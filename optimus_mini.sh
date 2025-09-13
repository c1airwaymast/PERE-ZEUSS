#!/bin/bash
echo "🔥 OPTIMUS ULTIMATE MINI 🔥"
sudo apt update -y && sudo apt install -y curl build-essential pkg-config libssl-dev
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
mkdir -p ~/optimus && cd ~/optimus
cat > Cargo.toml << 'EOF'
[package]
name = "optimus"
version = "1.0.0"
edition = "2021"
[dependencies]
clap = { version = "4.4", features = ["derive"] }
EOF
mkdir src
cat > src/main.rs << 'EOF'
use clap::{Parser, Subcommand};
#[derive(Parser)]
struct Cli { #[command(subcommand)] command: Option<Commands> }
#[derive(Subcommand)]
enum Commands { Status, Dominate, Ultimate }
fn main() {
    let cli = Cli::parse();
    match cli.command {
        Some(Commands::Status) => println!("🔥 OPTIMUS: ✅ OPERATIONAL ON VPS\n⚡ Power: OVER 9000!\n📧 SMTP: ⚰️ EXTINCT"),
        Some(Commands::Dominate) => println!("👑 DOMINATION MODE ACTIVE!\n🌍 VPS CONQUERED!\n📧 SMTP EXTINCT!"),
        Some(Commands::Ultimate) => println!("🌟 ULTIMATE FORM!\n🔥 TRANSFORMATION COMPLETE!\n👑 DIGITAL UNIVERSE DOMINATED!"),
        None => println!("Commands: optimus status | optimus dominate | optimus ultimate")
    }
}
EOF
cargo build --release
sudo cp target/release/optimus /usr/local/bin/ 2>/dev/null || echo "Installed locally"
echo "✅ OPTIMUS READY! Test: optimus status"
