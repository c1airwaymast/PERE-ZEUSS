# 🔥 ZEUS CROSS-COMPILATION SCRIPT FOR UBUNTU VPS (WINDOWS VERSION)
# Compilation croisée Windows -> Linux pour déploiement VPS

Write-Host "🔥🔥🔥 ZEUS CROSS-COMPILATION POUR VPS UBUNTU 🔥🔥🔥" -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "⚡ Compilation depuis Windows vers Linux Ubuntu..." -ForegroundColor Cyan

# Vérifier si Rust est installé
if (!(Get-Command "rustc" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Rust n'est pas installé!" -ForegroundColor Red
    Write-Host "📦 Installation de Rust..." -ForegroundColor Yellow
    
    # Télécharger et installer Rust
    $rustupPath = "$env:TEMP\rustup-init.exe"
    Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $rustupPath
    Start-Process -FilePath $rustupPath -ArgumentList "-y" -Wait
    
    # Recharger le PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

Write-Host "🎯 Configuration de la target Linux..." -ForegroundColor Green
rustup target add x86_64-unknown-linux-gnu

Write-Host "🔗 Installation du linker pour cross-compilation..." -ForegroundColor Green
# Pour Windows, nous devons installer GCC via MSYS2 ou utiliser un linker alternatif
if (!(Get-Command "x86_64-w64-mingw32-gcc" -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ Installation de MinGW-w64 recommandée pour le linker..." -ForegroundColor Yellow
    Write-Host "💡 Alternative: Utilisation de cross-compilation via Docker..." -ForegroundColor Cyan
    
    # Créer configuration Cargo pour cross-compilation
    $cargoConfigDir = "$env:USERPROFILE\.cargo"
    if (!(Test-Path $cargoConfigDir)) {
        New-Item -ItemType Directory -Path $cargoConfigDir -Force
    }
    
    $cargoConfig = @"
[target.x86_64-unknown-linux-gnu]
linker = "rust-lld"

[build]
target-dir = "target"
"@
    
    $cargoConfig | Out-File -FilePath "$cargoConfigDir\config.toml" -Encoding UTF8
}

Write-Host "🚀 Démarrage compilation cross-platform..." -ForegroundColor Magenta

# Compilation avec gestion d'erreur
try {
    cargo build --release --target x86_64-unknown-linux-gnu
    
    Write-Host "✅ Compilation terminée!" -ForegroundColor Green
    Write-Host "📁 Binaire Linux généré dans: target\x86_64-unknown-linux-gnu\release\" -ForegroundColor Cyan
    
    # Créer archive pour VPS
    Write-Host "📦 Création archive pour VPS..." -ForegroundColor Yellow
    
    $archivePath = "optimus-ultimate-linux.tar.gz"
    $sourceDir = "target\x86_64-unknown-linux-gnu\release"
    
    # Utiliser tar Windows 10+ ou 7zip
    if (Get-Command "tar" -ErrorAction SilentlyContinue) {
        tar -czf $archivePath -C $sourceDir *
    } else {
        # Alternative avec Compress-Archive (zip)
        $zipPath = "optimus-ultimate-linux.zip"
        Compress-Archive -Path "$sourceDir\*" -DestinationPath $zipPath -Force
        Write-Host "📦 Archive ZIP créée: $zipPath" -ForegroundColor Cyan
    }
    
    Write-Host "🌐 Archive prête pour upload VPS!" -ForegroundColor Green
    Write-Host "⚡ ZEUS A TRIOMPHÉ DE LA CROSS-COMPILATION!" -ForegroundColor Red
    
} catch {
    Write-Host "❌ Erreur de compilation: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Solution alternative: Compilation via Docker..." -ForegroundColor Yellow
    
    # Proposer compilation Docker
    Write-Host "🐳 Création de la solution Docker..." -ForegroundColor Cyan
    
    $dockerFile = @"
FROM rust:1.75-slim as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy project files
COPY . .

# Build release version
RUN cargo build --release

# Create minimal runtime image
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binary
COPY --from=builder /app/target/release/optimus-ultimate-cli /usr/local/bin/

# Create app user
RUN useradd -r -s /bin/false optimus

USER optimus

CMD ["optimus-ultimate-cli", "--help"]
"@
    
    $dockerFile | Out-File -FilePath "Dockerfile.linux" -Encoding UTF8
    
    Write-Host "✅ Dockerfile créé: Dockerfile.linux" -ForegroundColor Green
    Write-Host "🚀 Pour compiler avec Docker:" -ForegroundColor Cyan
    Write-Host "   docker build -f Dockerfile.linux -t optimus-ultimate-linux ." -ForegroundColor White
    Write-Host "   docker run --rm -v ${PWD}:/output optimus-ultimate-linux cp /usr/local/bin/optimus-ultimate-cli /output/" -ForegroundColor White
}

Write-Host "" -ForegroundColor White
Write-Host "🔥 ZEUS PROPOSE 3 SOLUTIONS DE DEPLOYMENT:" -ForegroundColor Red
Write-Host "1. 📦 Cross-compilation directe (si réussie)" -ForegroundColor Yellow
Write-Host "2. 🐳 Compilation Docker (recommandée)" -ForegroundColor Cyan  
Write-Host "3. 🌐 Compilation directe sur VPS" -ForegroundColor Green
Write-Host "" -ForegroundColor White
