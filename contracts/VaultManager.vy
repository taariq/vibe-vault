# @version 0.3.10
"""
@title VaultManager
@notice Manages strategy allocation and yield harvesting for kGOLDt vault
@dev Coordinates capital deployment, rebalancing, and profit distribution
@author Vibe Vault
"""

from vyper.interfaces import ERC20

interface IStrategy:
    def want() -> address: view
    def vault() -> address: view
    def estimatedTotalAssets() -> uint256: view
    def estimatedAPR() -> uint256: view
    def deposit(assets: uint256) -> uint256: nonpayable
    def withdraw(shares: uint256, min_assets: uint256) -> uint256: nonpayable
    def harvest() -> (uint256, uint256): nonpayable
    def emergencyExit(): nonpayable

interface IVault:
    def asset() -> address: view
    def reportStrategyGain(profit: uint256): nonpayable
    def reportStrategyLoss(loss: uint256): nonpayable
    def updateDebt(new_debt: uint256): nonpayable
    def buffer() -> uint256: view

# Events
event StrategyAdded:
    strategy: indexed(address)
    debt_ratio: uint256

event StrategyRemoved:
    strategy: indexed(address)

event StrategyDebtRatioUpdated:
    strategy: indexed(address)
    old_ratio: uint256
    new_ratio: uint256

event StrategyDeposit:
    strategy: indexed(address)
    assets: uint256
    shares: uint256

event StrategyWithdraw:
    strategy: indexed(address)
    shares: uint256
    assets: uint256

event Harvest:
    strategy: indexed(address)
    profit: uint256
    loss: uint256

event Rebalance:
    timestamp: uint256

# Storage
vault: public(immutable(address))
xaut: public(immutable(address))

# Strategy management
struct StrategyParams:
    activated: bool
    debt_ratio: uint256  # In basis points (10000 = 100%)
    current_debt: uint256  # Assets deployed to this strategy
    total_gain: uint256  # Historical gains
    total_loss: uint256  # Historical losses
    last_report: uint256  # Timestamp of last harvest

strategies: public(HashMap[address, StrategyParams])
strategy_list: public(DynArray[address, 10])
total_debt_ratio: public(uint256)
total_debt: public(uint256)

# Constants
MAX_BPS: constant(uint256) = 10000
BUFFER_TARGET: constant(uint256) = 1500  # 15%

# Access control
owner: public(address)
pending_owner: public(address)
keeper: public(address)  # Paloma job
guardian: public(address)

@external
def __init__(_vault: address, _keeper: address):
    """
    @notice Initialize VaultManager
    @param _vault Address of kGOLDt vault
    @param _keeper Address of keeper (Paloma job)
    """
    vault = _vault
    xaut = IVault(_vault).asset()

    self.owner = msg.sender
    self.keeper = _keeper
    self.guardian = msg.sender

# Strategy Management

@external
def addStrategy(strategy: address, debt_ratio: uint256):
    """
    @notice Add a new strategy
    @param strategy Address of strategy contract
    @param debt_ratio Target debt ratio in basis points
    """
    assert msg.sender == self.owner, "Only owner"
    assert not self.strategies[strategy].activated, "Strategy already exists"
    assert debt_ratio <= MAX_BPS, "Invalid debt ratio"
    assert self.total_debt_ratio + debt_ratio <= MAX_BPS, "Total ratio exceeded"

    # Verify strategy
    assert IStrategy(strategy).want() == xaut, "Wrong asset"
    assert IStrategy(strategy).vault() == vault, "Wrong vault"

    # Add strategy
    self.strategies[strategy] = StrategyParams({
        activated: True,
        debt_ratio: debt_ratio,
        current_debt: 0,
        total_gain: 0,
        total_loss: 0,
        last_report: block.timestamp
    })

    self.strategy_list.append(strategy)
    self.total_debt_ratio += debt_ratio

    log StrategyAdded(strategy, debt_ratio)

@external
def removeStrategy(strategy: address):
    """
    @notice Remove a strategy (must withdraw all funds first)
    @param strategy Address of strategy to remove
    """
    assert msg.sender == self.owner, "Only owner"
    assert self.strategies[strategy].activated, "Strategy not active"
    assert self.strategies[strategy].current_debt == 0, "Strategy has debt"

    # Remove from list
    for i in range(10):
        if i >= len(self.strategy_list):
            break
        if self.strategy_list[i] == strategy:
            # Move last element to this position
            last_idx: uint256 = len(self.strategy_list) - 1
            if i != last_idx:
                self.strategy_list[i] = self.strategy_list[last_idx]
            self.strategy_list.pop()
            break

    # Update total debt ratio
    self.total_debt_ratio -= self.strategies[strategy].debt_ratio

    # Deactivate
    self.strategies[strategy].activated = False

    log StrategyRemoved(strategy)

@external
def updateDebtRatio(strategy: address, new_ratio: uint256):
    """
    @notice Update strategy debt ratio
    @param strategy Strategy address
    @param new_ratio New debt ratio in basis points
    """
    assert msg.sender == self.owner, "Only owner"
    assert self.strategies[strategy].activated, "Strategy not active"
    assert new_ratio <= MAX_BPS, "Invalid ratio"

    old_ratio: uint256 = self.strategies[strategy].debt_ratio

    # Check total ratio
    new_total: uint256 = self.total_debt_ratio - old_ratio + new_ratio
    assert new_total <= MAX_BPS, "Total ratio exceeded"

    self.strategies[strategy].debt_ratio = new_ratio
    self.total_debt_ratio = new_total

    log StrategyDebtRatioUpdated(strategy, old_ratio, new_ratio)

# Capital Allocation

@external
def depositToStrategy(strategy: address, assets: uint256) -> uint256:
    """
    @notice Deposit assets to a strategy
    @param strategy Strategy address
    @param assets Amount of XAUt to deposit
    @return shares Amount of strategy shares received
    """
    assert msg.sender == self.keeper, "Only keeper"
    assert self.strategies[strategy].activated, "Strategy not active"

    # Transfer XAUt from vault to strategy
    assert ERC20(xaut).transferFrom(vault, strategy, assets), "Transfer failed"

    # Deposit to strategy
    shares: uint256 = IStrategy(strategy).deposit(assets)

    # Update debt
    self.strategies[strategy].current_debt += assets
    self.total_debt += assets

    # Update vault debt tracking
    IVault(vault).updateDebt(self.total_debt)

    log StrategyDeposit(strategy, assets, shares)
    return shares

@external
def withdrawFromStrategy(strategy: address, shares: uint256, min_assets: uint256) -> uint256:
    """
    @notice Withdraw assets from a strategy
    @param strategy Strategy address
    @param shares Amount of strategy shares to burn
    @param min_assets Minimum assets to receive
    @return assets Amount of XAUt received
    """
    assert msg.sender == self.keeper or msg.sender == self.owner, "Only keeper or owner"
    assert self.strategies[strategy].activated, "Strategy not active"

    # Withdraw from strategy (assets come directly to vault)
    assets: uint256 = IStrategy(strategy).withdraw(shares, min_assets)

    # Update debt
    if assets <= self.strategies[strategy].current_debt:
        self.strategies[strategy].current_debt -= assets
        self.total_debt -= assets
    else:
        # Profit case
        self.strategies[strategy].current_debt = 0
        self.total_debt -= self.strategies[strategy].current_debt

    # Update vault debt tracking
    IVault(vault).updateDebt(self.total_debt)

    log StrategyWithdraw(strategy, shares, assets)
    return assets

# Yield Management

@external
def harvest(strategy: address) -> (uint256, uint256):
    """
    @notice Harvest yield from a strategy
    @param strategy Strategy address
    @return profit XAUt profit realized
    @return loss XAUt loss incurred
    """
    assert msg.sender == self.keeper, "Only keeper"
    assert self.strategies[strategy].activated, "Strategy not active"

    # Call strategy harvest
    profit: uint256 = 0
    loss: uint256 = 0
    (profit, loss) = IStrategy(strategy).harvest()

    # Update strategy stats
    self.strategies[strategy].total_gain += profit
    self.strategies[strategy].total_loss += loss
    self.strategies[strategy].last_report = block.timestamp

    # Update debt
    if profit > 0:
        self.strategies[strategy].current_debt += profit
        self.total_debt += profit
    if loss > 0:
        if loss <= self.strategies[strategy].current_debt:
            self.strategies[strategy].current_debt -= loss
            self.total_debt -= loss
        else:
            self.total_debt -= self.strategies[strategy].current_debt
            self.strategies[strategy].current_debt = 0

    # Report to vault
    if profit > 0:
        IVault(vault).reportStrategyGain(profit)
    if loss > 0:
        IVault(vault).reportStrategyLoss(loss)

    # Update vault debt tracking
    IVault(vault).updateDebt(self.total_debt)

    log Harvest(strategy, profit, loss)
    return (profit, loss)

@external
def harvestAll() -> (uint256, uint256):
    """
    @notice Harvest all strategies
    @return total_profit Total profit across all strategies
    @return total_loss Total loss across all strategies
    """
    assert msg.sender == self.keeper, "Only keeper"

    total_profit: uint256 = 0
    total_loss: uint256 = 0

    for strategy in self.strategy_list:
        if self.strategies[strategy].activated:
            profit: uint256 = 0
            loss: uint256 = 0
            (profit, loss) = self.harvest(strategy)
            total_profit += profit
            total_loss += loss

    return (total_profit, total_loss)

# Rebalancing

@external
def rebalance():
    """
    @notice Rebalance capital allocation across strategies
    @dev Moves funds to maintain target debt ratios and buffer
    """
    assert msg.sender == self.keeper or msg.sender == self.owner, "Only keeper or owner"

    # Get vault total assets
    vault_buffer: uint256 = IVault(vault).buffer()
    total_assets: uint256 = vault_buffer + self.total_debt

    # Target buffer: 15% of total assets
    target_buffer: uint256 = (total_assets * BUFFER_TARGET) / MAX_BPS

    if vault_buffer < target_buffer:
        # Need to withdraw from strategies to refill buffer
        deficit: uint256 = target_buffer - vault_buffer
        # Withdraw proportionally from strategies
        # (Simplified: withdraw from highest debt strategy)
        self._withdraw_to_buffer(deficit)

    elif vault_buffer > target_buffer * 12 / 10:  # 20% above target
        # Deploy excess to strategies
        excess: uint256 = vault_buffer - target_buffer
        self._deploy_from_buffer(excess)

    log Rebalance(block.timestamp)

@internal
def _withdraw_to_buffer(amount: uint256):
    """
    @notice Withdraw funds from strategies to buffer
    @param amount Amount to withdraw
    """
    remaining: uint256 = amount

    # Withdraw from strategies with highest debt first
    for strategy in self.strategy_list:
        if remaining == 0:
            break

        if self.strategies[strategy].activated and self.strategies[strategy].current_debt > 0:
            withdraw_amount: uint256 = min(remaining, self.strategies[strategy].current_debt)

            # Calculate shares (simplified: assume 1:1)
            shares: uint256 = withdraw_amount

            # Withdraw
            assets: uint256 = IStrategy(strategy).withdraw(shares, withdraw_amount)

            # Update debt
            self.strategies[strategy].current_debt -= assets
            self.total_debt -= assets

            remaining -= assets

    # Update vault debt
    IVault(vault).updateDebt(self.total_debt)

@internal
def _deploy_from_buffer(amount: uint256):
    """
    @notice Deploy funds from buffer to strategies
    @param amount Amount to deploy
    """
    remaining: uint256 = amount
    total_assets: uint256 = IVault(vault).buffer() + self.total_debt

    # Deploy to strategies based on debt ratio targets
    for strategy in self.strategy_list:
        if remaining == 0:
            break

        if self.strategies[strategy].activated:
            target_debt: uint256 = (total_assets * self.strategies[strategy].debt_ratio) / MAX_BPS
            current_debt: uint256 = self.strategies[strategy].current_debt

            if current_debt < target_debt:
                deploy_amount: uint256 = min(remaining, target_debt - current_debt)

                # Transfer and deposit
                assert ERC20(xaut).transferFrom(vault, strategy, deploy_amount), "Transfer failed"
                shares: uint256 = IStrategy(strategy).deposit(deploy_amount)

                # Update debt
                self.strategies[strategy].current_debt += deploy_amount
                self.total_debt += deploy_amount

                remaining -= deploy_amount

    # Update vault debt
    IVault(vault).updateDebt(self.total_debt)

# View Functions

@external
@view
def creditAvailable(strategy: address) -> uint256:
    """
    @notice Calculate available credit for a strategy
    @param strategy Strategy address
    @return Available credit in XAUt
    """
    if not self.strategies[strategy].activated:
        return 0

    vault_buffer: uint256 = IVault(vault).buffer()
    total_assets: uint256 = vault_buffer + self.total_debt

    target_debt: uint256 = (total_assets * self.strategies[strategy].debt_ratio) / MAX_BPS
    current_debt: uint256 = self.strategies[strategy].current_debt

    if target_debt > current_debt:
        credit: uint256 = target_debt - current_debt
        return min(credit, vault_buffer)

    return 0

@external
@view
def debtOutstanding(strategy: address) -> uint256:
    """
    @notice Calculate debt to withdraw from strategy
    @param strategy Strategy address
    @return Debt to withdraw in XAUt
    """
    if not self.strategies[strategy].activated:
        return 0

    vault_buffer: uint256 = IVault(vault).buffer()
    total_assets: uint256 = vault_buffer + self.total_debt

    target_debt: uint256 = (total_assets * self.strategies[strategy].debt_ratio) / MAX_BPS
    current_debt: uint256 = self.strategies[strategy].current_debt

    if current_debt > target_debt:
        return current_debt - target_debt

    return 0

@external
@view
def strategyDebt(strategy: address) -> uint256:
    """@notice Get current debt of a strategy"""
    return self.strategies[strategy].current_debt

# Emergency Functions

@external
def emergencyExitStrategy(strategy: address):
    """
    @notice Emergency exit a strategy
    @param strategy Strategy address
    """
    assert msg.sender == self.guardian or msg.sender == self.owner, "Only guardian or owner"
    assert self.strategies[strategy].activated, "Strategy not active"

    # Call emergency exit
    IStrategy(strategy).emergencyExit()

    # Update debt to zero
    self.total_debt -= self.strategies[strategy].current_debt
    self.strategies[strategy].current_debt = 0

    # Update vault
    IVault(vault).updateDebt(self.total_debt)

# Access Control

@external
def setKeeper(new_keeper: address):
    """@notice Set keeper address"""
    assert msg.sender == self.owner, "Only owner"
    self.keeper = new_keeper

@external
def setGuardian(new_guardian: address):
    """@notice Set guardian address"""
    assert msg.sender == self.owner, "Only owner"
    self.guardian = new_guardian

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
