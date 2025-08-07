#!/bin/bash
# Build script for OPTIMUS ULTIMATE on Unix systems

set -e

TARGET="release"
CLEAN=false
TEST=false
BENCH=false
DOC=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET="$2"
            shift 2
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --test)
            TEST=true
            shift
            ;;
        --bench)
            BENCH=true
            shift
            ;;
        --doc)
            DOC=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--target release|debug] [--clean] [--test] [--bench] [--doc]"
            exit 1
            ;;
    esac
done

echo "🔥 OPTIMUS ULTIMATE - Build Script"
echo "================================="

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning build artifacts..."
    cargo clean
fi

# Run tests if requested
if [ "$TEST" = true ]; then
    echo "🧪 Running tests..."
    cargo test --workspace
fi

# Build project
echo "🏗️ Building OPTIMUS ULTIMATE ($TARGET)..."

if [ "$TARGET" = "release" ]; then
    # Release build with maximum optimizations
    export RUSTFLAGS="-C target-cpu=native -C opt-level=3 -C lto=fat"
    cargo build --release --workspace
else
    # Debug build
    cargo build --workspace
fi

# Run benchmarks if requested
if [ "$BENCH" = true ]; then
    echo "📊 Running benchmarks..."
    cargo bench --workspace
fi

# Generate documentation if requested
if [ "$DOC" = true ]; then
    echo "📚 Generating documentation..."
    cargo doc --workspace --no-deps --open
fi

echo "✅ Build completed successfully!"

# Display binary information
if [ "$TARGET" = "release" ]; then
    BINARY_PATH="target/release/optimus-ultimate-cli"
    if [ -f "$BINARY_PATH" ]; then
        SIZE=$(du -h "$BINARY_PATH" | cut -f1)
        echo "📦 Binary size: $SIZE"
        echo "📁 Location: $BINARY_PATH"
    fi
fi

echo ""
echo "🚀 Ready for deployment!"
