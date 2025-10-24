use cosmwasm_schema::cw_serde;
use cw_storage_plus::Item;

#[cw_serde]
pub struct Config {
    /// Owner of the job (can update config)
    pub owner: String,

    /// Ethereum chain ID (1 for mainnet)
    pub chain_id: u64,

    /// VaultManager contract address on Ethereum
    pub vault_manager_address: String,

    /// AaveMidasStrategy contract address on Ethereum
    pub strategy_address: String,

    /// kGOLDt vault contract address on Ethereum
    pub vault_address: String,

    /// Harvest interval in seconds (default: 86400 = 24 hours)
    pub harvest_interval: u64,

    /// Last harvest timestamp
    pub last_harvest: u64,

    /// LTV thresholds for rebalancing
    pub max_ltv: u64,  // 6000 = 60%
    pub min_ltv: u64,  // 4000 = 40%

    /// Whether job is paused
    pub paused: bool,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            owner: String::new(),
            chain_id: 1,
            vault_manager_address: String::new(),
            strategy_address: String::new(),
            vault_address: String::new(),
            harvest_interval: 86400, // 24 hours
            last_harvest: 0,
            max_ltv: 6000,
            min_ltv: 4000,
            paused: false,
        }
    }
}

#[cw_serde]
pub struct Stats {
    /// Total number of harvests executed
    pub total_harvests: u64,

    /// Total profit harvested (in smallest unit)
    pub total_profit: u128,

    /// Total loss incurred
    pub total_loss: u128,

    /// Number of rebalances triggered
    pub total_rebalances: u64,

    /// Last harvest profit
    pub last_profit: u128,

    /// Last harvest timestamp
    pub last_harvest_time: u64,
}

impl Default for Stats {
    fn default() -> Self {
        Self {
            total_harvests: 0,
            total_profit: 0,
            total_loss: 0,
            total_rebalances: 0,
            last_profit: 0,
            last_harvest_time: 0,
        }
    }
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const STATS: Item<Stats> = Item::new("stats");
