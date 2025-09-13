use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CoreConfig {
    pub name: String,
    pub version: String,
    pub debug_mode: bool,
}

impl Default for CoreConfig {
    fn default() -> Self {
        Self {
            name: "OPTIMUS ULTIMATE".to_string(),
            version: "1.0.0".to_string(),
            debug_mode: false,
        }
    }
}