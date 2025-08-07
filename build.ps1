# Build script for OPTIMUS ULTIMATE
param(
    [string]$Target = "release",
    [switch]$Clean,
    [switch]$Test,
    [switch]$Bench,
    [switch]$Doc
)

Write-Host "🔥 OPTIMUS ULTIMATE - Build Script" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Yellow

# Clean if requested
if ($Clean) {
    Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor Cyan
    cargo clean
}

# Run tests if requested
if ($Test) {
    Write-Host "🧪 Running tests..." -ForegroundColor Cyan
    cargo test --workspace
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Tests failed!" -ForegroundColor Red
        exit 1
    }
}

# Build project
Write-Host "🏗️ Building OPTIMUS ULTIMATE ($Target)..." -ForegroundColor Cyan

if ($Target -eq "release") {
    # Release build with maximum optimizations
    $env:RUSTFLAGS = "-C target-cpu=native -C opt-level=3 -C lto=fat"
    cargo build --release --workspace
} else {
    # Debug build
    cargo build --workspace
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# Run benchmarks if requested
if ($Bench) {
    Write-Host "📊 Running benchmarks..." -ForegroundColor Cyan
    cargo bench --workspace
}

# Generate documentation if requested
if ($Doc) {
    Write-Host "📚 Generating documentation..." -ForegroundColor Cyan
    cargo doc --workspace --no-deps --open
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green

# Display binary information
if ($Target -eq "release") {
    $binaryPath = "target\release\optimus-ultimate-cli.exe"
    if (Test-Path $binaryPath) {
        $size = (Get-Item $binaryPath).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "📦 Binary size: $sizeKB KB" -ForegroundColor Green
        Write-Host "📁 Location: $binaryPath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🚀 Ready for deployment!" -ForegroundColor Green
