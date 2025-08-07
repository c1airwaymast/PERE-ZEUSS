#!/bin/bash
# 🔥 ZEUS DIAGNOSTIC SCRIPT - TROUVE LE PROBLÈME ! 🔥

echo "🔥🔥🔥 ZEUS DIAGNOSTIC UBUNTU 🔥🔥🔥"
echo "==================================="
echo "⚡ Diagnostic du problème en cours..."
echo ""

# Test 1: Système de base
echo "📊 TEST 1: SYSTÈME DE BASE"
echo "=========================="
echo "🖥️ Système: $(uname -a)"
echo "👤 Utilisateur: $(whoami)"
echo "📁 Répertoire: $(pwd)"
echo "💾 Espace disque:"
df -h / | tail -1
echo ""

# Test 2: Réseau
echo "📊 TEST 2: CONNECTIVITÉ RÉSEAU" 
echo "=============================="
echo "🌐 IP locale:"
ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1
echo "🔗 Test Google:"
ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "✅ Internet OK" || echo "❌ Pas d'internet"
echo ""

# Test 3: Packages essentiels
echo "📊 TEST 3: PACKAGES ESSENTIELS"
echo "=============================="
which curl > /dev/null 2>&1 && echo "✅ curl: OK" || echo "❌ curl: MANQUANT"
which gcc > /dev/null 2>&1 && echo "✅ gcc: OK" || echo "❌ gcc: MANQUANT" 
which git > /dev/null 2>&1 && echo "✅ git: OK" || echo "❌ git: MANQUANT"
which make > /dev/null 2>&1 && echo "✅ make: OK" || echo "❌ make: MANQUANT"
echo ""

# Test 4: Rust
echo "📊 TEST 4: RUST INSTALLATION"
echo "============================"
if which rustc > /dev/null 2>&1; then
    echo "✅ Rust installé: $(rustc --version)"
    echo "✅ Cargo installé: $(cargo --version)"
else
    echo "❌ Rust non installé"
    echo "🔧 Installation automatique..."
    
    # Installation Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if which rustc > /dev/null 2>&1; then
        echo "✅ Rust installé avec succès: $(rustc --version)"
    else
        echo "❌ Échec installation Rust"
    fi
fi
echo ""

# Test 5: Permissions
echo "📊 TEST 5: PERMISSIONS"
echo "======================"
touch test_write.tmp > /dev/null 2>&1 && echo "✅ Écriture: OK" || echo "❌ Écriture: PROBLÈME"
rm -f test_write.tmp
echo "🔐 Droits sudo:"
timeout 1 sudo echo "✅ Sudo: OK" 2>/dev/null || echo "❌ Sudo: PROBLÈME"
echo ""

# Test 6: Création projet Zeus simple
echo "📊 TEST 6: PROJET ZEUS SIMPLE"
echo "============================"
mkdir -p zeus-diagnostic 2>/dev/null
cd zeus-diagnostic 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Dossier créé: $(pwd)"
    
    # Cargo.toml minimal
    cat > Cargo.toml << 'EOF'
[package]
name = "zeus-diagnostic"
version = "1.0.0"
edition = "2021"
EOF
    
    mkdir -p src
    
    # Code minimal
    cat > src/main.rs << 'EOF'
fn main() {
    println!("🔥 ZEUS DIAGNOSTIC: SUCCESS!");
    println!("⚡ Rust fonctionne parfaitement!");
}
EOF
    
    echo "📝 Fichiers créés:"
    ls -la
    echo ""
    
    # Test compilation
    echo "🏗️ Test compilation..."
    if cargo build 2>/dev/null; then
        echo "✅ Compilation: RÉUSSIE"
        echo "🚀 Test exécution:"
        ./target/debug/zeus-diagnostic
    else
        echo "❌ Compilation: ÉCHEC"
        echo "📋 Détails erreur:"
        cargo build
    fi
else
    echo "❌ Impossible de créer le dossier"
fi
echo ""

# Test 7: Diagnostic final
echo "🏆 DIAGNOSTIC FINAL"
echo "=================="

# Vérifications finales
PROBLEMS=0

if ! which curl > /dev/null 2>&1; then
    echo "❌ curl manquant - Installez: sudo apt install curl"
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! which gcc > /dev/null 2>&1; then
    echo "❌ build-essential manquant - Installez: sudo apt install build-essential"
    PROBLEMS=$((PROBLEMS + 1))
fi

if ! which rustc > /dev/null 2>&1; then
    echo "❌ Rust manquant - Réinstallez Rust"
    PROBLEMS=$((PROBLEMS + 1))
fi

if [ $PROBLEMS -eq 0 ]; then
    echo "✅✅✅ AUCUN PROBLÈME DÉTECTÉ !"
    echo "🔥 ZEUS PEUT FONCTIONNER SUR CE SYSTÈME !"
    echo ""
    echo "🚀 COMMANDES POUR INSTALLER ZEUS:"
    echo "================================="
    echo "mkdir zeus-final && cd zeus-final"
    echo "curl -O https://raw.githubusercontent.com/user/repo/zeus-install.sh"
    echo "chmod +x zeus-install.sh && ./zeus-install.sh"
else
    echo "❌ $PROBLEMS PROBLÈME(S) DÉTECTÉ(S)"
    echo ""
    echo "🔧 SOLUTION RAPIDE:"
    echo "=================="
    echo "sudo apt update"
    echo "sudo apt install -y curl build-essential pkg-config libssl-dev"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    echo "source ~/.cargo/env"
fi

echo ""
echo "🔥🔥🔥 DIAGNOSTIC ZEUS TERMINÉ 🔥🔥🔥"
echo "===================================="
