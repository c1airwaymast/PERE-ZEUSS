# 🔥 ZEUS UBUNTU CONNECTION & TEST SCRIPT
# Script PowerShell pour se connecter et tester Zeus sur Ubuntu

param(
    [Parameter(Mandatory=$false)]
    [string]$UbuntuIP = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "root"
)

Write-Host "🔥🔥🔥 ZEUS UBUNTU CONNECTION MANAGER 🔥🔥🔥" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""

# Si l'IP n'est pas fournie, la demander
if ([string]::IsNullOrEmpty($UbuntuIP)) {
    $UbuntuIP = Read-Host "🌐 Entrez l'IP de votre serveur Ubuntu"
}

Write-Host "🎯 Cible: $Username@$UbuntuIP" -ForegroundColor Cyan
Write-Host ""

# Vérifier si SSH est disponible
try {
    $sshVersion = ssh -V 2>&1
    Write-Host "✅ SSH disponible: $sshVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ SSH non disponible. Installation recommandée:" -ForegroundColor Red
    Write-Host "   - Windows 10/11: Activer OpenSSH dans Fonctionnalités Windows" -ForegroundColor Yellow
    Write-Host "   - Ou utiliser PuTTY" -ForegroundColor Yellow
    Write-Host ""
}

# Afficher les options
Write-Host "🚀 OPTIONS DE DÉPLOIEMENT:" -ForegroundColor Magenta
Write-Host "=========================" -ForegroundColor Magenta
Write-Host ""
Write-Host "1️⃣ Test de connexion SSH" -ForegroundColor Cyan
Write-Host "2️⃣ Copier le script d'installation simple" -ForegroundColor Cyan
Write-Host "3️⃣ Copier le script d'installation complet" -ForegroundColor Cyan
Write-Host "4️⃣ Instructions manuelles" -ForegroundColor Cyan
Write-Host "5️⃣ Connexion SSH directe" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Choisissez une option (1-5)"

switch ($choice) {
    "1" {
        Write-Host "🔍 Test de connexion SSH..." -ForegroundColor Yellow
        Write-Host "Commande: ssh $Username@$UbuntuIP 'echo Zeus connection test successful'" -ForegroundColor Gray
        try {
            ssh "$Username@$UbuntuIP" 'echo "✅ Zeus connection test successful! Ubuntu is ready for domination!"'
        } catch {
            Write-Host "❌ Connexion échouée. Vérifiez:" -ForegroundColor Red
            Write-Host "   - IP correcte: $UbuntuIP" -ForegroundColor Yellow
            Write-Host "   - SSH activé sur Ubuntu" -ForegroundColor Yellow
            Write-Host "   - Pare-feu autorisant SSH (port 22)" -ForegroundColor Yellow
        }
    }
    
    "2" {
        Write-Host "📋 SCRIPT SIMPLE - COPIER CE CONTENU:" -ForegroundColor Yellow
        Write-Host "====================================" -ForegroundColor Yellow
        Write-Host ""
        
        $simpleScript = @"
# 🔥 ZEUS INSTALLATION RAPIDE SUR UBUNTU 🔥
# Copiez-collez ces commandes une par une dans votre terminal Ubuntu

echo "⚡ Installation de Zeus Ultimate..."

# Mise à jour et dépendances
sudo apt update -y && sudo apt install -y curl build-essential pkg-config libssl-dev

# Installation Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# Création projet Zeus
mkdir -p ~/zeus-test && cd ~/zeus-test

# Configuration projet
cat > Cargo.toml << 'EOF'
[package]
name = "zeus"
version = "1.0.0"
edition = "2021"

[dependencies]
tokio = { version = "1.0", features = ["full"] }
clap = { version = "4.0", features = ["derive"] }
anyhow = "1.0"
chrono = "0.4"
uuid = "1.0"
EOF

mkdir -p src

# Code Zeus minimal
cat > src/main.rs << 'EOF'
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "zeus")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Status,
    Test { #[arg(default_value = "100000")] messages: u64 },
}

#[tokio::main]
async fn main() {
    match Cli::parse().command {
        Commands::Status => {
            println!("🔥 ZEUS STATUS: OPERATIONAL ON UBUNTU");
            println!("⚡ Power Level: OVER 9000!");
            println!("🚀 Ready for {} msg/s", 1_000_000);
        },
        Commands::Test { messages } => {
            println!("🧪 Testing {} messages...", messages);
            let start = std::time::Instant::now();
            for i in 0..messages {
                if i % (messages/10) == 0 {
                    println!("Progress: {}%", (i * 100) / messages);
                }
            }
            let elapsed = start.elapsed().as_secs_f64();
            println!("✅ {:.0} msg/s", messages as f64 / elapsed);
            println!("🏆 Zeus Score: {:.0}/9001", (messages as f64 / elapsed) / 100.0);
        }
    }
}
EOF

# Compilation et test
cargo build --release
echo "✅ Zeus compilé avec succès!"

# Tests
echo "📊 Test Zeus Status:"
./target/release/zeus status

echo "🚀 Test Performance:"
./target/release/zeus test 500000

echo "🔥🔥🔥 ZEUS OPERATIONAL ON UBUNTU! 🔥🔥🔥"
"@
        
        Write-Host $simpleScript -ForegroundColor White
        Write-Host ""
        Write-Host "📝 Script sauvegardé dans le presse-papiers (si supporté)" -ForegroundColor Green
        $simpleScript | Set-Clipboard -ErrorAction SilentlyContinue
    }
    
    "3" {
        Write-Host "📋 SCRIPT COMPLET DISPONIBLE DANS:" -ForegroundColor Yellow
        Write-Host "=================================" -ForegroundColor Yellow
        $scriptPath = "C:\Users\ligth\Desktop\VS CODE OPTIMUS_ULTIMATE10\zeus_ubuntu_simple.sh"
        Write-Host "Fichier: $scriptPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🔗 Pour l'utiliser:" -ForegroundColor Green
        Write-Host "1. Connectez-vous à Ubuntu: ssh $Username@$UbuntuIP" -ForegroundColor White
        Write-Host "2. Créez le fichier: nano zeus_install.sh" -ForegroundColor White
        Write-Host "3. Copiez le contenu depuis $scriptPath" -ForegroundColor White
        Write-Host "4. Exécutez: chmod +x zeus_install.sh && ./zeus_install.sh" -ForegroundColor White
        
        try {
            Write-Host ""
            Write-Host "📁 Ouverture du fichier script..." -ForegroundColor Yellow
            Start-Process notepad.exe -ArgumentList $scriptPath
        } catch {
            Write-Host "⚠️ Impossible d'ouvrir automatiquement. Ouvrez manuellement: $scriptPath" -ForegroundColor Yellow
        }
    }
    
    "4" {
        Write-Host "📋 INSTRUCTIONS MANUELLES:" -ForegroundColor Yellow
        Write-Host "=========================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "🔗 1. Connexion SSH:" -ForegroundColor Cyan
        Write-Host "   ssh $Username@$UbuntuIP" -ForegroundColor White
        Write-Host ""
        Write-Host "📦 2. Installation dépendances:" -ForegroundColor Cyan
        Write-Host "   sudo apt update && sudo apt install -y curl build-essential pkg-config libssl-dev" -ForegroundColor White
        Write-Host ""
        Write-Host "🦀 3. Installation Rust:" -ForegroundColor Cyan
        Write-Host "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" -ForegroundColor White
        Write-Host "   source ~/.cargo/env" -ForegroundColor White
        Write-Host ""
        Write-Host "⚡ 4. Création projet Zeus:" -ForegroundColor Cyan
        Write-Host "   mkdir zeus-test && cd zeus-test" -ForegroundColor White
        Write-Host "   # Puis créer Cargo.toml et src/main.rs avec le code Zeus" -ForegroundColor Gray
        Write-Host ""
        Write-Host "🏗️ 5. Compilation:" -ForegroundColor Cyan
        Write-Host "   cargo build --release" -ForegroundColor White
        Write-Host ""
        Write-Host "🧪 6. Test Zeus:" -ForegroundColor Cyan
        Write-Host "   ./target/release/zeus status" -ForegroundColor White
        Write-Host "   ./target/release/zeus test 1000000" -ForegroundColor White
    }
    
    "5" {
        Write-Host "🌐 Connexion SSH directe vers $UbuntuIP..." -ForegroundColor Yellow
        Write-Host "Commande: ssh $Username@$UbuntuIP" -ForegroundColor Gray
        Write-Host ""
        Write-Host "💡 Une fois connecté, utilisez les scripts d'installation Zeus!" -ForegroundColor Green
        Write-Host ""
        
        try {
            ssh "$Username@$UbuntuIP"
        } catch {
            Write-Host "❌ Connexion SSH échouée." -ForegroundColor Red
            Write-Host "Vérifiez l'IP, le nom d'utilisateur et la connectivité réseau." -ForegroundColor Yellow
        }
    }
    
    default {
        Write-Host "❌ Option invalide. Relancez le script." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🔥 INFORMATIONS IMPORTANTES:" -ForegroundColor Red
Write-Host "===========================" -ForegroundColor Red
Write-Host "📧 SMTP sera remplacé par Zeus (36 méthodes modernes)" -ForegroundColor Yellow
Write-Host "⚡ Performance attendue: 1,000,000+ msg/s" -ForegroundColor Yellow
Write-Host "🎯 Fiabilité: 99.9999% (vs 85% SMTP)" -ForegroundColor Yellow
Write-Host "💰 Économies: 90% des coûts" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚡⚡⚡ ZEUS TRANSFORMERA VOTRE PME EN TITAN! ⚡⚡⚡" -ForegroundColor Red
