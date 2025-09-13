use thiserror::Error;

#[derive(Error, Debug)]
pub enum OptimusError {
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("Performance error: {0}")]
    Performance(String),
    
    #[error("Communication error: {0}")]
    Communication(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}