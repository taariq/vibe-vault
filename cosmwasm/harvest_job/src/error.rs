use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Harvest too soon. Must wait {wait_time} seconds")]
    HarvestTooSoon { wait_time: u64 },

    #[error("LTV within acceptable range")]
    LtvOk {},

    #[error("Compass EVM execution failed: {reason}")]
    CompassExecutionFailed { reason: String },
}
