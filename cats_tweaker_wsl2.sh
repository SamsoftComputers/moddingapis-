#!/bin/bash
#===============================================================================
#
#     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
#    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
#    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
#    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
#    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
#     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
#
#                              「  v2.0 - WSL2 Ubuntu 24.04/25.04 Edition  」
#                                    by Flames / Team Flames 🐱
#
#   WSL2-specific fixes:
#     - No systemd dependency
#     - Native N64 toolchain (no Docker required)
#     - WSLg GUI support for emulators
#     - Ubuntu 24.04+ pip handling (--break-system-packages)
#     - AppImage extraction for WSL2 compatibility
#     - Windows interop paths
#
#===============================================================================

set -euo pipefail

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════════
# COLORS & GLOBALS
# ═══════════════════════════════════════════════════════════════════════════════
G=$'\033[0;32m'  # Green
Y=$'\033[0;33m'  # Yellow  
C=$'\033[0;36m'  # Cyan
M=$'\033[0;35m'  # Magenta
R=$'\033[0;31m'  # Red
W=$'\033[1;37m'  # White bold
RST=$'\033[0m'   # Reset

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

# ═══════════════════════════════════════════════════════════════════════════════
# WSL2 DETECTION
# ═══════════════════════════════════════════════════════════════════════════════
IS_WSL=false
IS_WSL2=false
WSL_VERSION=""
WINDOWS_USER=""
WIN_HOME=""

if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    IS_WSL=true
    if [[ -d /run/WSL ]]; then
        IS_WSL2=true
        WSL_VERSION="2"
    else
        WSL_VERSION="1"
    fi
    # Get Windows username for interop
    WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || echo "")
    [[ -n "$WINDOWS_USER" ]] && WIN_HOME="/mnt/c/Users/$WINDOWS_USER"
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "24.04")
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "noble")

# CPU count
NCPU=$(nproc 2>/dev/null || echo 4)

# Shell RC file
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="$HOME/.zshrc"

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Create directories
mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

# Download with retry
dl() {
    local url="$1" out="$2"
    echo "[DL] $(date '+%H:%M:%S') $url" >> "$LOG"
    if curl -fsSL --connect-timeout 30 --max-time 600 --retry 3 -L -o "$out" "$url" 2>>"$LOG"; then
        if [[ -s "$out" ]]; then
            echo "[DL] Success: $(ls -lh "$out" 2>/dev/null | awk '{print $5}')" >> "$LOG"
            return 0
        fi
    fi
    echo "[DL] Failed or empty" >> "$LOG"
    rm -f "$out" 2>/dev/null
    return 1
}

# Status indicators
ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${Y}[✗]${RST} %s ${Y}(see log)${RST}\n" "$1"; }
skip() { printf "  ${C}[~]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

# Add to PATH (idempotent)
add_path() {
    local line="$1"
    grep -qxF "$line" "$SHELL_RC" 2>/dev/null || echo "$line" >> "$SHELL_RC"
}

# Safe cd
scd() {
    cd "$1" 2>/dev/null || cd /tmp
}

# ═══════════════════════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════════════════════
clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                              「  v2.0 - WSL2 Ubuntu Edition  」
                                        /\_____/\
                                       /  o   o  \
                                      ( ==  ^  == )
                                       )         (
                                      (           )
                                     ( (  )   (  ) )
                                    (__(__)___(__)__)

EOF

# ═══════════════════════════════════════════════════════════════════════════════
step "ENVIRONMENT DETECTION"
# ═══════════════════════════════════════════════════════════════════════════════

if $IS_WSL2; then
    ok "WSL2 detected (version $WSL_VERSION)"
    [[ -n "$WINDOWS_USER" ]] && info "Windows user: $WINDOWS_USER"
    [[ -n "$WIN_HOME" && -d "$WIN_HOME" ]] && info "Windows home: $WIN_HOME"
elif $IS_WSL; then
    warn "WSL1 detected — some features may not work"
    warn "Consider upgrading: wsl --set-version <distro> 2"
else
    fail "Not running in WSL!"
    info "This script is designed for WSL2 Ubuntu"
    info "For native Linux, use the standard Cat's Tweaker"
    exit 1
fi

info "Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME)"
info "CPUs: $NCPU"
info "Install dir: $INSTALL_DIR"
info "Log: $LOG"

# Check for WSLg (GUI support)
if [[ -d /mnt/wslg ]]; then
    ok "WSLg detected (GUI apps supported)"
    export DISPLAY="${DISPLAY:-:0}"
else
    warn "WSLg not detected — GUI apps may not work"
    info "Update WSL: wsl --update (from Windows)"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "SYSTEM PACKAGES (no systemd)"
# ═══════════════════════════════════════════════════════════════════════════════

info "Updating package lists..."
sudo apt-get update -qq >> "$LOG" 2>&1 && ok "APT update" || fail "APT update"

info "Installing build essentials..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    build-essential gcc g++ clang llvm lld \
    cmake ninja-build meson autoconf automake libtool pkg-config \
    flex bison texinfo gawk \
    >> "$LOG" 2>&1 && ok "Compilers & build tools" || fail "Build tools"

info "Installing development libraries..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev \
    libpng-dev libjpeg-dev libfreetype-dev zlib1g-dev \
    libncurses-dev libreadline-dev libgmp-dev libmpfr-dev libmpc-dev \
    libusb-1.0-0-dev libudev-dev \
    >> "$LOG" 2>&1 && ok "Development libraries" || fail "Dev libraries"

info "Installing utilities..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget git unzip p7zip-full xz-utils \
    nasm yasm \
    python3 python3-pip python3-venv python3-dev \
    nodejs npm \
    fuse libfuse2 \
    >> "$LOG" 2>&1 && ok "Utilities" || fail "Utilities"

# Ubuntu 24.04+ specific: Install pipx for user packages
if [[ "${UBUNTU_VERSION%%.*}" -ge 24 ]]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq pipx >> "$LOG" 2>&1
    pipx ensurepath >> "$LOG" 2>&1 || true
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "RETRO ASSEMBLERS (APT)"
# ═══════════════════════════════════════════════════════════════════════════════

# These are available in Ubuntu repos
info "Installing assemblers from APT..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    cc65 rgbds sdcc \
    >> "$LOG" 2>&1 && ok "cc65, rgbds, sdcc (APT)" || {
    # Fallback: some may not be in older repos
    sudo apt-get install -y -qq cc65 >> "$LOG" 2>&1 && ok "cc65" || skip "cc65 (not in repo)"
    sudo apt-get install -y -qq rgbds >> "$LOG" 2>&1 && ok "rgbds" || skip "rgbds (will download)"
    sudo apt-get install -y -qq sdcc >> "$LOG" 2>&1 && ok "sdcc" || skip "sdcc (not in repo)"
}

# ═══════════════════════════════════════════════════════════════════════════════
step "PYTHON PACKAGES"
# ═══════════════════════════════════════════════════════════════════════════════

info "Installing Python packages..."

# Ubuntu 24.04+ requires --break-system-packages or use pipx/venv
if [[ "${UBUNTU_VERSION%%.*}" -ge 24 ]]; then
    # Use --break-system-packages for system-wide install (user requested)
    pip3 install --user --break-system-packages \
        pygame pygame-ce pillow numpy pysdl2 pyyaml toml \
        intelhex pyserial capstone \
        >> "$LOG" 2>&1 && ok "Python packages (--break-system-packages)" || fail "Python packages"
else
    pip3 install --user \
        pygame pygame-ce pillow numpy pysdl2 pyyaml toml \
        intelhex pyserial capstone \
        >> "$LOG" 2>&1 && ok "Python packages" || fail "Python packages"
fi

# Ursina (3D engine) - may fail on some systems, non-critical
if [[ "${UBUNTU_VERSION%%.*}" -ge 24 ]]; then
    pip3 install --user --break-system-packages ursina >> "$LOG" 2>&1 && ok "Ursina 3D engine" || skip "Ursina (optional)"
else
    pip3 install --user ursina >> "$LOG" 2>&1 && ok "Ursina 3D engine" || skip "Ursina (optional)"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "N64 TOOLCHAIN (mips64-elf-gcc) — Native, No Docker"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$HOME"
rm -rf "$COMPILERS/n64" 2>/dev/null
mkdir -p "$COMPILERS/n64"
scd "$COMPILERS/n64"

# Download prebuilt toolchain (no Docker needed!)
TC_URL="https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz"

info "Downloading prebuilt N64 toolchain (~200MB)..."
if dl "$TC_URL" toolchain.tar.gz; then
    info "Extracting toolchain..."
    tar xzf toolchain.tar.gz >> "$LOG" 2>&1
    rm -f toolchain.tar.gz
    
    # Verify installation
    if [[ -x "$COMPILERS/n64/bin/mips64-elf-gcc" ]]; then
        N64_GCC_VER=$("$COMPILERS/n64/bin/mips64-elf-gcc" --version 2>/dev/null | head -1 || echo "unknown")
        ok "N64 toolchain: $N64_GCC_VER"
    else
        fail "N64 toolchain extraction"
    fi
else
    fail "N64 toolchain download"
    info "Manual: https://github.com/DragonMinded/libdragon/releases"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "LIBDRAGON N64 SDK"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf libdragon libdragon-trunk 2>/dev/null

info "Downloading libdragon SDK..."
if dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.tar.gz" libdragon.tar.gz; then
    tar xzf libdragon.tar.gz >> "$LOG" 2>&1
    mv libdragon-trunk libdragon 2>/dev/null || true
    rm -f libdragon.tar.gz
    
    # Build libdragon
    if [[ -d "$SDKS/libdragon" ]]; then
        info "Building libdragon (this takes a few minutes)..."
        scd "$SDKS/libdragon"
        
        # Set N64 environment for build
        export N64_INST="$COMPILERS/n64"
        export PATH="$N64_INST/bin:$PATH"
        
        if make -j"$NCPU" >> "$LOG" 2>&1; then
            if make install >> "$LOG" 2>&1; then
                ok "libdragon SDK built and installed"
            else
                ok "libdragon SDK built (install to N64_INST skipped)"
            fi
        else
            warn "libdragon build failed — SDK downloaded but not compiled"
            info "Build manually: cd ~/retro-dev/sdks/libdragon && make"
        fi
    fi
else
    fail "libdragon SDK download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "DEVKITPRO (GBA/DS/3DS/Wii/Switch)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$HOME"
mkdir -p "$COMPILERS/devkitpro"
scd "$COMPILERS/devkitpro"

info "Downloading devkitPro installer..."
if dl "https://apt.devkitpro.org/install-devkitpro-pacman" install-devkitpro-pacman; then
    chmod +x install-devkitpro-pacman
    ok "devkitPro installer downloaded"
    info "To install: sudo $COMPILERS/devkitpro/install-devkitpro-pacman"
    info "Then: sudo dkp-pacman -S gba-dev nds-dev 3ds-dev"
    
    # Offer to run installer
    echo ""
    read -r -p "  Install devkitPro now? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        info "Running devkitPro installer (needs sudo)..."
        if sudo ./install-devkitpro-pacman >> "$LOG" 2>&1; then
            ok "devkitPro pacman installed"
            info "Installing GBA/NDS devkits..."
            sudo dkp-pacman -Syu --noconfirm >> "$LOG" 2>&1 || true
            sudo dkp-pacman -S --noconfirm gba-dev nds-dev >> "$LOG" 2>&1 && \
                ok "GBA & NDS devkits installed" || warn "Some devkits failed"
        else
            fail "devkitPro installer"
        fi
    else
        skip "devkitPro installation (run manually later)"
    fi
else
    fail "devkitPro download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "GBDK-2020 (Game Boy C SDK)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf gbdk gbdk-linux64 2>/dev/null

info "Downloading GBDK-2020..."
if dl "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz" gbdk.tar.gz; then
    tar xzf gbdk.tar.gz >> "$LOG" 2>&1
    # Handle different archive structures
    [[ -d "gbdk" ]] || mv gbdk-linux64 gbdk 2>/dev/null || mv gbdk-* gbdk 2>/dev/null || true
    rm -f gbdk.tar.gz
    
    if [[ -x "$SDKS/gbdk/bin/lcc" ]]; then
        ok "GBDK-2020"
    else
        warn "GBDK extracted but lcc not found"
    fi
else
    fail "GBDK-2020 download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ADDITIONAL ASSEMBLERS"
# ═══════════════════════════════════════════════════════════════════════════════

# RGBDS (if not from APT or need newer version)
if ! command -v rgbasm >/dev/null 2>&1; then
    scd "$TOOLS"
    mkdir -p rgbds
    scd "$TOOLS/rgbds"
    
    info "Downloading RGBDS..."
    if dl "https://github.com/gbdev/rgbds/releases/download/v0.8.0/rgbds-0.8.0-linux-x86_64.tar.xz" rgbds.tar.xz; then
        tar xJf rgbds.tar.xz >> "$LOG" 2>&1
        rm -f rgbds.tar.xz
        chmod +x rgbasm rgblink rgbfix rgbgfx 2>/dev/null || true
        ok "RGBDS 0.8.0"
    else
        fail "RGBDS download"
    fi
else
    ok "RGBDS (system)"
fi

# ASM6F (NES assembler) - build from source
scd "$TOOLS"
mkdir -p asm6
scd "$TOOLS/asm6"

info "Building ASM6F..."
if dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c; then
    if cc -O3 -w asm6f.c -o asm6f 2>>"$LOG"; then
        chmod +x asm6f
        ok "ASM6F (NES assembler)"
    else
        fail "ASM6F compile"
    fi
else
    # Create stub
    cat > asm6f.c << 'STUBSRC'
#include <stdio.h>
int main(int c,char**v){printf("ASM6F stub - get real version from github.com/freem/asm6f\n");return 1;}
STUBSRC
    cc -O3 -w asm6f.c -o asm6f 2>/dev/null
    skip "ASM6F (stub only)"
fi

# WLA-DX (multi-platform assembler) - build from source
scd "$TOOLS"
rm -rf wla-dx wla-dx-* 2>/dev/null

info "Building WLA-DX..."
if dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz; then
    tar xzf wla.tar.gz >> "$LOG" 2>&1
    scd wla-dx-10.6
    mkdir -p build
    scd build
    
    if cmake .. -DCMAKE_BUILD_TYPE=Release >> "$LOG" 2>&1; then
        if make -j"$NCPU" >> "$LOG" 2>&1; then
            ok "WLA-DX 10.6"
        else
            fail "WLA-DX build"
        fi
    else
        fail "WLA-DX cmake"
    fi
    rm -f "$TOOLS/wla.tar.gz"
else
    fail "WLA-DX download"
fi

# DASM (Atari 2600)
scd "$SDKS"
mkdir -p atari
scd "$SDKS/atari"

info "Downloading DASM..."
if dl "https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz" dasm.tar.gz; then
    tar xzf dasm.tar.gz >> "$LOG" 2>&1
    rm -f dasm.tar.gz
    chmod +x dasm 2>/dev/null || true
    ok "DASM (Atari 2600)"
else
    fail "DASM download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "GENESIS/MEGA DRIVE SDK (SGDK)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf sgdk SGDK-* 2>/dev/null

info "Downloading SGDK..."
if dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz; then
    tar xzf sgdk.tar.gz >> "$LOG" 2>&1
    mv SGDK-2.00 sgdk 2>/dev/null || true
    rm -f sgdk.tar.gz
    ok "SGDK 2.00 (Sega Genesis)"
    info "Note: SGDK needs m68k-elf toolchain for full functionality"
else
    fail "SGDK download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "SNES SDK (PVSnesLib)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf pvsneslib pvsneslib-* 2>/dev/null

info "Downloading PVSnesLib..."
if dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip; then
    unzip -qo pvs.zip >> "$LOG" 2>&1
    mv pvsneslib-master pvsneslib 2>/dev/null || true
    rm -f pvs.zip
    ok "PVSnesLib (SNES)"
else
    fail "PVSnesLib download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ROM HACKING TOOLS"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$TOOLS"
rm -rf flips 2>/dev/null
mkdir -p flips
scd "$TOOLS/flips"

info "Downloading Flips (IPS/BPS patcher)..."
if dl "https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip" flips.zip; then
    unzip -qo flips.zip >> "$LOG" 2>&1
    chmod +x flips* 2>/dev/null || true
    rm -f flips.zip
    ok "Flips v198"
else
    # Build from source
    info "Building Flips from source..."
    scd "$TOOLS"
    if dl "https://github.com/Alcaro/Flips/archive/refs/heads/master.tar.gz" flips-src.tar.gz; then
        tar xzf flips-src.tar.gz >> "$LOG" 2>&1
        scd Flips-master
        if make CFLAGS="-O3" >> "$LOG" 2>&1; then
            mkdir -p "$TOOLS/flips"
            cp flips "$TOOLS/flips/"
            ok "Flips (built from source)"
        else
            fail "Flips build"
        fi
        rm -rf "$TOOLS/Flips-master" "$TOOLS/flips-src.tar.gz"
    else
        fail "Flips"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "EMULATORS (WSLg GUI)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$EMUS"

# mGBA - AppImage needs special handling in WSL2
info "Downloading mGBA..."
if dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-appimage-x64.appimage" mGBA.AppImage; then
    chmod +x mGBA.AppImage
    
    # Extract AppImage for better WSL2 compatibility
    info "Extracting mGBA AppImage for WSL2..."
    ./mGBA.AppImage --appimage-extract >> "$LOG" 2>&1 || true
    if [[ -d "squashfs-root" ]]; then
        mv squashfs-root mGBA-extracted 2>/dev/null || true
        # Create launcher script
        cat > mGBA << 'LAUNCHER'
#!/bin/bash
cd "$(dirname "$0")/mGBA-extracted" && ./AppRun "$@"
LAUNCHER
        chmod +x mGBA
        ok "mGBA 0.10.5 (extracted for WSL2)"
    else
        ok "mGBA 0.10.5 (AppImage)"
        info "Run with: ~/retro-dev/emulators/mGBA.AppImage --appimage-extract-and-run"
    fi
else
    fail "mGBA download"
fi

# Ares multi-system emulator
info "Downloading Ares..."
if dl "https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip" ares.zip; then
    unzip -qo ares.zip >> "$LOG" 2>&1
    chmod +x ares*/ares ares 2>/dev/null || true
    rm -f ares.zip
    ok "Ares v146 (multi-system)"
else
    fail "Ares download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "MODERN GAME DEV TOOLS"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$TOOLS"

# Raylib
info "Downloading Raylib..."
rm -rf raylib raylib-* 2>/dev/null
if dl "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz" raylib.tar.gz; then
    tar xzf raylib.tar.gz >> "$LOG" 2>&1
    mv raylib-5.5 raylib 2>/dev/null || true
    rm -f raylib.tar.gz
    
    # Build raylib
    scd "$TOOLS/raylib/src"
    if make PLATFORM=PLATFORM_DESKTOP -j"$NCPU" >> "$LOG" 2>&1; then
        ok "Raylib 5.5 (built)"
    else
        ok "Raylib 5.5 (source only)"
    fi
else
    fail "Raylib download"
fi

# Godot
scd "$TOOLS"
info "Downloading Godot..."
rm -f godot.zip Godot* 2>/dev/null
if dl "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip" godot.zip; then
    unzip -qo godot.zip >> "$LOG" 2>&1
    chmod +x Godot* 2>/dev/null || true
    rm -f godot.zip
    ok "Godot 4.3"
else
    fail "Godot download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ENVIRONMENT SETUP"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$HOME"

# Create comprehensive environment script
cat > "$INSTALL_DIR/env.sh" << 'ENVSCRIPT'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# CAT'S TWEAKER v2.0 — WSL2 Environment
# Source this: source ~/retro-dev/env.sh
# ═══════════════════════════════════════════════════════════════════════════════

export RETRO_DEV="$HOME/retro-dev"

# ─── N64 Development ───
export N64_INST="$RETRO_DEV/compilers/n64"
[[ -d "$N64_INST/bin" ]] && export PATH="$N64_INST/bin:$PATH"

# ─── DevkitPro (GBA/DS/3DS/Wii) ───
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"
[[ -d "$DEVKITARM/bin" ]] && export PATH="$DEVKITARM/bin:$PATH"

# ─── Game Boy (GBDK) ───
export GBDK="$RETRO_DEV/sdks/gbdk"
[[ -d "$GBDK/bin" ]] && export PATH="$GBDK/bin:$PATH"

# ─── Genesis (SGDK) ───
export SGDK="$RETRO_DEV/sdks/sgdk"

# ─── SNES (PVSnesLib) ───
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"

# ─── libdragon (N64 SDK) ───
export LIBDRAGON="$RETRO_DEV/sdks/libdragon"

# ─── Tools ───
export PATH="$RETRO_DEV/tools/asm6:$PATH"
export PATH="$RETRO_DEV/tools/flips:$PATH"
export PATH="$RETRO_DEV/tools/rgbds:$PATH"
export PATH="$RETRO_DEV/tools/wla-dx-10.6/build/binaries:$PATH"
export PATH="$RETRO_DEV/sdks/atari:$PATH"
export PATH="$RETRO_DEV/emulators:$PATH"
export PATH="$RETRO_DEV/tools:$PATH"

# ─── WSL2 Specific ───
# WSLg display (should be auto-set, but just in case)
[[ -z "$DISPLAY" ]] && export DISPLAY=:0

# Windows interop
if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    # Access to Windows PATH (optional, can slow things down)
    # export PATH="$PATH:/mnt/c/Windows/System32"
    :
fi

# ─── Python user packages ───
export PATH="$HOME/.local/bin:$PATH"

# ─── Greeting ───
echo ""
echo "  🐱 CAT'S TWEAKER v2.0 — WSL2 Environment Loaded! 🎮"
echo ""
echo "  Toolchains:"
[[ -x "$N64_INST/bin/mips64-elf-gcc" ]] && echo "    ✓ N64:  mips64-elf-gcc"
[[ -x "$DEVKITARM/bin/arm-none-eabi-gcc" ]] && echo "    ✓ GBA:  arm-none-eabi-gcc"
[[ -x "$GBDK/bin/lcc" ]] && echo "    ✓ GB:   lcc (GBDK)"
command -v rgbasm >/dev/null && echo "    ✓ GB:   rgbasm (RGBDS)"
command -v sdcc >/dev/null && echo "    ✓ Z80:  sdcc"
command -v cc65 >/dev/null && echo "    ✓ 6502: cc65"
echo ""
ENVSCRIPT

chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script: ~/retro-dev/env.sh"

# Add to shell RC
add_path ""
add_path "# Cat's Tweaker v2.0 — WSL2 Retro Dev"
add_path "[[ -f \"\$HOME/retro-dev/env.sh\" ]] && source \"\$HOME/retro-dev/env.sh\""

ok "Added to $SHELL_RC"

# ═══════════════════════════════════════════════════════════════════════════════
step "QUICK REFERENCE"
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$INSTALL_DIR/README.txt" << 'README'
═══════════════════════════════════════════════════════════════════════════════
                    CAT'S TWEAKER v2.0 — WSL2 Quick Reference
═══════════════════════════════════════════════════════════════════════════════

ACTIVATE ENVIRONMENT:
    source ~/retro-dev/env.sh

───────────────────────────────────────────────────────────────────────────────
NINTENDO 64
───────────────────────────────────────────────────────────────────────────────
    Compiler:   mips64-elf-gcc
    SDK:        ~/retro-dev/sdks/libdragon
    
    New project:
        mkdir myrom && cd myrom
        cp -r ~/retro-dev/sdks/libdragon/examples/helloworld/* .
        make
    
    Test ROM:
        # Use ares or Project64 on Windows

───────────────────────────────────────────────────────────────────────────────
GAME BOY / GAME BOY COLOR
───────────────────────────────────────────────────────────────────────────────
    GBDK:       lcc -o game.gb game.c
    RGBDS:      rgbasm -o main.o main.asm && rgblink -o game.gb main.o
    
    Test ROM:   ~/retro-dev/emulators/mGBA game.gb

───────────────────────────────────────────────────────────────────────────────
GAME BOY ADVANCE
───────────────────────────────────────────────────────────────────────────────
    Install:    sudo dkp-pacman -S gba-dev
    Compiler:   arm-none-eabi-gcc
    
    New project:
        cp -r /opt/devkitpro/examples/gba/template myproject
        cd myproject && make

───────────────────────────────────────────────────────────────────────────────
NES
───────────────────────────────────────────────────────────────────────────────
    cc65:       cl65 -t nes -o game.nes game.c
    ASM6F:      asm6f game.asm game.nes

───────────────────────────────────────────────────────────────────────────────
SEGA GENESIS / MEGA DRIVE
───────────────────────────────────────────────────────────────────────────────
    SDK:        ~/retro-dev/sdks/sgdk
    Note:       Requires m68k-elf-gcc toolchain

───────────────────────────────────────────────────────────────────────────────
ROM PATCHING
───────────────────────────────────────────────────────────────────────────────
    Apply IPS:  flips --apply patch.ips original.rom patched.rom
    Apply BPS:  flips --apply patch.bps original.rom patched.rom
    Create:     flips --create original.rom modified.rom patch.bps

───────────────────────────────────────────────────────────────────────────────
EMULATORS
───────────────────────────────────────────────────────────────────────────────
    mGBA:       ~/retro-dev/emulators/mGBA rom.gba
    Ares:       ~/retro-dev/emulators/ares-*/ares

───────────────────────────────────────────────────────────────────────────────
WSL2 TIPS
───────────────────────────────────────────────────────────────────────────────
    - GUI apps work via WSLg (automatic)
    - Access Windows files: /mnt/c/Users/YourName/
    - Copy to Windows: cp rom.gb /mnt/c/Users/YourName/Desktop/
    - Run Windows exe: /mnt/c/path/to/program.exe

═══════════════════════════════════════════════════════════════════════════════
README

ok "Quick reference: ~/retro-dev/README.txt"

# ═══════════════════════════════════════════════════════════════════════════════
# COMPLETE
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v2.0 — WSL2 INSTALLATION COMPLETE! ✨${RST}             ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}                                                                       ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Install dir:${RST}  ~/retro-dev                                          ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Activate:${RST}     source ~/retro-dev/env.sh                           ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Reference:${RST}    ~/retro-dev/README.txt                              ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Log:${RST}          ~/retro-dev/install.log                             ${G}║${RST}\n"
printf "${G}  ║${RST}                                                                       ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${Y}Next steps:${RST}                                                        ${G}║${RST}\n"
printf "${G}  ║${RST}    1. Restart terminal or: source ~/.bashrc                           ${G}║${RST}\n"
printf "${G}  ║${RST}    2. Test N64: mips64-elf-gcc --version                              ${G}║${RST}\n"
printf "${G}  ║${RST}    3. Test GB:  lcc --version                                         ${G}║${RST}\n"
printf "${G}  ║${RST}                                                                       ${G}║${RST}\n"
printf "${G}  ╚═══════════════════════════════════════════════════════════════════════╝${RST}\n"
echo ""
printf "                              ${M}/\\_____/\\${RST}\n"
printf "                             ${M}/  o   o  \\${RST}\n"
printf "                            ${M}( ==  ^  == )${RST}\n"
printf "                             ${M})  ~nya~  (${RST}\n"
printf "                            ${M}(           )${RST}\n"
printf "                           ${M}( (  )   (  ) )${RST}\n"
printf "                          ${M}(__(__)___(__)__)${RST}\n"
echo ""
printf "                    ${C}Team Flames / Samsoft 🐱${RST}\n"
echo ""
