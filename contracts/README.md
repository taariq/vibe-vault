# kGOLDt Contracts - Vyper Implementation

## Overview

kGOLDt is a gold-backed yield vault that generates 8% APY on tokenized gold (XAUt) through a sophisticated strategy involving Aave V3 collateralization, USDC borrowing, and Midas Protocol yield farming.

**User Flow:** Deposit XAUt → Receive kGOLDt shares → Earn 8% APY → Withdraw anytime

## Architecture

### Contract Structure

```
contracts/
├── interfaces/
│   └── IStrategy.vyi          # Strategy interface
├── kGOLDt.vy                  # ERC-4626 vault contract
├── VaultManager.vy            # Strategy management & capital allocation
└── AaveMidasStrategy.vy       # Aave V3 + Midas strategy implementation
```

### Component Responsibilities

#### 1. **kGOLDt.vy** (ERC-4626 Vault)

The main vault contract implementing the ERC-4626 tokenized vault standard.

**Key Functions:**
- `deposit(assets, receiver)` - Deposit XAUt and receive kGOLDt shares
- `withdraw(assets, receiver, owner)` - Withdraw XAUt by burning shares
- `redeem(shares, receiver, owner)` - Redeem shares for XAUt
- `totalAssets()` - Total XAUt under management
- `pricePerShare()` - Current exchange rate (increases with yield)

**Features:**
- **Instant Withdrawals:** Up to 15% buffer for immediate redemptions
- **Withdrawal Queue:** Large withdrawals processed at next harvest (~24h)
- **Fees:** 0.5% annual management + 10% performance fee
- **Buffer Management:** 15% kept liquid for withdrawals

#### 2. **VaultManager.vy** (Capital Allocation)

Manages strategy deployment, rebalancing, and yield harvesting.

**Key Functions:**
- `addStrategy(strategy, debt_ratio)` - Add a new yield strategy
- `depositToStrategy(strategy, assets)` - Deploy capital to strategy
- `withdrawFromStrategy(strategy, shares, min_assets)` - Withdraw from strategy
- `harvest(strategy)` - Harvest yield and report profit/loss
- `harvestAll()` - Harvest all strategies
- `rebalance()` - Rebalance capital allocation

**Features:**
- **Debt Ratio Management:** Allocate capital across multiple strategies
- **Automated Rebalancing:** Maintain target buffer and strategy allocations
- **Profit/Loss Tracking:** Track historical performance per strategy
- **Emergency Exit:** Guardian can emergency exit strategies

#### 3. **AaveMidasStrategy.vy** (Yield Strategy)

Implements the Aave V3 + Midas Protocol yield strategy.

**Strategy Flow:**
1. Deposits XAUt to Aave V3 as collateral
2. Borrows USDC at 50% LTV
3. Deploys USDC to mRE7YIELD (Midas Protocol) targeting 21% APY
4. Harvests USDC yield daily
5. Swaps USDC to XAUt via 1inch
6. Reports profit to vault

**Key Functions:**
- `deposit(assets)` - Deploy XAUt to strategy
- `withdraw(shares, min_assets)` - Withdraw XAUt from strategy
- `harvest()` - Harvest yield and report profit
- `emergencyExit()` - Exit all positions

**Parameters:**
- `TARGET_LTV`: 50% (5000 bps)
- `MAX_LTV`: 60% (6000 bps) - triggers rebalancing
- `MIN_LTV`: 40% (4000 bps) - triggers rebalancing

**Risk Management:**
- Automated LTV monitoring and rebalancing
- Emergency exit functionality
- Slippage protection on withdrawals

## Paloma Automation

The vault is automated using Paloma Chain's Compass EVM system, which enables decentralized keeper operations.

### CosmWasm Harvest Job

```
cosmwasm/harvest_job/
├── src/
│   ├── contract.rs    # Main CosmWasm contract logic
│   ├── msg.rs         # Message definitions
│   ├── state.rs       # State management
│   └── error.rs       # Error handling
└── Cargo.toml
```

**Automated Tasks:**
- **Daily Harvest:** Calls `VaultManager.harvest()` every 24 hours
- **LTV Monitoring:** Checks strategy LTV and triggers rebalancing if needed
- **Fee Collection:** Collects management fees from vault
- **Health Monitoring:** Tracks vault metrics and performance

**Key Features:**
- Compass EVM integration for cross-chain execution
- Configurable harvest intervals
- Emergency pause/resume
- Statistics tracking

## Deployment Guide

### Prerequisites

1. **Vyper Compiler:** `vyper >= 0.3.10`
2. **Foundry/Brownie:** For testing and deployment
3. **Paloma CLI:** For CosmWasm deployment

### Ethereum Contracts

#### 1. Deploy Contracts

```bash
# Compile contracts
vyper contracts/kGOLDt.vy
vyper contracts/VaultManager.vy
vyper contracts/AaveMidasStrategy.vy

# Deploy (using Foundry/Brownie/Ape)
# 1. Deploy kGOLDt vault
# 2. Deploy VaultManager
# 3. Deploy AaveMidasStrategy
# 4. Connect contracts
```

#### 2. Contract Addresses (Ethereum Mainnet)

```python
# Tokens
XAUT = "0x70e8dE73cE538DA2bEEd35d14187F6959a8ecA96"
USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"

# Aave V3
AAVE_POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2"

# Midas Protocol
MIDAS_VAULT = "[mRE7YIELD vault address]"

# 1inch
ONE_INCH_ROUTER = "0x1111111254EEB25477B68fb85Ed929f73A960582"
```

#### 3. Initialize Vault

```python
# 1. Initialize kGOLDt
vault = kGOLDt.deploy(
    xaut=XAUT,
    vault_manager=vault_manager.address,
    treasury=treasury_address,
    name="kGOLDt Gold Yield Vault",
    symbol="kGOLDt"
)

# 2. Initialize VaultManager
manager = VaultManager.deploy(
    vault=vault.address,
    keeper=paloma_job_address
)

# 3. Deploy Strategy
strategy = AaveMidasStrategy.deploy(
    vault=vault.address,
    vault_manager=manager.address,
    xaut=XAUT,
    usdc=USDC,
    aave_pool=AAVE_POOL,
    midas_vault=MIDAS_VAULT,
    one_inch_router=ONE_INCH_ROUTER
)

# 4. Add Strategy to Manager
manager.addStrategy(strategy.address, 10000)  # 100% debt ratio
```

### Paloma Harvest Job

#### 1. Build CosmWasm Contract

```bash
cd cosmwasm/harvest_job
cargo build --release --target wasm32-unknown-unknown

# Optimize
docker run --rm -v "$(pwd)":/code \
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/code/target \
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \
  cosmwasm/rust-optimizer:0.12.13
```

#### 2. Deploy to Paloma

```bash
# Store contract
palomad tx wasm store artifacts/kgoldt_harvest_job.wasm \
  --from wallet \
  --gas-prices 0.025ugrain \
  --gas auto \
  --gas-adjustment 1.3

# Instantiate
palomad tx wasm instantiate CODE_ID \
  '{
    "chain_id": 1,
    "vault_manager_address": "0x...",
    "strategy_address": "0x...",
    "vault_address": "0x...",
    "harvest_interval": 86400
  }' \
  --from wallet \
  --label "kGOLDt Harvest Job" \
  --gas-prices 0.025ugrain \
  --gas auto
```

#### 3. Execute Harvest

```bash
# Manual harvest trigger
palomad tx wasm execute CONTRACT_ADDRESS \
  '{"harvest": {}}' \
  --from wallet

# Query harvest status
palomad query wasm contract-state smart CONTRACT_ADDRESS \
  '{"harvest_status": {}}'

# Query stats
palomad query wasm contract-state smart CONTRACT_ADDRESS \
  '{"stats": {}}'
```

## User Guide

### For Depositors

#### Deposit XAUt

```python
# 1. Approve XAUt
xaut.approve(vault.address, amount)

# 2. Deposit
vault.deposit(amount, user_address)

# Or mint exact shares
vault.mint(shares, user_address)
```

#### Withdraw XAUt

```python
# Check max instant withdrawal (within buffer)
max_instant = vault.maxWithdraw(user_address)

# Instant withdrawal (if within buffer)
vault.withdraw(amount, receiver, owner)

# Large withdrawal (queued for next harvest)
vault.redeem(shares, receiver, owner)

# Process queued withdrawal after harvest
vault.processQueuedWithdrawal(user_address)
```

#### Monitor Position

```python
# Get price per share
price = vault.pricePerShare()

# Calculate position value
shares = vault.balanceOf(user_address)
xaut_value = vault.convertToAssets(shares)

# Check total assets
total = vault.totalAssets()
buffer = vault.buffer()
```

### For Governance

#### Strategy Management

```python
# Add new strategy
manager.addStrategy(new_strategy, debt_ratio=5000)  # 50%

# Update debt ratio
manager.updateDebtRatio(strategy, new_ratio=3000)  # 30%

# Remove strategy (must withdraw all first)
manager.withdrawFromStrategy(strategy, all_shares, min_assets)
manager.removeStrategy(strategy)
```

#### Rebalancing

```python
# Manual rebalance
manager.rebalance()

# Check strategy allocations
credit = manager.creditAvailable(strategy)
debt_outstanding = manager.debtOutstanding(strategy)
current_debt = manager.strategyDebt(strategy)
```

#### Emergency Actions

```python
# Emergency exit a strategy
manager.emergencyExitStrategy(strategy)

# Pause vault deposits
vault.pause()
```

## Testing

### Vyper Tests (using Ape/Brownie)

```python
# Test deposit/withdraw
def test_deposit_withdraw(vault, xaut, user):
    # Deposit
    xaut.approve(vault.address, 100e6, sender=user)
    vault.deposit(100e6, user, sender=user)
    assert vault.balanceOf(user) == 100e6

    # Withdraw
    vault.withdraw(50e6, user, user, sender=user)
    assert vault.balanceOf(user) == 50e6

# Test strategy flow
def test_strategy_harvest(manager, strategy):
    # Harvest
    profit, loss = manager.harvest(strategy, sender=keeper)
    assert profit > 0
```

### CosmWasm Tests

```bash
cargo test
```

## Monitoring & Maintenance

### Key Metrics

- **TVL:** `vault.totalAssets()`
- **APY:** Track `pricePerShare()` over time
- **Buffer:** `vault.buffer()` (should be ~15%)
- **Strategy Debt:** `manager.totalDebt()`
- **LTV:** `strategy._getCurrentLTV()` (should be 40-60%)

### Alert Thresholds

- LTV > 58% → Rebalance soon
- LTV > 60% → Emergency rebalance
- Buffer < 10% → Withdraw from strategies
- Buffer > 20% → Deploy to strategies

## Security Considerations

### Access Control

- **Owner:** Can add/remove strategies, update parameters
- **Keeper:** Can harvest, rebalance (Paloma job)
- **Guardian:** Can emergency exit strategies

### Risks

1. **Smart Contract Risk:** Bugs in Aave, Midas, or vault contracts
2. **Liquidation Risk:** LTV exceeds safe threshold on Aave
3. **Oracle Risk:** XAUt/USDC price manipulation
4. **Yield Risk:** Midas APY drops below expectations
5. **Slippage Risk:** USDC→XAUt swaps during harvest

### Mitigation

- Comprehensive testing and audits
- Automated LTV monitoring and rebalancing
- Emergency exit functionality
- Slippage protection on swaps
- Multiple DEX options for swaps

## License

Apache 2.0

## Support

- GitHub: https://github.com/serenorg/vibe-vault
- Docs: https://docs.vibevault.io
- Discord: [Coming soon]
