# kGOLDt \- TLDR Build Spec 

## What It Does

Deposit XAUt → Get kGOLDt → Earn 8% APY in gold → Withdraw anytime

## How It Works

1. User deposits XAUt, receives kGOLDt (1:1 initially)  
2. Protocol deposits XAUt to Aave as collateral  
3. Borrow USDC at 50% LTV from Aave  
4. Deploy USDC to mRE7YIELD (21% APY)  
5. Daily: Harvest yield, swap USDC for XAUt, increase kGOLDt value  
6. User withdraws: Burns kGOLDt, receives XAUt (now worth more)

##  Key Strategy Parameters

* **Asset:** XAUt only  
* **Collateral:** Aave V3 isolated market  
* **LTV:** 50%  
* **Yield:** mRE7YIELD (21% APY target)  
* **Buffer:** 15% kept liquid (not deployed)  
* **Harvest:** Daily (automated via Gelato)  
* **Fees:** 0.5% annual mgmt \+ 10% performance

## Withdrawal Logic

* **Small (\<15% of buffer):** Instant, 0% fee  
* **Large (\>15%):** Queued, processed at next harvest (\~24h), 0% fee  
* **Buffer refilled:** At each harvest

## Frontend Proposal

### Navigation

* 4 tabs: Deposit | Withdraw | Dashboard | Strategies

### Deposit Page

* Two-panel input form (matching your UI style)  
  * Top panel: Enter XAUt amount (with token dropdown and max button)  
  * Bottom panel: Preview kGOLDt shares received  
* Expandable details section showing:  
  * Current exchange rate (1 kGOLDt \= X XAUt)  
  * Your share of pool (%)  
  * TVL, Current APY, Buffer available  
  * Time until next harvest  
* Approve \+ Deposit buttons with gas estimate

### Withdraw Page

* Two-panel input form  
  * Top panel: Enter kGOLDt amount to burn  
  * Bottom panel: Preview XAUt to receive  
* Withdrawal type indicator:  
  * "Instant" if within buffer (≤15% TVL)  
  * "Queued (\~24h)" if above buffer  
* Expandable details showing:  
  * Exchange rate  
  * Your profit (XAUt gained \+ %)  
  * Performance fee (10% of profit)  
  * Net amount after fees  
* Approve \+ Withdraw button with gas estimate

### Dashboard (Bottom Section)

* Your Position card:  
  * kGOLDt balance  
  * Current value in XAUt and USD  
  * Total XAUt earned (+ % gain)  
* Performance card:  
  * Current APY (7-day average)  
  * Daily earnings estimate  
  * Time since deposit  
  * Lifetime earnings  
* Expandable vault metrics (TVL, exchange rate, buffer status, strategy health)

### **Strategies Page** (Info/Monitoring)

* Strategy status overview (health, last harvest time)  
* Expandable Aave V3 details (LTV, liquidation threshold, borrow rates)  
* Expandable Midas details (deposited USDC, APY, daily yield)  
* Expandable automation info (harvest frequency, next harvest, rebalancing)

## Suggested Contracts Implementation

### kGOLDt.sol (ERC-4626 Vault)

```
contract kGOLDt is ERC4626 {
    // ERC-4626 Standard Methods
    function deposit(uint256 assets, address receiver) 
        returns (uint256 shares)
    
    function mint(uint256 shares, address receiver) 
        returns (uint256 assets)
    
    function withdraw(uint256 assets, address receiver, address owner) 
        returns (uint256 shares)
    
    function redeem(uint256 shares, address receiver, address owner) 
        returns (uint256 assets)
    
    // View Functions
    function totalAssets() returns (uint256)
    function convertToShares(uint256 assets) returns (uint256)
    function convertToAssets(uint256 shares) returns (uint256)
    function previewDeposit(uint256 assets) returns (uint256)
    function previewWithdraw(uint256 assets) returns (uint256)
    
    // Custom
    function pricePerShare() returns (uint256)  // XAUt per share
    function buffer() returns (uint256)          // Liquid XAUt available
}
```

### VaultManager.sol

```
contract VaultManager {
    // Strategy Management
    function addStrategy(address strategy, uint256 debtRatio) onlyOwner
    function removeStrategy(address strategy) onlyOwner
    function updateDebtRatio(address strategy, uint256 debtRatio) onlyOwner
    
    // Capital Allocation
    function depositToStrategy(
        address strategy, 
        uint256 assets
    ) onlyKeeper returns (uint256 shares)
    
    function withdrawFromStrategy(
        address strategy, 
        uint256 shares,
        uint256 minAssets
    ) onlyKeeper returns (uint256 assets)
    
    // Yield Management
    function harvest(address strategy) onlyKeeper 
        returns (uint256 profit, uint256 loss)
    
    function harvestAll() onlyKeeper 
        returns (uint256 totalProfit, uint256 totalLoss)
    
    // Rebalancing
    function rebalance() onlyKeeper
    
    // View Functions
    function totalDebt() returns (uint256)
    function strategyDebt(address strategy) returns (uint256)
    function creditAvailable(address strategy) returns (uint256)
}
```

### 3\. IStrategy.sol (Interface)

```
interface IStrategy {
    // Core Strategy Functions
    function deposit(uint256 assets) external returns (uint256 shares);
    
    function withdraw(uint256 shares, uint256 minAssets) 
        external returns (uint256 assets);
    
    function harvest() external returns (uint256 profit, uint256 loss);
    
    // View Functions
    function estimatedTotalAssets() external view returns (uint256);
    function estimatedAPR() external view returns (uint256);
    
    // Metadata
    function name() external view returns (string memory);
    function want() external view returns (address);  // XAUt address
    function vault() external view returns (address);
}
```

### 4\. Strategy Implementations (AaveMidasStrategy.sol)

```
contract AaveMidasStrategy is IStrategy {
    // Configuration
    uint256 public constant TARGET_LTV = 5000;  // 50%
    uint256 public constant MAX_LTV = 6000;     // 60%
    
    // IStrategy Implementation
    function deposit(uint256 xautAmount) external override onlyVault 
        returns (uint256 shares)
    
    function withdraw(uint256 shares, uint256 minXaut) external override onlyVault 
        returns (uint256 xautAmount)
    
    function harvest() external override onlyKeeper 
        returns (uint256 profit, uint256 loss) {
        // 1. Claim rewards from mRE7YIELD
        // 2. Swap USDC rewards to XAUt (via 1inch/Uniswap)
        // 3. Report profit to vault
        // 4. Rebalance if needed
    }
    
    // Strategy-Specific
    function depositToAave(uint256 xautAmount) internal
    function borrowFromAave(uint256 usdcAmount) internal
    function repayToAave(uint256 usdcAmount) internal
    function withdrawFromAave(uint256 xautAmount) internal
    
    function depositToMidas(uint256 usdcAmount) internal
    function withdrawFromMidas(uint256 usdcAmount) internal
    
    function rebalanceLTV() internal
    function getCurrentLTV() public view returns (uint256)
    
    // Emergency
    function emergencyExit() external onlyGovernance
}
```

---

**That's it. 3 contracts (1 Interface), 1 frontend, automated harvesting, 8% APY on gold.**  
