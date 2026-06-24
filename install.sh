#!/usr/bin/env bash
# 1bit installer — one-command setup for Strix Halo 1-bit inference
# Usage: curl -fsSL https://raw.githubusercontent.com/bong-water-water-bong/1bit-engine/main/install.sh | bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[1bit]${NC} $*"; }
warn() { echo -e "${YELLOW}[1bit]${NC} $*"; }
err()  { echo -e "${RED}[1bit]${NC} $*"; exit 1; }

# ── detect ──

OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$ARCH" != "x86_64" ]; then
    err "Unsupported architecture: $ARCH. Strix Halo requires x86_64."
fi

INSTALL_DIR="${1:-$HOME/1bit}"
ROCM_CPP_DIR="$INSTALL_DIR/rocm-cpp"
ENGINE_DIR="$INSTALL_DIR/engine"
MODELS_DIR="${MODELS_DIR:-$HOME/models}"
MODEL_URL="${MODEL_URL:-}"
RELEASE_TAG="${RELEASE_TAG:-v0.2.0}"

log "1bit installer — Strix Halo 1-bit inference"
log "Install directory: $INSTALL_DIR"
log "Models directory: $MODELS_DIR"

# ── detect package manager ──

PKG=""
if command -v apt-get &>/dev/null; then
    PKG="apt"
elif command -v pacman &>/dev/null; then
    PKG="pacman"
elif command -v dnf &>/dev/null; then
    PKG="dnf"
else
    warn "Unknown package manager. Trying to continue with prerequisites already installed."
fi

log "Detected: $PKG package manager"

# ── install dependencies ──

install_deps() {
    log "Installing build dependencies..."
    case "$PKG" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y -qq \
                build-essential cmake ninja-build git curl \
                rocm-hip-runtime-dev hsa-rocr-dev hip-dev rocm-cmake \
                python3 python3-pip
            # Fix ROCm symlinks if needed
            if [ ! -f /opt/rocm/bin/hipcc ] && [ -f /usr/bin/hipcc ]; then
                sudo ln -sf /usr/bin/hipcc /opt/rocm/bin/hipcc 2>/dev/null || true
            fi
            if [ ! -f /opt/rocm/bin/hipconfig ] && [ -f /usr/bin/hipconfig ]; then
                sudo ln -sf /usr/bin/hipconfig /opt/rocm/bin/hipconfig 2>/dev/null || true
            fi
            # Fix libxml2 for ld.lld
            if ! ldconfig -p | grep -q libxml2.so.2; then
                sudo ln -sf /usr/lib/x86_64-linux-gnu/libxml2.so.16 /usr/lib/x86_64-linux-gnu/libxml2.so.2 2>/dev/null || true
            fi
            ;;
        pacman)
            sudo pacman -Sy --noconfirm base-devel cmake ninja git curl python python-pip rocm-hip-sdk
            ;;
        dnf)
            sudo dnf install -y gcc-c++ cmake ninja-build git curl python3 python3-pip rocm-hip-devel
            ;;
        *)
            warn "Please install: cmake ninja git curl build-essential rocm-hip-sdk"
            warn "Then re-run this script."
            ;;
    esac
}

install_deps

# ── install Rust ──

if command -v cargo &>/dev/null; then
    log "Rust already installed: $(rustc --version)"
else
    log "Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

mkdir -p "$INSTALL_DIR" "$MODELS_DIR"

# ── build rocm-cpp ──

log "Building rocm-cpp (HIP kernels)..."
if [ -d "$ROCM_CPP_DIR" ]; then
    log "rocm-cpp already cloned, updating..."
    (cd "$ROCM_CPP_DIR" && git pull origin main)
else
    git clone https://github.com/bong-water-water-bong/rocm-cpp.git "$ROCM_CPP_DIR"
fi

cd "$ROCM_CPP_DIR"
cmake -B build -G Ninja \
    -DCMAKE_HIP_ARCHITECTURES=gfx1151 \
    2>&1 | tail -3
ninja -C build rocm_cpp bitnet_decode 2>&1 | tail -3

log "rocm-cpp built successfully"
log "  library: $ROCM_CPP_DIR/build/librocm_cpp.so"
log "  binary:  $ROCM_CPP_DIR/build/bitnet_decode"

# ── build 1bit-engine ──

log "Building 1bit-engine (Rust server)..."
if [ -d "$ENGINE_DIR" ]; then
    log "Engine already cloned, updating..."
    (cd "$ENGINE_DIR" && git pull origin main)
else
    git clone https://github.com/bong-water-water-bong/1bit-engine.git "$ENGINE_DIR"
fi

cd "$ENGINE_DIR"
source "$HOME/.cargo/env"
export ROCM_PATH=/opt/rocm
export HSA_OVERRIDE_GFX_VERSION=11.5.1
export HSA_ENABLE_SDMA=0
cargo build --release 2>&1 | tail -3

log "1bit-engine built successfully"
log "  binary: $ENGINE_DIR/target/release/onebit"

# ── suggest model download ──

log ""
log "╔══════════════════════════════════════════════════════╗"
log "║  Installation complete!                              ║"
log "╠══════════════════════════════════════════════════════╣"
log "║                                                      ║"
log "║  Next: download a 1-bit model. Options:               "
log "║                                                      ║"
log "║  1. Pre-converted models (recommended):               "
log "║     Visit https://huggingface.co/models               "
log "║     Search for 'bitnet b1.58' or 'bonsai-1bit'       "
log "║                                                      ║"
log "║  2. Convert from safetensors:                         "
log "║     cd $ROCM_CPP_DIR                                  "
log "║     pip install torch safetensors                     "
log "║     python tools/export_bitnet.py --model MODEL_ID \\  "
log "║       --out $MODELS_DIR/model.h1b                     "
log "║                                                      ║"
log "║  Then run:                                            "
log "║    source ~/.cargo/env                                "
log "║    export HSA_OVERRIDE_GFX_VERSION=11.5.1             "
log "║    export HSA_ENABLE_SDMA=0                           "
log "║    $ENGINE_DIR/target/release/onebit \\                "
log "║      --model $MODELS_DIR/model.h1b \\                  "
log "║      --port 13305 --tune-prefill --fp16-weights       "
log "║                                                      ║"
log "╚══════════════════════════════════════════════════════╝"
log ""
log "Visit https://1bit.systems for documentation."
