# 🔥 ZEUS UBUNTU CONNECTION & TEST SCRIPT
# Script pour se connecter à Ubuntu et lancer les tests ZEUS

param(
    [string]$UbuntuIP,
    [string]$Username = "root",
    [string]$SshKey = ""
)

Write-Host "🔥🔥🔥 ZEUS UBUNTU CONNECTION SCRIPT 🔥🔥🔥" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Yellow

if (!$UbuntuIP) {
    $UbuntuIP = Read-Host "🐧 IP de votre Ubuntu"
}

if (!$Username) {
    $Username = Read-Host "👤 Nom d'utilisateur Ubuntu (défaut: root)"
    if (!$Username) { $Username = "root" }
}

Write-Host "🔗 Connexion à Ubuntu: $Username@$UbuntuIP" -ForegroundColor Cyan

# Fonction pour exécuter commandes SSH
function Invoke-UbuntuCommand {
    param([string]$Command, [string]$Description)
    
    Write-Host "⚡ $Description..." -ForegroundColor Yellow
    
    if ($SshKey) {
        ssh -i $SshKey -o StrictHostKeyChecking=no $Username@$UbuntuIP $Command
    } else {
        ssh -o StrictHostKeyChecking=no $Username@$UbuntuIP $Command
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $Description - SUCCÈS" -ForegroundColor Green
    } else {
        Write-Host "❌ $Description - ÉCHEC" -ForegroundColor Red
    }
    
    return $LASTEXITCODE
}

# 1. Test de connexion
Write-Host "🧪 Test de connexion Ubuntu..." -ForegroundColor Cyan
$connectionTest = Invoke-UbuntuCommand "echo '🔥 ZEUS se connecte à Ubuntu! ⚡'" "Test connexion"

if ($connectionTest -ne 0) {
    Write-Host "❌ Impossible de se connecter à Ubuntu" -ForegroundColor Red
    Write-Host "💡 Vérifiez:" -ForegroundColor Yellow
    Write-Host "   • IP correcte: $UbuntuIP" -ForegroundColor White
    Write-Host "   • SSH activé sur Ubuntu" -ForegroundColor White
    Write-Host "   • Utilisateur existe: $Username" -ForegroundColor White
    Write-Host "   • Firewall autorise SSH (port 22)" -ForegroundColor White
    exit 1
}

# 2. Vérifier l'état Ubuntu
Write-Host "📊 Vérification état Ubuntu..." -ForegroundColor Cyan
Invoke-UbuntuCommand "uname -a && lsb_release -a 2>/dev/null" "Info système Ubuntu"

# 3. Copier le script de réparation
Write-Host "📤 Upload du script de diagnostic ZEUS..." -ForegroundColor Yellow

if ($SshKey) {
    scp -i $SshKey -o StrictHostKeyChecking=no "fix_ubuntu_zeus.sh" "$Username@$UbuntuIP:/tmp/"
} else {
    scp -o StrictHostKeyChecking=no "fix_ubuntu_zeus.sh" "$Username@$UbuntuIP:/tmp/"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Script uploadé avec succès" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur upload du script" -ForegroundColor Red
    exit 1
}

# 4. Rendre le script exécutable et le lancer
Write-Host "🚀 Exécution du diagnostic et réparation ZEUS..." -ForegroundColor Magenta
Invoke-UbuntuCommand "chmod +x /tmp/fix_ubuntu_zeus.sh" "Permissions script"
Invoke-UbuntuCommand "/tmp/fix_ubuntu_zeus.sh" "Diagnostic Ubuntu complet"

# 5. Déployer ZEUS Ultimate
Write-Host "⚡ Déploiement ZEUS Ultimate..." -ForegroundColor Red
Invoke-UbuntuCommand "sudo /tmp/deploy-zeus-ultimate.sh" "Déploiement ZEUS"

# 6. Tests ZEUS
Write-Host "🧪 TESTS ZEUS ULTIMATE" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow

Write-Host "📊 Test 1: Status ZEUS..." -ForegroundColor Cyan
Invoke-UbuntuCommand "zeus status" "Status ZEUS"

Write-Host "🚀 Test 2: Performance (100K messages)..." -ForegroundColor Cyan
Invoke-UbuntuCommand "zeus performance --messages 100000" "Test Performance"

Write-Host "📡 Test 3: Communication moderne..." -ForegroundColor Cyan
Invoke-UbuntuCommand "zeus comm-test --volume 50000" "Test Communication"

Write-Host "🏛️ Test 4: Benchmark OLYMPIEN..." -ForegroundColor Cyan
Invoke-UbuntuCommand "zeus benchmark" "Benchmark complet"

# 7. Résumé final
Write-Host "" -ForegroundColor White
Write-Host "🔥🔥🔥 RÉSUMÉ DÉPLOIEMENT ZEUS 🔥🔥🔥" -ForegroundColor Red
Write-Host "====================================" -ForegroundColor Yellow
Write-Host "🐧 Ubuntu: $UbuntuIP" -ForegroundColor White
Write-Host "👤 User: $Username" -ForegroundColor White
Write-Host "⚡ ZEUS Ultimate: DÉPLOYÉ" -ForegroundColor Green
Write-Host "" -ForegroundColor White
Write-Host "🎯 COMMANDES DISPONIBLES:" -ForegroundColor Cyan
Write-Host "  ssh $Username@$UbuntuIP 'zeus status'" -ForegroundColor White
Write-Host "  ssh $Username@$UbuntuIP 'zeus performance --messages 1000000'" -ForegroundColor White
Write-Host "  ssh $Username@$UbuntuIP 'zeus comm-test --volume 500000'" -ForegroundColor White
Write-Host "  ssh $Username@$UbuntuIP 'zeus benchmark'" -ForegroundColor White
Write-Host "  ssh $Username@$UbuntuIP 'zeus serve --port 8080'" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "🌐 TEST MANUEL:" -ForegroundColor Yellow
Write-Host "  1. ssh $Username@$UbuntuIP" -ForegroundColor White
Write-Host "  2. zeus status" -ForegroundColor White
Write-Host "  3. zeus performance --messages 1000000" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "⚡ ZEUS A CONQUIS UBUNTU! TESTS PRÊTS! ⚡" -ForegroundColor Red
