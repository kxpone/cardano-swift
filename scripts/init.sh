#!/bin/bash
set -e

# Configuration
BRIDGE_REPO="https://github.com/Emurgo/csl-mobile-bridge.git"
BRIDGE_TAG="9.0.1" # Current stable release supporting CSL 15+
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/.build/native-bridge"
DEST_DIR="$PROJECT_ROOT/Sources/CCardano"

echo "Step 1: Cloning/Updating native Cardano Rust bridge (version $BRIDGE_TAG)..."
if [ ! -d "$BUILD_DIR" ]; then
    git clone --depth 1 --branch "$BRIDGE_TAG" "$BRIDGE_REPO" "$BUILD_DIR"
else
    echo "Bridge repo already exists, ensuring it is on $BRIDGE_TAG..."
    cd "$BUILD_DIR"
    git fetch origin tag "$BRIDGE_TAG" --depth 1
    git checkout "$BRIDGE_TAG"
    cd -
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
    if rustup target list --installed | grep -q "apple-ios"; then
        IOS_SIM_LIBS=""
        for target in aarch64-apple-ios-sim x86_64-apple-ios; do
            if rustup target list --installed | grep -q "$target"; then
                echo "Building for iOS Simulator ($target)..."
                cargo build --target $target --release
                IOS_SIM_LIBS="$IOS_SIM_LIBS $BUILD_DIR/rust/target/$target/release/libreact_native_haskell_shelley.a"
            fi
        done
        # No lipo here as typically we use XCframeworks or single architectures for sim in CI
    fi

    # tvOS Support
    if rustup target list --installed | grep -q "apple-tvos"; then
        TVOS_LIBS=""
        for target in aarch64-apple-tvos aarch64-apple-tvos-sim x86_64-apple-tvos; do
            if rustup target list --installed | grep -q "$target"; then
                echo "Building for tvOS ($target)..."
                cargo build --target $target --release
                TVOS_LIBS="$TVOS_LIBS $BUILD_DIR/rust/target/$target/release/libreact_native_haskell_shelley.a"
            fi
        done
        if [ ! -z "$TVOS_LIBS" ]; then
            mkdir -p "$DEST_DIR/tvos"
            lipo -create $TVOS_LIBS -output "$DEST_DIR/tvos/libreact_native_haskell_shelley.a"
        fi
    fi

    # watchOS Support
    if rustup target list --installed | grep -q "apple-watchos"; then
        WATCH_LIBS=""
        for target in aarch64-apple-watchos aarch64-apple-watchos-sim arm64_32-apple-watchos armv7k-apple-watchos x86_64-apple-watchos-sim; do
            if rustup target list --installed | grep -q "$target"; then
                echo "Building for watchOS ($target)..."
                cargo build --target $target --release
                WATCH_LIBS="$WATCH_LIBS $BUILD_DIR/rust/target/$target/release/libreact_native_haskell_shelley.a"
            fi
        done
        if [ ! -z "$WATCH_LIBS" ]; then
            mkdir -p "$DEST_DIR/watchos"
            lipo -create $WATCH_LIBS -output "$DEST_DIR/watchos/libreact_native_haskell_shelley.a"
        fi
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
