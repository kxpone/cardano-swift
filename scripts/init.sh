#!/bin/bash
set -e

# Configuration
BRIDGE_REPO="https://github.com/Emurgo/csl-mobile-bridge.git"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/.build/native-bridge"
DEST_DIR="$PROJECT_ROOT/Sources/CCardano"

echo "Step 1: Cloning/Updating native Cardano Rust bridge..."
if [ ! -d "$BUILD_DIR" ]; then
    git clone --depth 1 "$BRIDGE_REPO" "$BUILD_DIR"
else
    echo "Bridge repo already exists, skipping clone."
fi

echo "Step 2: Building Rust static library..."
cd "$BUILD_DIR/rust"

# Build for current host system (Linux/macOS)
echo "Building for host architecture..."
if [ ! -f "target/release/libreact_native_haskell_shelley.a" ]; then
    cargo build --release
else
    echo "Host binary already exists, skipping build (run 'cargo clean' in $BUILD_DIR/rust to force rebuild)."
fi

# If on macOS, also attempt to build for iOS if rustup targets are available
if [[ "$(uname)" == "Darwin" ]]; then
    if rustup target list --installed | grep -q "aarch64-apple-ios"; then
        echo "Building for iOS (aarch64)..."
        cargo build --target aarch64-apple-ios --release
        mkdir -p "$DEST_DIR/ios"
        cp "$BUILD_DIR/rust/target/aarch64-apple-ios/release/libreact_native_haskell_shelley.a" "$DEST_DIR/ios/"
    fi
    if rustup target list --installed | grep -q "x86_64-apple-ios"; then
        echo "Building for iOS Simulator (x86_64)..."
        cargo build --target x86_64-apple-ios --release
        # Note: In a real world scenario, you'd use lipo to create a fat binary or XCFramework
    fi
fi

echo "Step 3: Generating C headers..."
mkdir -p "$BUILD_DIR/include"
if ! command -v cbindgen &> /dev/null; then
    echo "cbindgen not found, installing..."
    cargo install cbindgen
fi
cbindgen --config cbindgen.toml --output "$BUILD_DIR/include/react_native_haskell_shelley.h"

echo "Step 4: Installing binaries to $DEST_DIR..."
OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_NAME=$(uname -m)
PLATFORM_DIR="$DEST_DIR/$OS_NAME"

mkdir -p "$DEST_DIR/include"
mkdir -p "$PLATFORM_DIR"

cp "$BUILD_DIR/include/react_native_haskell_shelley.h" "$DEST_DIR/include/"
cp "$BUILD_DIR/rust/target/release/libreact_native_haskell_shelley.a" "$PLATFORM_DIR/"

echo "SUCCESS: Native environment is ready ($OS_NAME/$ARCH_NAME)."
