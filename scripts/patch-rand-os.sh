#!/bin/bash
#
# Patch rand_os for tvOS/watchOS Support
#
# DESCRIPTION:
# This script patches the rand_os crate to enable compilation for tvOS and watchOS.
# These are Tier 2/3 Rust targets that are missing from rand_os v0.1.3's platform checks.
#
# WHY THIS IS NEEDED:
# The underlying CSL bridge pins rand_os v0.1.3 (from 2018) which has hardcoded compile-time
# checks that reject tvOS/watchOS before the platform-specific code can load. This patch
# enables these platforms by:
#
# 1. Adding tvOS/watchOS to the mod_use! macro that selects the macOS/iOS implementation
# 2. Adding tvOS/watchOS to the compile_error guard so they're recognized as supported
#
# The macOS/iOS implementation uses the Security framework's SecRandomCopyBytes, which is
# universally available on all Apple platforms (iOS, tvOS, watchOS, macOS).
#
# PATCH APPLICATION:
# Patches are CONDITIONALLY APPLIED only when tvOS or watchOS targets are detected:
#
#   Build Target       | Patching Applied | Reason
#   -------------------|------------------|--------------------------------------
#   macOS (host)       | ❌ No            | No tvOS/watchOS targets installed
#   Linux (host)       | ❌ No            | tvOS/watchOS unavailable on Linux
#   iOS                | ❌ No            | tvOS/watchOS targets not detected
#   tvOS               | ✅ Yes           | Targets detected (aarch64-apple-tvos)
#   watchOS            | ✅ Yes           | Targets detected (aarch64-apple-watchos)
#
# This ensures iOS, macOS, and Linux builds remain completely untouched.
#
# INIT.SH INTEGRATION:
# The init.sh script (Step 1b) detects tvOS/watchOS targets and only calls this script if:
#   - Running on macOS
#   - AND (aarch64-apple-tvos OR aarch64-apple-watchos targets are installed)
#
# Usage: ./patch-rand-os.sh [cargo_toml_path]
#        If cargo_toml_path is provided, updates Cargo.toml with git patches
#
# Note: This script should only be called when building for tvOS or watchOS targets.
#       It applies patches to rand_os that enable these platforms to compile.
#       The patches do not affect iOS, macOS, or Linux builds.
#

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to patch rand_os source code
patch_rand_os_source() {
    local rand_os_lib_path="$1"
    
    if [ ! -f "$rand_os_lib_path" ]; then
        echo "Warning: rand_os source file not found at $rand_os_lib_path"
        return 1
    fi
    
    echo "Patching rand_os source code at: $rand_os_lib_path"
    
    # Create a temporary Python script for reliable regex patching
    # Using Python instead of sed to avoid shell escaping complications
    cat > /tmp/patch_rand_os.py << 'PYTHONPATCH'
import sys
import re

file_path = sys.argv[1]
with open(file_path, 'r') as f:
    content = f.read()

# Patch 1: Update mod_use! for iOS to include tvOS and watchOS
# This allows module selection for tvOS/watchOS using the existing macOS implementation
content = re.sub(
    r'mod_use!\(cfg\(target_os = "ios"\), macos\);',
    'mod_use!(cfg(any(target_os = "ios", target_os = "tvos", target_os = "watchos")), macos);',
    content
)

# Patch 2: Add tvOS/watchOS to compile_error guard
# This prevents the "OS RNG support is not available" compile_error from triggering
content = re.sub(
    r'(\s+)target_os = "ios",(\s+)target_os = "linux",',
    r'\1target_os = "ios",\n\1target_os = "tvos",\n\1target_os = "watchos",\2target_os = "linux",',
    content
)

with open(file_path, 'w') as f:
    f.write(content)

print("Patched successfully")
PYTHONPATCH

    python3 /tmp/patch_rand_os.py "$rand_os_lib_path" || {
        echo "Error: Failed to patch rand_os source code"
        return 1
    }
    
    return 0
}

# Function to add Cargo.toml patches
add_cargo_patches() {
    local cargo_toml="$1"
    
    if [ ! -f "$cargo_toml" ]; then
        echo "Warning: Cargo.toml not found at $cargo_toml"
        return 1
    fi
    
    echo "Updating Cargo.toml with dependency patches: $cargo_toml"
    
    # Remove any existing patches first
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/\[patch.crates-io\]/,/^$/d' "$cargo_toml" 2>/dev/null || true
    else
        sed -i '/\[patch.crates-io\]/,/^$/d' "$cargo_toml" 2>/dev/null || true
    fi
    
    # Add patches to support tvOS/watchOS targets
    cat >> "$cargo_toml" <<'CARGOPATCH'

[patch.crates-io]
# Use modern getrandom that supports tvOS/watchOS
getrandom = { git = "https://github.com/rust-random/getrandom.git", rev = "f68a940" }
# Use older rand_os version that we patch for tvOS/watchOS
rand_os = { git = "https://github.com/rust-random/rand", rev = "267e19e" }
CARGOPATCH
    
    echo "Cargo.toml patching complete"
    return 0
}

# Main logic
main() {
    echo "=== Rand OS tvOS/watchOS Patching Script ==="
    
    # If Cargo.toml path provided, update dependency patches
    if [ -n "$1" ]; then
        add_cargo_patches "$1"
    fi
    
    # Wait for cargo to fetch dependencies
    sleep 2
    
    # Find and patch rand_os source file
    # Cargo may use different hashes for the git checkout, so search dynamically
    RAND_OS_LIB_PATH=$(find ~/.cargo/git/checkouts -type f -name "lib.rs" -path "*/rand_os*/src/lib.rs" 2>/dev/null | grep -v target | head -1)
    
    if [ -n "$RAND_OS_LIB_PATH" ]; then
        echo "Found rand_os at: $RAND_OS_LIB_PATH"
        patch_rand_os_source "$RAND_OS_LIB_PATH"
    else
        echo "Warning: Could not find rand_os source file. It may be patched during next build."
        return 1
    fi
    
    echo "=== Patching complete ==="
    return 0
}

main "$@"
