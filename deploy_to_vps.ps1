# 🔥 ZEUS VPS DEPLOYMENT MASTER SCRIPT
# Déploiement automatique sur VPS Ubuntu

param(
    [string]$VpsIp = "",
    [string]$VpsUser = "root",
    [string]$SshKey = "",
    [switch]$UseDocker = $false
)

Write-Host "🔥🔥🔥 ZEUS VPS DEPLOYMENT OLYMPIEN 🔥🔥🔥" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Yellow

if ($VpsIp -eq "") {
    $VpsIp = Read-Host "🌐 IP du VPS Ubuntu"
}

if ($VpsUser -eq "") {
    $VpsUser = Read-Host "👤 Utilisateur SSH (défaut: root)"
    if ($VpsUser -eq "") { $VpsUser = "root" }
}

Write-Host "⚡ Configuration:" -ForegroundColor Cyan
Write-Host "   🌐 VPS: $VpsIp" -ForegroundColor White
Write-Host "   👤 User: $VpsUser" -ForegroundColor White
Write-Host "   🐳 Docker: $UseDocker" -ForegroundColor White

# Fonction pour exécuter commandes SSH
function Invoke-SshCommand {
    param([string]$Command)
    
    if ($SshKey -ne "") {
        ssh -i $SshKey -o StrictHostKeyChecking=no $VpsUser@$VpsIp $Command
    } else {
        ssh -o StrictHostKeyChecking=no $VpsUser@$VpsIp $Command
    }
}

# Fonction pour copier fichiers
function Copy-ToVps {
    param([string]$LocalPath, [string]$RemotePath)
    
    if ($SshKey -ne "") {
        scp -i $SshKey -o StrictHostKeyChecking=no $LocalPath $VpsUser@$VpsIp`:$RemotePath
    } else {
        scp -o StrictHostKeyChecking=no $LocalPath $VpsUser@$VpsIp`:$RemotePath
    }
}

Write-Host "🔧 Préparation du VPS..." -ForegroundColor Green

# Mise à jour du système
Write-Host "📦 Mise à jour du système Ubuntu..." -ForegroundColor Yellow
Invoke-SshCommand "apt update && apt upgrade -y"

if ($UseDocker) {
    Write-Host "🐳 Installation Docker..." -ForegroundColor Cyan
    
    # Installation Docker
    Invoke-SshCommand @"
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu `$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker
"@

    # Copier le projet sur VPS
    Write-Host "📁 Copie du projet sur VPS..." -ForegroundColor Yellow
    Invoke-SshCommand "mkdir -p /opt/optimus-ultimate"
    
    # Créer archive du projet
    $tempArchive = "$env:TEMP\optimus-ultimate.tar.gz"
    tar -czf $tempArchive --exclude=target --exclude=.git * 
    
    Copy-ToVps $tempArchive "/opt/optimus-ultimate/project.tar.gz"
    
    # Extraire et compiler avec Docker
    Invoke-SshCommand @"
cd /opt/optimus-ultimate
tar -xzf project.tar.gz
docker build -f Dockerfile.linux -t optimus-ultimate .
docker run --name optimus-build optimus-ultimate
docker cp optimus-build:/usr/local/bin/optimus-ultimate-cli ./optimus-ultimate-cli
docker rm optimus-build
chmod +x optimus-ultimate-cli
"@

} else {
    Write-Host "🦀 Installation Rust sur VPS..." -ForegroundColor Yellow
    
    # Installation Rust
    Invoke-SshCommand @"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env
apt install -y build-essential pkg-config libssl-dev
"@

    # Copier le projet
    Write-Host "📁 Copie et compilation du projet..." -ForegroundColor Yellow
    Invoke-SshCommand "mkdir -p /opt/optimus-ultimate"
    
    # Créer archive
    $tempArchive = "$env:TEMP\optimus-ultimate.tar.gz"
    tar -czf $tempArchive --exclude=target --exclude=.git *
    
    Copy-ToVps $tempArchive "/opt/optimus-ultimate/project.tar.gz"
    
    # Compiler sur VPS
    Invoke-SshCommand @"
cd /opt/optimus-ultimate
tar -xzf project.tar.gz
source ~/.cargo/env
cargo build --release
cp target/release/optimus-ultimate-cli ./optimus-ultimate-cli
chmod +x optimus-ultimate-cli
"@
}

Write-Host "⚙️ Configuration du service systemd..." -ForegroundColor Green

# Créer service systemd
$serviceConfig = @"
[Unit]
Description=OPTIMUS ULTIMATE Security Suite
After=network.target

[Service]
Type=simple
User=optimus
WorkingDirectory=/opt/optimus-ultimate
ExecStart=/opt/optimus-ultimate/optimus-ultimate-cli status
Restart=always
RestartSec=10
Environment=RUST_LOG=info

[Install]
WantedBy=multi-user.target
"@

$serviceConfig | Out-File -FilePath "$env:TEMP\optimus-ultimate.service" -Encoding UTF8
Copy-ToVps "$env:TEMP\optimus-ultimate.service" "/etc/systemd/system/optimus-ultimate.service"

# Configuration utilisateur et permissions
Invoke-SshCommand @"
useradd -r -s /bin/false optimus 2>/dev/null || true
chown -R optimus:optimus /opt/optimus-ultimate
systemctl daemon-reload
systemctl enable optimus-ultimate
systemctl start optimus-ultimate
"@

Write-Host "🌐 Configuration du firewall..." -ForegroundColor Yellow
Invoke-SshCommand @"
ufw allow ssh
ufw allow 8080/tcp
ufw allow 8443/tcp
ufw --force enable
"@

Write-Host "🔍 Vérification du déploiement..." -ForegroundColor Cyan
$status = Invoke-SshCommand "systemctl is-active optimus-ultimate"
$health = Invoke-SshCommand "/opt/optimus-ultimate/optimus-ultimate-cli status 2>/dev/null || echo 'En cours de démarrage...'"

Write-Host "" -ForegroundColor White
Write-Host "✅ DÉPLOIEMENT ZEUS TERMINÉ!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Yellow
Write-Host "🌐 VPS: $VpsIp" -ForegroundColor White
Write-Host "📊 Status: $status" -ForegroundColor White
Write-Host "🔍 Health: $health" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "🚀 COMMANDES UTILES:" -ForegroundColor Cyan
Write-Host "   Statut:    ssh $VpsUser@$VpsIp 'systemctl status optimus-ultimate'" -ForegroundColor White
Write-Host "   Logs:      ssh $VpsUser@$VpsIp 'journalctl -u optimus-ultimate -f'" -ForegroundColor White
Write-Host "   Test:      ssh $VpsUser@$VpsIp '/opt/optimus-ultimate/optimus-ultimate-cli status'" -ForegroundColor White
Write-Host "   Restart:   ssh $VpsUser@$VpsIp 'systemctl restart optimus-ultimate'" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "⚡ ZEUS A CONQUIS LE VPS! OPTIMUS ULTIMATE EST DÉPLOYÉ!" -ForegroundColor Red
