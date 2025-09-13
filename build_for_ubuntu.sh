#!/bin/bash
# 🔥 ZEUS CROSS-COMPILATION SCRIPT FOR UBUNTU VPS
# Compilation croisée Windows -> Linux pour déploiement VPS

echo "🔥🔥🔥 ZEUS CROSS-COMPILATION POUR VPS UBUNTU 🔥🔥🔥"
echo "=================================================="
echo "⚡ Compilation depuis Windows vers Linux Ubuntu..."

# Vérifier si Rust est installé
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust n'est pas installé!"
    echo "📦 Installation de Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
fi

# Ajouter la target Linux depuis Windows
echo "🎯 Configuration de la target Linux..."
rustup target add x86_64-unknown-linux-gnu

# Installer le linker pour cross-compilation
echo "🔗 Installation du linker Linux..."
sudo apt update
sudo apt install -y gcc-multilib

# Configurer Cargo pour cross-compilation
echo "⚙️ Configuration Cargo..."
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml << 'EOF'
[target.x86_64-unknown-linux-gnu]
linker = "x86_64-linux-gnu-gcc"

[build]
target = "x86_64-unknown-linux-gnu"
EOF

echo "🚀 Démarrage compilation cross-platform..."
cargo build --release --target x86_64-unknown-linux-gnu

echo "✅ Compilation terminée!"
echo "📁 Binaire Linux généré dans: target/x86_64-unknown-linux-gnu/release/"

# Créer archive pour VPS
echo "📦 Création archive pour VPS..."
tar -czf optimus-ultimate-linux.tar.gz -C target/x86_64-unknown-linux-gnu/release/ .

echo "🌐 Archive prête pour upload VPS: optimus-ultimate-linux.tar.gz"
echo "⚡ ZEUS A TRIOMPHÉ DE LA CROSS-COMPILATION!"
