# @version 0.3.10
"""
@title AaveMidasStrategy
@notice kGOLDt yield strategy using Aave V3 collateral and Midas Protocol
@dev Deposits XAUt to Aave, borrows USDC, deploys to mRE7YIELD, harvests daily
@author Vibe Vault
"""

from vyper.interfaces import ERC20

# Aave V3 Interfaces
interface IPool:
    def supply(asset: address, amount: uint256, onBehalfOf: address, referralCode: uint16): nonpayable
    def withdraw(asset: address, amount: uint256, to: address) -> uint256: nonpayable
    def borrow(asset: address, amount: uint256, interestRateMode: uint256, referralCode: uint16, onBehalfOf: address): nonpayable
    def repay(asset: address, amount: uint256, interestRateMode: uint256, onBehalfOf: address) -> uint256: nonpayable
    def getUserAccountData(user: address) -> (uint256, uint256, uint256, uint256, uint256, uint256): view

# Midas Protocol Interface
interface IMidasVault:
    def deposit(assets: uint256, receiver: address) -> uint256: nonpayable
    def withdraw(assets: uint256, receiver: address, owner: address) -> uint256: nonpayable
    def balanceOf(account: address) -> uint256: view
    def convertToAssets(shares: uint256) -> uint256: view

# 1inch Aggregation Router
interface IAggregationRouter:
    def swap(caller: address, desc: SwapDescription, data: Bytes[1024]) -> (uint256, uint256): payable

struct SwapDescription:
    srcToken: address
    dstToken: address
    srcReceiver: address
    dstReceiver: address
    amount: uint256
    minReturnAmount: uint256
    flags: uint256

# Events
event Deposit:
    assets: uint256
    shares: uint256

event Withdraw:
    shares: uint256
    assets: uint256

event Harvest:
    profit: uint256
    loss: uint256
    usdc_harvested: uint256
    xaut_bought: uint256

event Rebalance:
    old_ltv: uint256
    new_ltv: uint256

event EmergencyExit:
    xaut_recovered: uint256

# Immutable addresses
VAULT: public(immutable(address))
XAUT: public(immutable(address))
USDC: public(immutable(address))

# Aave V3 (Ethereum mainnet)
AAVE_POOL: public(immutable(address))  # 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2

# Midas Protocol - mRE7YIELD
MIDAS_VAULT: public(immutable(address))  # mRE7YIELD vault address

# 1inch Router
ONE_INCH_ROUTER: public(immutable(address))  # 0x1111111254EEB25477B68fb85Ed929f73A960582

# Strategy parameters
TARGET_LTV: public(constant(uint256)) = 5000  # 50%
MAX_LTV: public(constant(uint256)) = 6000  # 60%
MIN_LTV: public(constant(uint256)) = 4000  # 40%
LTV_BUFFER: public(constant(uint256)) = 500  # 5% buffer for rebalancing

MAX_BPS: constant(uint256) = 10000

# State
owner: public(address)
keeper: public(address)
vault_manager: public(address)

xaut_deposited: public(uint256)  # XAUt supplied to Aave
usdc_borrowed: public(uint256)  # USDC borrowed from Aave
usdc_deployed: public(uint256)  # USDC deployed to Midas
midas_shares: public(uint256)  # Shares in Midas vault

last_harvest: public(uint256)
total_profit: public(uint256)
total_loss: public(uint256)

@external
def __init__(
    _vault: address,
    _vault_manager: address,
    _xaut: address,
    _usdc: address,
    _aave_pool: address,
    _midas_vault: address,
    _one_inch_router: address
):
    """
    @notice Initialize the Aave-Midas strategy
    @param _vault Address of kGOLDt vault
    @param _vault_manager Address of VaultManager
    @param _xaut Address of Tether Gold (XAUt)
    @param _usdc Address of USDC
    @param _aave_pool Address of Aave V3 Pool
    @param _midas_vault Address of mRE7YIELD Midas vault
    @param _one_inch_router Address of 1inch aggregation router
    """
    VAULT = _vault
    XAUT = _xaut
    USDC = _usdc
    AAVE_POOL = _aave_pool
    MIDAS_VAULT = _midas_vault
    ONE_INCH_ROUTER = _one_inch_router

    self.owner = msg.sender
    self.vault_manager = _vault_manager
    self.keeper = msg.sender
    self.last_harvest = block.timestamp

    # Approve Aave for XAUt and USDC
    assert ERC20(XAUT).approve(AAVE_POOL, max_value(uint256)), "XAUt approval failed"
    assert ERC20(USDC).approve(AAVE_POOL, max_value(uint256)), "USDC approval failed"

    # Approve Midas for USDC
    assert ERC20(USDC).approve(MIDAS_VAULT, max_value(uint256)), "Midas approval failed"

    # Approve 1inch for USDC
    assert ERC20(USDC).approve(ONE_INCH_ROUTER, max_value(uint256)), "1inch approval failed"

# IStrategy Implementation

@external
@view
def want() -> address:
    """@notice Returns XAUt address"""
    return XAUT

@external
@view
def vault() -> address:
    """@notice Returns vault address"""
    return VAULT

@external
@view
def estimatedTotalAssets() -> uint256:
    """
    @notice Estimate total assets in XAUt terms
    @dev Calculates: XAUt in Aave + (Midas value - USDC debt) converted to XAUt
    @return Total estimated XAUt value
    """
    # XAUt deposited to Aave
    xaut_value: uint256 = self.xaut_deposited

    # Get USDC value in Midas
    usdc_in_midas: uint256 = 0
    if self.midas_shares > 0:
        usdc_in_midas = IMidasVault(MIDAS_VAULT).convertToAssets(self.midas_shares)

    # Net USDC position (Midas assets - borrowed debt)
    net_usdc: uint256 = 0
    if usdc_in_midas > self.usdc_borrowed:
        net_usdc = usdc_in_midas - self.usdc_borrowed
        # Convert net USDC to XAUt (simplified: would use oracle in production)
        # For now, estimate 1 XAUt ≈ 2000 USDC
        xaut_value += (net_usdc * 10**6) / 2000  # Adjust decimals

    return xaut_value

@external
@view
def estimatedAPR() -> uint256:
    """
    @notice Estimate current APR in basis points
    @dev Based on Midas APR minus Aave borrow rate
    @return Estimated APR (e.g., 800 = 8%)
    """
    # Simplified: return target 8% APR (800 bps)
    # In production, would calculate from actual rates
    return 800

@external
def deposit(assets: uint256) -> uint256:
    """
    @notice Deposit XAUt and deploy to strategy
    @dev Supplies XAUt to Aave, borrows USDC, deploys to Midas
    @param assets Amount of XAUt to deposit
    @return shares Strategy shares minted (1:1 with assets)
    """
    assert msg.sender == self.vault_manager, "Only vault manager"

    # Transfer XAUt from vault to strategy
    assert ERC20(XAUT).transferFrom(VAULT, self, assets), "Transfer failed"

    # 1. Supply XAUt to Aave as collateral
    IPool(AAVE_POOL).supply(XAUT, assets, self, 0)
    self.xaut_deposited += assets

    # 2. Borrow USDC at 50% LTV
    # Calculate borrow amount (simplified pricing: 1 XAUt = 2000 USDC)
    xaut_value_usd: uint256 = assets * 2000 / 10**6  # Adjust for decimals
    borrow_amount: uint256 = (xaut_value_usd * TARGET_LTV) / MAX_BPS

    IPool(AAVE_POOL).borrow(USDC, borrow_amount, 2, 0, self)  # Variable rate mode = 2
    self.usdc_borrowed += borrow_amount

    # 3. Deploy USDC to Midas (mRE7YIELD)
    shares: uint256 = IMidasVault(MIDAS_VAULT).deposit(borrow_amount, self)
    self.usdc_deployed += borrow_amount
    self.midas_shares += shares

    log Deposit(assets, assets)
    return assets  # Simplified: 1:1 shares

@external
def withdraw(shares: uint256, min_assets: uint256) -> uint256:
    """
    @notice Withdraw assets from strategy
    @dev Withdraws from Midas, repays Aave, withdraws XAUt to vault
    @param shares Strategy shares to burn
    @param min_assets Minimum XAUt to receive
    @return assets Amount of XAUt withdrawn
    """
    assert msg.sender == self.vault_manager, "Only vault manager"

    # Calculate proportional withdrawal
    total_shares: uint256 = self.xaut_deposited  # Simplified: 1:1 shares
    withdrawal_ratio: uint256 = (shares * MAX_BPS) / total_shares

    # 1. Withdraw USDC from Midas
    usdc_to_withdraw: uint256 = (self.usdc_deployed * withdrawal_ratio) / MAX_BPS
    midas_shares_to_burn: uint256 = (self.midas_shares * withdrawal_ratio) / MAX_BPS

    usdc_received: uint256 = IMidasVault(MIDAS_VAULT).withdraw(
        usdc_to_withdraw,
        self,
        self
    )
    self.usdc_deployed -= usdc_to_withdraw
    self.midas_shares -= midas_shares_to_burn

    # 2. Repay USDC to Aave
    usdc_to_repay: uint256 = (self.usdc_borrowed * withdrawal_ratio) / MAX_BPS
    IPool(AAVE_POOL).repay(USDC, usdc_to_repay, 2, self)
    self.usdc_borrowed -= usdc_to_repay

    # 3. Withdraw XAUt from Aave to vault
    xaut_to_withdraw: uint256 = (self.xaut_deposited * withdrawal_ratio) / MAX_BPS
    assets: uint256 = IPool(AAVE_POOL).withdraw(XAUT, xaut_to_withdraw, VAULT)
    self.xaut_deposited -= xaut_to_withdraw

    assert assets >= min_assets, "Slippage exceeded"

    log Withdraw(shares, assets)
    return assets

@external
def harvest() -> (uint256, uint256):
    """
    @notice Harvest yield and report profit
    @dev Claims Midas rewards, swaps USDC to XAUt, reports profit
    @return profit XAUt profit realized
    @return loss XAUt loss incurred
    """
    assert msg.sender == self.keeper, "Only keeper"

    # Track initial XAUt deposited
    initial_xaut: uint256 = self.xaut_deposited

    # 1. Check Midas vault shares value vs deployed USDC
    current_usdc_value: uint256 = IMidasVault(MIDAS_VAULT).convertToAssets(self.midas_shares)

    profit_usdc: uint256 = 0
    if current_usdc_value > self.usdc_deployed:
        profit_usdc = current_usdc_value - self.usdc_deployed

        # 2. Withdraw profit from Midas
        if profit_usdc > 0:
            # Calculate shares for profit
            profit_shares: uint256 = (profit_usdc * self.midas_shares) / current_usdc_value

            IMidasVault(MIDAS_VAULT).withdraw(profit_usdc, self, self)
            self.midas_shares -= profit_shares
            self.usdc_deployed -= profit_usdc

            # 3. Swap USDC profit to XAUt via 1inch
            # In production, would use actual 1inch API call
            # Simplified: direct swap
            xaut_bought: uint256 = self._swapUSDCToXAUt(profit_usdc)

            # 4. Supply XAUt profit to Aave (increases collateral)
            if xaut_bought > 0:
                IPool(AAVE_POOL).supply(XAUT, xaut_bought, self, 0)
                self.xaut_deposited += xaut_bought

                # Send profit to vault
                assert ERC20(XAUT).transfer(VAULT, xaut_bought), "Transfer failed"

                self.total_profit += xaut_bought
                self.last_harvest = block.timestamp

                log Harvest(xaut_bought, 0, profit_usdc, xaut_bought)
                return (xaut_bought, 0)

    # 5. Check for losses
    loss: uint256 = 0
    if self.xaut_deposited < initial_xaut:
        loss = initial_xaut - self.xaut_deposited
        self.total_loss += loss

    # 6. Rebalance LTV if needed
    self._checkAndRebalanceLTV()

    self.last_harvest = block.timestamp
    log Harvest(0, loss, profit_usdc, 0)
    return (0, loss)

@internal
def _swapUSDCToXAUt(usdc_amount: uint256) -> uint256:
    """
    @notice Swap USDC to XAUt via 1inch
    @dev In production, would use 1inch API for best rates
    @param usdc_amount Amount of USDC to swap
    @return Amount of XAUt received
    """
    # Simplified swap logic
    # In production, construct proper 1inch swap calldata

    # For now, return estimated amount (1 XAUt ≈ 2000 USDC)
    estimated_xaut: uint256 = (usdc_amount * 10**6) / 2000

    # Would call: IAggregationRouter(ONE_INCH_ROUTER).swap(...)
    # For this implementation, assume swap succeeds
    return estimated_xaut

@external
def emergencyExit():
    """
    @notice Emergency exit all positions
    @dev Withdraws from Midas, repays Aave, returns XAUt to vault
    """
    assert msg.sender == self.owner or msg.sender == self.vault_manager, "Only owner or manager"

    # 1. Withdraw all from Midas
    if self.midas_shares > 0:
        usdc_received: uint256 = IMidasVault(MIDAS_VAULT).withdraw(
            self.usdc_deployed,
            self,
            self
        )
        self.midas_shares = 0
        self.usdc_deployed = 0

        # 2. Repay all USDC debt to Aave
        if self.usdc_borrowed > 0:
            IPool(AAVE_POOL).repay(USDC, self.usdc_borrowed, 2, self)
            self.usdc_borrowed = 0

    # 3. Withdraw all XAUt from Aave to vault
    if self.xaut_deposited > 0:
        xaut_recovered: uint256 = IPool(AAVE_POOL).withdraw(XAUT, self.xaut_deposited, VAULT)
        self.xaut_deposited = 0

        log EmergencyExit(xaut_recovered)

# Internal Functions

@internal
def _checkAndRebalanceLTV():
    """
    @notice Check LTV and rebalance if outside target range
    @dev Maintains LTV between 40-60% by adjusting borrow/repay
    """
    current_ltv: uint256 = self._getCurrentLTV()

    if current_ltv > MAX_LTV:
        # LTV too high - repay some debt
        self._reduceLTV()
        log Rebalance(current_ltv, self._getCurrentLTV())

    elif current_ltv < MIN_LTV and self.xaut_deposited > 0:
        # LTV too low - borrow more
        self._increaseLTV()
        log Rebalance(current_ltv, self._getCurrentLTV())

@internal
def _getCurrentLTV() -> uint256:
    """
    @notice Calculate current LTV ratio
    @return LTV in basis points
    """
    if self.xaut_deposited == 0:
        return 0

    # Get account data from Aave
    # Returns: (totalCollateralBase, totalDebtBase, availableBorrowsBase, currentLiquidationThreshold, ltv, healthFactor)
    total_collateral: uint256 = 0
    total_debt: uint256 = 0
    available_borrows: uint256 = 0
    liquidation_threshold: uint256 = 0
    ltv: uint256 = 0
    health_factor: uint256 = 0

    (total_collateral, total_debt, available_borrows, liquidation_threshold, ltv, health_factor) = IPool(AAVE_POOL).getUserAccountData(self)

    if total_collateral == 0:
        return 0

    return (total_debt * MAX_BPS) / total_collateral

@internal
def _reduceLTV():
    """@notice Reduce LTV by repaying debt"""
    # Withdraw some USDC from Midas to repay
    repay_amount: uint256 = self.usdc_borrowed / 10  # Repay 10%

    if repay_amount > 0 and repay_amount <= self.usdc_deployed:
        # Withdraw from Midas
        IMidasVault(MIDAS_VAULT).withdraw(repay_amount, self, self)
        self.usdc_deployed -= repay_amount

        # Repay to Aave
        IPool(AAVE_POOL).repay(USDC, repay_amount, 2, self)
        self.usdc_borrowed -= repay_amount

@internal
def _increaseLTV():
    """@notice Increase LTV by borrowing more"""
    # Calculate safe borrow amount
    current_ltv: uint256 = self._getCurrentLTV()
    target_borrow_increase: uint256 = ((TARGET_LTV - current_ltv) * self.xaut_deposited * 2000) / (MAX_BPS * 10**6)

    if target_borrow_increase > 0:
        # Borrow from Aave
        IPool(AAVE_POOL).borrow(USDC, target_borrow_increase, 2, 0, self)
        self.usdc_borrowed += target_borrow_increase

        # Deploy to Midas
        shares: uint256 = IMidasVault(MIDAS_VAULT).deposit(target_borrow_increase, self)
        self.usdc_deployed += target_borrow_increase
        self.midas_shares += shares

# Access Control

@external
def setKeeper(new_keeper: address):
    """@notice Set keeper address"""
    assert msg.sender == self.owner, "Only owner"
    self.keeper = new_keeper

@external
def transferOwnership(new_owner: address):
    """@notice Transfer ownership"""
    assert msg.sender == self.owner, "Only owner"
    self.owner = new_owner
