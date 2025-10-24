use cosmwasm_std::{
    entry_point, to_json_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
    Uint128,
};

use crate::error::ContractError;
use crate::msg::{
    ConfigResponse, ExecuteMsg, HarvestStatusResponse, InstantiateMsg, QueryMsg, StatsResponse,
};
use crate::state::{Config, Stats, CONFIG, STATS};

#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let config = Config {
        owner: info.sender.to_string(),
        chain_id: msg.chain_id,
        vault_manager_address: msg.vault_manager_address,
        strategy_address: msg.strategy_address,
        vault_address: msg.vault_address,
        harvest_interval: msg.harvest_interval.unwrap_or(86400), // Default 24 hours
        last_harvest: 0,
        max_ltv: 6000,
        min_ltv: 4000,
        paused: false,
    };

    CONFIG.save(deps.storage, &config)?;
    STATS.save(deps.storage, &Stats::default())?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("owner", info.sender)
        .add_attribute("chain_id", msg.chain_id.to_string()))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Harvest {} => execute_harvest(deps, env, info),
        ExecuteMsg::Rebalance {} => execute_rebalance(deps, env, info),
        ExecuteMsg::CollectFees {} => execute_collect_fees(deps, env, info),
        ExecuteMsg::Pause {} => execute_pause(deps, info),
        ExecuteMsg::Resume {} => execute_resume(deps, info),
        ExecuteMsg::UpdateConfig {
            vault_manager_address,
            strategy_address,
            vault_address,
            harvest_interval,
            max_ltv,
            min_ltv,
        } => execute_update_config(
            deps,
            info,
            vault_manager_address,
            strategy_address,
            vault_address,
            harvest_interval,
            max_ltv,
            min_ltv,
        ),
        ExecuteMsg::TransferOwnership { new_owner } => {
            execute_transfer_ownership(deps, info, new_owner)
        }
    }
}

pub fn execute_harvest(
    deps: DepsMut,
    env: Env,
    _info: MessageInfo,
) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;

    // Check if paused
    if config.paused {
        return Err(ContractError::Unauthorized {});
    }

    // Check if enough time has passed
    let time_since_harvest = env.block.time.seconds() - config.last_harvest;
    if time_since_harvest < config.harvest_interval {
        return Err(ContractError::HarvestTooSoon {
            wait_time: config.harvest_interval - time_since_harvest,
        });
    }

    // Construct Compass EVM call to harvest()
    // Function signature: harvest(address strategy) returns (uint256 profit, uint256 loss)
    let harvest_calldata = encode_harvest_call(&config.strategy_address);

    // Create Compass EVM message
    // This would use the actual paloma-compass-evm SDK
    // For now, showing the structure
    let compass_msg = create_compass_evm_message(
        config.chain_id,
        config.vault_manager_address.clone(),
        harvest_calldata,
        0, // No value sent
    );

    // Update config
    config.last_harvest = env.block.time.seconds();
    CONFIG.save(deps.storage, &config)?;

    // Update stats (would parse profit/loss from EVM response in production)
    let mut stats = STATS.load(deps.storage)?;
    stats.total_harvests += 1;
    stats.last_harvest_time = env.block.time.seconds();
    STATS.save(deps.storage, &stats)?;

    Ok(Response::new()
        .add_message(compass_msg)
        .add_attribute("method", "harvest")
        .add_attribute("strategy", config.strategy_address)
        .add_attribute("timestamp", env.block.time.seconds().to_string()))
}

pub fn execute_rebalance(
    deps: DepsMut,
    env: Env,
    _info: MessageInfo,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;

    if config.paused {
        return Err(ContractError::Unauthorized {});
    }

    // Construct Compass EVM call to rebalance()
    let rebalance_calldata = encode_rebalance_call();

    let compass_msg = create_compass_evm_message(
        config.chain_id,
        config.vault_manager_address.clone(),
        rebalance_calldata,
        0,
    );

    // Update stats
    let mut stats = STATS.load(deps.storage)?;
    stats.total_rebalances += 1;
    STATS.save(deps.storage, &stats)?;

    Ok(Response::new()
        .add_message(compass_msg)
        .add_attribute("method", "rebalance")
        .add_attribute("timestamp", env.block.time.seconds().to_string()))
}

pub fn execute_collect_fees(
    deps: DepsMut,
    env: Env,
    _info: MessageInfo,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;

    if config.paused {
        return Err(ContractError::Unauthorized {});
    }

    // Construct Compass EVM call to collectManagementFee()
    let collect_fees_calldata = encode_collect_fees_call();

    let compass_msg = create_compass_evm_message(
        config.chain_id,
        config.vault_address.clone(),
        collect_fees_calldata,
        0,
    );

    Ok(Response::new()
        .add_message(compass_msg)
        .add_attribute("method", "collect_fees")
        .add_attribute("timestamp", env.block.time.seconds().to_string()))
}

pub fn execute_pause(deps: DepsMut, info: MessageInfo) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;

    // Only owner can pause
    if info.sender.to_string() != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    config.paused = true;
    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("method", "pause")
        .add_attribute("paused", "true"))
}

pub fn execute_resume(deps: DepsMut, info: MessageInfo) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;

    // Only owner can resume
    if info.sender.to_string() != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    config.paused = false;
    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("method", "resume")
        .add_attribute("paused", "false"))
}

pub fn execute_update_config(
    deps: DepsMut,
    info: MessageInfo,
    vault_manager_address: Option<String>,
    strategy_address: Option<String>,
    vault_address: Option<String>,
    harvest_interval: Option<u64>,
    max_ltv: Option<u64>,
    min_ltv: Option<u64>,
) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;

    // Only owner can update config
    if info.sender.to_string() != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    if let Some(addr) = vault_manager_address {
        config.vault_manager_address = addr;
    }
    if let Some(addr) = strategy_address {
        config.strategy_address = addr;
    }
    if let Some(addr) = vault_address {
        config.vault_address = addr;
    }
    if let Some(interval) = harvest_interval {
        config.harvest_interval = interval;
    }
    if let Some(ltv) = max_ltv {
        config.max_ltv = ltv;
    }
    if let Some(ltv) = min_ltv {
        config.min_ltv = ltv;
    }

    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new().add_attribute("method", "update_config"))
}

pub fn execute_transfer_ownership(
    deps: DepsMut,
    info: MessageInfo,
    new_owner: String,
) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;

    // Only owner can transfer
    if info.sender.to_string() != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    config.owner = new_owner.clone();
    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new()
        .add_attribute("method", "transfer_ownership")
        .add_attribute("new_owner", new_owner))
}

#[entry_point]
pub fn query(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Config {} => to_json_binary(&query_config(deps)?),
        QueryMsg::Stats {} => to_json_binary(&query_stats(deps)?),
        QueryMsg::HarvestStatus {} => to_json_binary(&query_harvest_status(deps, env)?),
    }
}

fn query_config(deps: Deps) -> StdResult<ConfigResponse> {
    let config = CONFIG.load(deps.storage)?;
    Ok(ConfigResponse {
        owner: config.owner,
        chain_id: config.chain_id,
        vault_manager_address: config.vault_manager_address,
        strategy_address: config.strategy_address,
        vault_address: config.vault_address,
        harvest_interval: config.harvest_interval,
        last_harvest: config.last_harvest,
        max_ltv: config.max_ltv,
        min_ltv: config.min_ltv,
        paused: config.paused,
    })
}

fn query_stats(deps: Deps) -> StdResult<StatsResponse> {
    let stats = STATS.load(deps.storage)?;
    Ok(StatsResponse {
        total_harvests: stats.total_harvests,
        total_profit: stats.total_profit.to_string(),
        total_loss: stats.total_loss.to_string(),
        total_rebalances: stats.total_rebalances,
        last_profit: stats.last_profit.to_string(),
        last_harvest_time: stats.last_harvest_time,
    })
}

fn query_harvest_status(deps: Deps, env: Env) -> StdResult<HarvestStatusResponse> {
    let config = CONFIG.load(deps.storage)?;

    let time_since_harvest = env.block.time.seconds() - config.last_harvest;
    let ready = time_since_harvest >= config.harvest_interval;
    let seconds_until_next = if ready {
        0
    } else {
        config.harvest_interval - time_since_harvest
    };

    Ok(HarvestStatusResponse {
        ready,
        seconds_until_next,
        last_harvest: config.last_harvest,
    })
}

// Helper functions to encode EVM function calls

fn encode_harvest_call(strategy_address: &str) -> Vec<u8> {
    // Function signature: harvest(address)
    // Keccak256("harvest(address)")[0:4] = 0x4641257d
    let mut calldata = vec![0x46, 0x41, 0x25, 0x7d];

    // Encode strategy address (remove 0x prefix and pad to 32 bytes)
    let addr_bytes = hex::decode(strategy_address.trim_start_matches("0x")).unwrap_or_default();
    let mut padded = vec![0u8; 12]; // Pad 12 bytes
    padded.extend_from_slice(&addr_bytes);

    calldata.extend_from_slice(&padded);
    calldata
}

fn encode_rebalance_call() -> Vec<u8> {
    // Function signature: rebalance()
    // Keccak256("rebalance()")[0:4] = 0x7d7c2a1c
    vec![0x7d, 0x7c, 0x2a, 0x1c]
}

fn encode_collect_fees_call() -> Vec<u8> {
    // Function signature: collectManagementFee()
    // Keccak256("collectManagementFee()")[0:4] = 0x5c60da1b (example)
    vec![0x5c, 0x60, 0xda, 0x1b]
}

fn create_compass_evm_message(
    chain_id: u64,
    target_address: String,
    calldata: Vec<u8>,
    value: u128,
) -> cosmwasm_std::CosmosMsg {
    // This is a placeholder for the actual Paloma Compass EVM message
    // In production, would use the paloma-compass-evm SDK

    // Example structure (actual implementation depends on Paloma SDK):
    /*
    paloma_compass_evm::CompassEvmMsg::SubmitLogicCall {
        chain_id,
        logic_contract_address: target_address,
        payload: calldata,
        value: Uint128::new(value),
        deadline: env.block.time.plus_seconds(3600), // 1 hour
    }
    */

    // Placeholder: return a generic Cosmos message
    cosmwasm_std::CosmosMsg::Custom(serde_json::json!({
        "compass_evm": {
            "submit_logic_call": {
                "chain_id": chain_id,
                "target": target_address,
                "calldata": hex::encode(calldata),
                "value": value.to_string()
            }
        }
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use cosmwasm_std::testing::{mock_dependencies, mock_env, mock_info};

    #[test]
    fn proper_initialization() {
        let mut deps = mock_dependencies();
        let msg = InstantiateMsg {
            chain_id: 1,
            vault_manager_address: "0x1234567890123456789012345678901234567890".to_string(),
            strategy_address: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd".to_string(),
            vault_address: "0x9999999999999999999999999999999999999999".to_string(),
            harvest_interval: Some(86400),
        };
        let info = mock_info("creator", &[]);
        let res = instantiate(deps.as_mut(), mock_env(), info, msg).unwrap();
        assert_eq!(0, res.messages.len());
    }
}
