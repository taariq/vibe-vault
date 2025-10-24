# @version 0.3.10
"""
@title kGOLDt - Gold-Backed Yield Vault
@notice ERC-4626 vault that generates 8% APY on tokenized gold (XAUt)
@dev Deposits XAUt, deploys to Aave/Midas strategy, harvests yield daily
@author Vibe Vault
"""

from vyper.interfaces import ERC20
from vyper.interfaces import ERC4626

implements: ERC4626

# Events
event Deposit:
    sender: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256

event Withdraw:
    sender: indexed(address)
    receiver: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256

event WithdrawalQueued:
    owner: indexed(address)
    shares: uint256
    estimated_assets: uint256

event StrategyAdded:
    strategy: indexed(address)

event StrategyRemoved:
    strategy: indexed(address)

event Harvest:
    profit: uint256
    loss: uint256
    performance_fee: uint256

# Immutables
XAUT: public(immutable(address))  # Tether Gold token
VAULT_MANAGER: public(immutable(address))

# Storage
name: public(String[64])
symbol: public(String[32])
decimals: public(uint8)

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

# Vault state
total_assets_deposited: public(uint256)
total_debt: public(uint256)  # Assets deployed to strategies
buffer_reserve: public(uint256)  # 15% kept liquid for withdrawals

# Fees (in basis points)
MANAGEMENT_FEE: public(constant(uint256)) = 50  # 0.5%
PERFORMANCE_FEE: public(constant(uint256)) = 1000  # 10%
BUFFER_TARGET: public(constant(uint256)) = 1500  # 15%
MAX_BPS: constant(uint256) = 10000

# Withdrawal queue
struct WithdrawalRequest:
    shares: uint256
    timestamp: uint256

pending_withdrawals: public(HashMap[address, WithdrawalRequest])

# Access control
owner: public(address)
pending_owner: public(address)
keeper: public(address)  # Paloma job address
treasury: public(address)

# Last fee collection
last_fee_collection: public(uint256)

@external
def __init__(
    _xaut: address,
    _vault_manager: address,
    _treasury: address,
    _name: String[64],
    _symbol: String[32]
):
    """
    @notice Initialize the kGOLDt vault
    @param _xaut Address of Tether Gold (XAUt) token
    @param _vault_manager Address of VaultManager contract
    @param _treasury Address to receive fees
    @param _name Vault token name
    @param _symbol Vault token symbol
    """
    XAUT = _xaut
    VAULT_MANAGER = _vault_manager

    self.name = _name
    self.symbol = _symbol
    self.decimals = ERC20(_xaut).decimals()

    self.owner = msg.sender
    self.keeper = msg.sender
    self.treasury = _treasury
    self.last_fee_collection = block.timestamp

# ERC20 Functions

@external
def transfer(_to: address, _value: uint256) -> bool:
    """@notice Transfer vault shares"""
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    return True

@external
def approve(_spender: address, _value: uint256) -> bool:
    """@notice Approve spender for vault shares"""
    self.allowance[msg.sender][_spender] = _value
    return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    """@notice Transfer vault shares from another account"""
    self.allowance[_from][msg.sender] -= _value
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    return True

# ERC-4626 View Functions

@external
@view
def asset() -> address:
    """@notice Returns the address of the underlying asset (XAUt)"""
    return XAUT

@external
@view
def totalAssets() -> uint256:
    """
    @notice Total assets under management
    @return Total XAUt (buffer + deployed to strategies)
    """
    return self.buffer_reserve + self.total_debt

@external
@view
def convertToShares(assets: uint256) -> uint256:
    """
    @notice Convert assets to shares
    @param assets Amount of XAUt
    @return Amount of kGOLDt shares
    """
    _totalSupply: uint256 = self.totalSupply
    if _totalSupply == 0:
        return assets

    _totalAssets: uint256 = self.buffer_reserve + self.total_debt
    if _totalAssets == 0:
        return assets

    return (assets * _totalSupply) / _totalAssets

@external
@view
def convertToAssets(shares: uint256) -> uint256:
    """
    @notice Convert shares to assets
    @param shares Amount of kGOLDt shares
    @return Amount of XAUt
    """
    _totalSupply: uint256 = self.totalSupply
    if _totalSupply == 0:
        return shares

    _totalAssets: uint256 = self.buffer_reserve + self.total_debt
    return (shares * _totalAssets) / _totalSupply

@external
@view
def maxDeposit(receiver: address) -> uint256:
    """@notice Maximum assets that can be deposited"""
    return max_value(uint256)

@external
@view
def maxMint(receiver: address) -> uint256:
    """@notice Maximum shares that can be minted"""
    return max_value(uint256)

@external
@view
def maxWithdraw(owner: address) -> uint256:
    """
    @notice Maximum assets that can be instantly withdrawn
    @dev Limited by buffer reserve
    """
    shares: uint256 = self.balanceOf[owner]
    max_assets: uint256 = self.convertToAssets(shares)

    # Can only instantly withdraw what's in buffer
    if max_assets > self.buffer_reserve:
        return self.buffer_reserve
    return max_assets

@external
@view
def maxRedeem(owner: address) -> uint256:
    """
    @notice Maximum shares that can be instantly redeemed
    @dev Limited by buffer reserve
    """
    return self.convertToShares(self.buffer_reserve)

@external
@view
def previewDeposit(assets: uint256) -> uint256:
    """@notice Preview shares received for deposit"""
    return self.convertToShares(assets)

@external
@view
def previewMint(shares: uint256) -> uint256:
    """@notice Preview assets needed to mint shares"""
    _totalSupply: uint256 = self.totalSupply
    if _totalSupply == 0:
        return shares

    _totalAssets: uint256 = self.buffer_reserve + self.total_debt
    return (shares * _totalAssets) / _totalSupply + 1  # Round up

@external
@view
def previewWithdraw(assets: uint256) -> uint256:
    """@notice Preview shares needed to withdraw assets"""
    _totalSupply: uint256 = self.totalSupply
    if _totalSupply == 0:
        return assets

    _totalAssets: uint256 = self.buffer_reserve + self.total_debt
    return (assets * _totalSupply) / _totalAssets + 1  # Round up

@external
@view
def previewRedeem(shares: uint256) -> uint256:
    """@notice Preview assets received for redeeming shares"""
    return self.convertToAssets(shares)

# ERC-4626 State-Changing Functions

@external
def deposit(assets: uint256, receiver: address) -> uint256:
    """
    @notice Deposit XAUt and receive kGOLDt shares
    @param assets Amount of XAUt to deposit
    @param receiver Address to receive shares
    @return shares Amount of kGOLDt shares minted
    """
    shares: uint256 = self.convertToShares(assets)

    # Transfer XAUt from user
    assert ERC20(XAUT).transferFrom(msg.sender, self, assets), "Transfer failed"

    # Mint shares
    self.balanceOf[receiver] += shares
    self.totalSupply += shares

    # Update state
    self.buffer_reserve += assets
    self.total_assets_deposited += assets

    log Deposit(msg.sender, receiver, assets, shares)
    return shares

@external
def mint(shares: uint256, receiver: address) -> uint256:
    """
    @notice Mint exact amount of kGOLDt shares
    @param shares Amount of shares to mint
    @param receiver Address to receive shares
    @return assets Amount of XAUt deposited
    """
    assets: uint256 = self.previewMint(shares)

    # Transfer XAUt from user
    assert ERC20(XAUT).transferFrom(msg.sender, self, assets), "Transfer failed"

    # Mint shares
    self.balanceOf[receiver] += shares
    self.totalSupply += shares

    # Update state
    self.buffer_reserve += assets
    self.total_assets_deposited += assets

    log Deposit(msg.sender, receiver, assets, shares)
    return assets

@external
def withdraw(assets: uint256, receiver: address, owner: address) -> uint256:
    """
    @notice Withdraw XAUt by burning kGOLDt shares
    @param assets Amount of XAUt to withdraw
    @param receiver Address to receive XAUt
    @param owner Address that owns the shares
    @return shares Amount of shares burned
    """
    shares: uint256 = self.previewWithdraw(assets)

    # Check allowance if not owner
    if msg.sender != owner:
        self.allowance[owner][msg.sender] -= shares

    # Check if instant withdrawal possible (within buffer)
    if assets <= self.buffer_reserve:
        # Instant withdrawal
        self._burn_and_withdraw(owner, receiver, shares, assets)
    else:
        # Queue withdrawal for next harvest
        self.pending_withdrawals[owner] = WithdrawalRequest({
            shares: shares,
            timestamp: block.timestamp
        })
        log WithdrawalQueued(owner, shares, assets)

    return shares

@external
def redeem(shares: uint256, receiver: address, owner: address) -> uint256:
    """
    @notice Redeem kGOLDt shares for XAUt
    @param shares Amount of shares to redeem
    @param receiver Address to receive XAUt
    @param owner Address that owns the shares
    @return assets Amount of XAUt withdrawn
    """
    assets: uint256 = self.convertToAssets(shares)

    # Check allowance if not owner
    if msg.sender != owner:
        self.allowance[owner][msg.sender] -= shares

    # Check if instant withdrawal possible
    if assets <= self.buffer_reserve:
        # Instant withdrawal
        self._burn_and_withdraw(owner, receiver, shares, assets)
    else:
        # Queue withdrawal for next harvest
        self.pending_withdrawals[owner] = WithdrawalRequest({
            shares: shares,
            timestamp: block.timestamp
        })
        log WithdrawalQueued(owner, shares, assets)

    return assets

@internal
def _burn_and_withdraw(owner: address, receiver: address, shares: uint256, assets: uint256):
    """
    @notice Internal function to burn shares and transfer assets
    @param owner Owner of the shares
    @param receiver Receiver of assets
    @param shares Amount of shares to burn
    @param assets Amount of assets to transfer
    """
    # Calculate performance fee (10% of profit)
    initial_assets: uint256 = self.convertToAssets(shares)
    if assets > initial_assets:
        profit: uint256 = assets - initial_assets
        fee: uint256 = (profit * PERFORMANCE_FEE) / MAX_BPS
        assets -= fee
        # Transfer fee to treasury
        assert ERC20(XAUT).transfer(self.treasury, fee), "Fee transfer failed"

    # Burn shares
    self.balanceOf[owner] -= shares
    self.totalSupply -= shares

    # Update buffer
    self.buffer_reserve -= assets

    # Transfer XAUt to receiver
    assert ERC20(XAUT).transfer(receiver, assets), "Transfer failed"

    log Withdraw(msg.sender, receiver, owner, assets, shares)

# Custom Vault Functions

@external
@view
def pricePerShare() -> uint256:
    """
    @notice Current exchange rate (XAUt per share)
    @return Price in XAUt decimals
    """
    if self.totalSupply == 0:
        return 10 ** convert(self.decimals, uint256)
    return (self.buffer_reserve + self.total_debt) * (10 ** convert(self.decimals, uint256)) / self.totalSupply

@external
@view
def buffer() -> uint256:
    """@notice Liquid XAUt available for instant withdrawals"""
    return self.buffer_reserve

@external
def processQueuedWithdrawal(user: address):
    """
    @notice Process a queued withdrawal after harvest
    @dev Can be called by anyone after next harvest
    @param user Address with queued withdrawal
    """
    request: WithdrawalRequest = self.pending_withdrawals[user]
    assert request.shares > 0, "No pending withdrawal"

    # Calculate assets
    assets: uint256 = self.convertToAssets(request.shares)

    # Check buffer has enough
    assert assets <= self.buffer_reserve, "Insufficient buffer"

    # Clear request
    self.pending_withdrawals[user] = WithdrawalRequest({shares: 0, timestamp: 0})

    # Execute withdrawal
    self._burn_and_withdraw(user, user, request.shares, assets)

@external
def reportStrategyGain(profit: uint256):
    """
    @notice Report profit from strategy harvest
    @dev Only callable by VaultManager
    @param profit Amount of XAUt profit
    """
    assert msg.sender == VAULT_MANAGER, "Only manager"

    # Calculate performance fee
    fee: uint256 = (profit * PERFORMANCE_FEE) / MAX_BPS

    # Add profit to buffer (minus fee)
    self.buffer_reserve += (profit - fee)

    # Transfer fee to treasury
    if fee > 0:
        assert ERC20(XAUT).transfer(self.treasury, fee), "Fee transfer failed"

    log Harvest(profit, 0, fee)

@external
def reportStrategyLoss(loss: uint256):
    """
    @notice Report loss from strategy
    @dev Only callable by VaultManager
    @param loss Amount of XAUt loss
    """
    assert msg.sender == VAULT_MANAGER, "Only manager"

    # Reduce total debt
    self.total_debt -= loss

    log Harvest(0, loss, 0)

@external
def collectManagementFee():
    """
    @notice Collect management fee (0.5% annually)
    @dev Called during harvest
    """
    assert msg.sender == self.keeper, "Only keeper"

    time_elapsed: uint256 = block.timestamp - self.last_fee_collection
    if time_elapsed == 0:
        return

    # Calculate fee: 0.5% annual = 0.5% * (time_elapsed / 1 year)
    total: uint256 = self.buffer_reserve + self.total_debt
    annual_fee: uint256 = (total * MANAGEMENT_FEE) / MAX_BPS
    fee: uint256 = (annual_fee * time_elapsed) / 31536000  # seconds in a year

    if fee > 0 and fee <= self.buffer_reserve:
        assert ERC20(XAUT).transfer(self.treasury, fee), "Fee transfer failed"
        self.buffer_reserve -= fee

    self.last_fee_collection = block.timestamp

# Access Control

@external
def setKeeper(new_keeper: address):
    """@notice Set keeper address (Paloma job)"""
    assert msg.sender == self.owner, "Only owner"
    self.keeper = new_keeper

@external
def setTreasury(new_treasury: address):
    """@notice Set treasury address"""
    assert msg.sender == self.owner, "Only owner"
    self.treasury = new_treasury

@external
def transferOwnership(new_owner: address):
    """@notice Start ownership transfer"""
    assert msg.sender == self.owner, "Only owner"
    self.pending_owner = new_owner

@external
def acceptOwnership():
    """@notice Accept ownership transfer"""
    assert msg.sender == self.pending_owner, "Only pending owner"
    self.owner = self.pending_owner
    self.pending_owner = empty(address)

# Emergency

@external
def pause():
    """@notice Pause deposits (withdrawals always enabled)"""
    assert msg.sender == self.owner, "Only owner"
    # Implementation would add paused state
    pass

@external
def updateDebt(new_debt: uint256):
    """
    @notice Update total debt from VaultManager
    @dev Only callable by VaultManager
    @param new_debt New total debt amount
    """
    assert msg.sender == VAULT_MANAGER, "Only manager"
    self.total_debt = new_debt
