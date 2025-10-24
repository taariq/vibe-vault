use cosmwasm_schema::{cw_serde, QueryResponses};

#[cw_serde]
pub struct InstantiateMsg {
    pub chain_id: u64,
    pub vault_manager_address: String,
    pub strategy_address: String,
    pub vault_address: String,
    pub harvest_interval: Option<u64>,
}

#[cw_serde]
pub enum ExecuteMsg {
    /// Execute daily harvest
    Harvest {},

    /// Check and rebalance LTV if needed
    Rebalance {},

    /// Collect management fees from vault
    CollectFees {},

    /// Emergency pause the job
    Pause {},

    /// Resume the job
    Resume {},

    /// Update configuration (owner only)
    UpdateConfig {
        vault_manager_address: Option<String>,
        strategy_address: Option<String>,
        vault_address: Option<String>,
        harvest_interval: Option<u64>,
        max_ltv: Option<u64>,
        min_ltv: Option<u64>,
    },

    /// Transfer ownership
    TransferOwnership { new_owner: String },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    /// Get current configuration
    #[returns(ConfigResponse)]
    Config {},

    /// Get job statistics
    #[returns(StatsResponse)]
    Stats {},

    /// Check if harvest is ready
    #[returns(HarvestStatusResponse)]
    HarvestStatus {},
}

#[cw_serde]
pub struct ConfigResponse {
    pub owner: String,
    pub chain_id: u64,
    pub vault_manager_address: String,
    pub strategy_address: String,
    pub vault_address: String,
    pub harvest_interval: u64,
    pub last_harvest: u64,
    pub max_ltv: u64,
    pub min_ltv: u64,
    pub paused: bool,
}

#[cw_serde]
pub struct StatsResponse {
    pub total_harvests: u64,
    pub total_profit: String,
    pub total_loss: String,
    pub total_rebalances: u64,
    pub last_profit: String,
    pub last_harvest_time: u64,
}

#[cw_serde]
pub struct HarvestStatusResponse {
    pub ready: bool,
    pub seconds_until_next: u64,
    pub last_harvest: u64,
}
