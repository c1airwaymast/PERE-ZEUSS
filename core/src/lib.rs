//! Core functionality for OPTIMUS ULTIMATE PME Security Suite
//! 
//! This crate provides the foundational types and traits used throughout
//! the ZEUS system.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Core result type used throughout the ZEUS system
pub type ZeusResult<T> = anyhow::Result<T>;

/// Configuration for Zeus components
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZeusConfig {
    pub component_name: String,
    pub version: String,
    pub settings: HashMap<String, String>,
}

impl Default for ZeusConfig {
    fn default() -> Self {
        Self {
            component_name: "zeus-component".to_string(),
            version: "1.0.0".to_string(),
            settings: HashMap::new(),
        }
    }
}

/// Core metrics that all Zeus components should provide
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZeusMetrics {
    pub component_name: String,
    pub uptime_seconds: u64,
    pub operations_count: u64,
    pub error_count: u64,
    pub last_operation_timestamp: Option<chrono::DateTime<chrono::Utc>>,
    pub custom_metrics: HashMap<String, f64>,
}

impl Default for ZeusMetrics {
    fn default() -> Self {
        Self {
            component_name: "unknown".to_string(),
            uptime_seconds: 0,
            operations_count: 0,
            error_count: 0,
            last_operation_timestamp: None,
            custom_metrics: HashMap::new(),
        }
    }
}

/// Trait that all Zeus components should implement
#[async_trait::async_trait]
pub trait ZeusComponent: Send + Sync {
    /// Initialize the component with given configuration
    async fn initialize(&mut self, config: ZeusConfig) -> ZeusResult<()>;
    
    /// Get current metrics from the component
    async fn get_metrics(&self) -> ZeusResult<ZeusMetrics>;
    
    /// Start the component
    async fn start(&mut self) -> ZeusResult<()>;
    
    /// Stop the component gracefully
    async fn stop(&mut self) -> ZeusResult<()>;
    
    /// Health check for the component
    async fn health_check(&self) -> ZeusResult<bool>;
}