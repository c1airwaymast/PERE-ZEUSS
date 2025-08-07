# SCRIPT ZEUS ULTIMATE - NETTOYAGE ET ORGANISATION
# Version ultra-simple pour éviter les erreurs PowerShell

Write-Host "⚡ ZEUS ULTIMATE - NETTOYAGE WORKSPACE ⚡" -ForegroundColor Yellow

# Définir le chemin
$workspace = "c:\Users\ligth\Desktop\VS CODE OPTIMUS_ULTIMATE10"

# Confirmation
Write-Host "💀 ATTENTION: Suppression de tout le contenu actuel!" -ForegroundColor Red
$confirm = Read-Host "Tapez ZEUS pour confirmer"
if ($confirm -ne "ZEUS") { 
    Write-Host "❌ Annulé" -ForegroundColor Red
    exit 
}

# Arrêter les processus
Write-Host "🛑 Arrêt des processus..." -ForegroundColor Cyan
Get-Process | Where-Object {$_.ProcessName -match "cargo|rust"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Nettoyer (garder seulement ce script)
Write-Host "🧹 Nettoyage..." -ForegroundColor Cyan
Get-ChildItem -Path $workspace -Recurse | Where-Object {$_.Name -notmatch "ZEUS_CLEAN.ps1"} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Créer dossiers
Write-Host "📁 Création dossiers..." -ForegroundColor Cyan
@("src", "src\modules", "scripts", "docs", "tests") | ForEach-Object {
    New-Item -ItemType Directory -Path (Join-Path $workspace $_) -Force | Out-Null
}

# Copier fichiers finaux si ils existent
Write-Host "📋 Copie fichiers..." -ForegroundColor Cyan
if (Test-Path "README_FINAL.md") { Copy-Item "README_FINAL.md" "README.md" -Force }
if (Test-Path "Cargo_FINAL.toml") { Copy-Item "Cargo_FINAL.toml" "Cargo.toml" -Force }
if (Test-Path "src_FINAL\main.rs") { Copy-Item "src_FINAL\main.rs" "src\main.rs" -Force }
if (Test-Path "src_FINAL\zeus_uid_divine.rs") { Copy-Item "src_FINAL\zeus_uid_divine.rs" "src\zeus_uid_divine.rs" -Force }

Write-Host "✅ ZEUS WORKSPACE NETTOYÉ!" -ForegroundColor Green
Write-Host "🔧 Maintenant, créez les fichiers manquants manuellement:" -ForegroundColor Yellow
Write-Host "   1. src\lib.rs" -ForegroundColor White
Write-Host "   2. src\modules\*.rs" -ForegroundColor White
Write-Host "   3. scripts\build.bat" -ForegroundColor White

Read-Host "Appuyez sur Entrée pour terminer"
