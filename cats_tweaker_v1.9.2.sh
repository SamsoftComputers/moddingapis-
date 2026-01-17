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
#                                      「  v1.9.2 - retro dev toolkit  」
#                                         by Flames / Team Flames 🐱
#                              Apple Silicon M4 Pro + Rosetta 2 Optimized
#
#===============================================================================

# CRITICAL: Force native ARM execution on Apple Silicon
# This fixes the Rosetta/brew mismatch issue
if [[ "$(uname)" == "Darwin" && "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"Apple"* ]]; then
    if [[ "$(uname -m)" == "x86_64" ]]; then
        echo "⚠️  Detected: Running under Rosetta but you have Apple Silicon"
        echo "   Re-launching script natively for ARM brew compatibility..."
        echo ""
        exec arch -arm64 /bin/bash "$0" "$@"
    fi
fi

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

# Colors
G=$'\033[0;32m'
Y=$'\033[0;33m'
C=$'\033[0;36m'
M=$'\033[0;35m'
R=$'\033[0;31m'
W=$'\033[1;37m'
RST=$'\033[0m'

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

# Find brew dynamically
BREW=""
BREW_PREFIX=""
if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW="/opt/homebrew/bin/brew"
    BREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]]; then
    BREW="/usr/local/bin/brew"
    BREW_PREFIX="/usr/local"
fi

# Directories
INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

NCPU=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
SHELL_RC="$HOME/.zshrc"
[[ "$(uname)" != "Darwin" ]] && SHELL_RC="$HOME/.bashrc"

IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
HAS_DOCKER=false

# Download helper
dl() {
    local url="$1" out="$2"
    echo "[DL] $url" >> "$LOG"
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 -L -o "$out" "$url" 2>>"$LOG"
    [[ -s "$out" ]]
}

add_path() {
    local line="$1"
    [[ -z "$line" ]] && return
    grep -qxF "$line" "$SHELL_RC" 2>/dev/null || echo "$line" >> "$SHELL_RC"
}

# Brew install with visible output on failure
brew_pkg() {
    local pkg="$1"
    if "$BREW" list "$pkg" &>/dev/null; then
        ok "$pkg (already installed)"
        return 0
    fi
    
    printf "  ${C}[*]${RST} Installing %s..." "$pkg"
    
    local output
    output=$("$BREW" install "$pkg" 2>&1)
    local ret=$?
    
    if [[ $ret -eq 0 ]]; then
        printf "\r  ${G}[✓]${RST} %s                    \n" "$pkg"
        return 0
    else
        printf "\r  ${R}[✗]${RST} %s                    \n" "$pkg"
        echo "    └─ Error: $(echo "$output" | grep -i "error\|fail\|cannot" | head -1)"
        echo "$output" >> "$LOG"
        return 1
    fi
}

# ============================================================================
# BANNER
# ============================================================================

clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                                      「  v1.9.2 - retro dev toolkit  」
                                    Apple Silicon M4 Pro + Rosetta 2 Ready
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )         (
                                          (           )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF

# ============================================================================
step "SYSTEM DETECTION"
# ============================================================================

if $IS_MAC; then
    ok "macOS detected"
    ok "Architecture: $(uname -m)"
    
    CPU_BRAND="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
    if [[ "$CPU_BRAND" == *"Apple"* ]]; then
        ok "CPU: $CPU_BRAND"
    fi
fi

# ============================================================================
step "XCODE COMMAND LINE TOOLS"
# ============================================================================

if $IS_MAC; then
    if xcode-select -p &>/dev/null; then
        ok "Xcode CLI tools installed"
    else
        info "Installing Xcode Command Line Tools (required for brew)..."
        xcode-select --install 2>/dev/null
        echo ""
        echo "  ⚠️  A dialog should appear. Click 'Install' and wait for it to complete."
        echo "     Then re-run this script."
        echo ""
        read -p "  Press Enter after installation completes (or Ctrl+C to exit)..."
    fi
fi

# ============================================================================
step "HOMEBREW SETUP"
# ============================================================================

if $IS_MAC; then
    if [[ -n "$BREW" ]]; then
        ok "Homebrew: $BREW"
        
        # Source brew environment
        eval "$("$BREW" shellenv)"
        export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Re-detect
        if [[ -x /opt/homebrew/bin/brew ]]; then
            BREW="/opt/homebrew/bin/brew"
            BREW_PREFIX="/opt/homebrew"
        elif [[ -x /usr/local/bin/brew ]]; then
            BREW="/usr/local/bin/brew"
            BREW_PREFIX="/usr/local"
        fi
        
        if [[ -n "$BREW" ]]; then
            eval "$("$BREW" shellenv)"
            ok "Homebrew installed"
        else
            fail "Homebrew installation failed"
            exit 1
        fi
    fi
    
    # Add to shell RC
    add_path "# Homebrew"
    add_path 'eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null'
    
    # Update brew
    info "Updating Homebrew..."
    "$BREW" update >> "$LOG" 2>&1 || warn "Brew update had issues"
fi

# ============================================================================
step "CORE BUILD TOOLS (via Homebrew)"
# ============================================================================

if $IS_MAC; then
    info "Installing packages one-by-one (shows errors if any fail)..."
    echo ""
    
    # Core compilers
    brew_pkg gcc
    brew_pkg llvm
    brew_pkg cmake
    brew_pkg ninja
    brew_pkg meson
    brew_pkg autoconf
    brew_pkg automake
    brew_pkg libtool
    brew_pkg pkg-config
    
    echo ""
    # Libraries
    brew_pkg sdl2
    brew_pkg sdl2_image
    brew_pkg sdl2_mixer
    brew_pkg sdl2_ttf
    brew_pkg libpng
    brew_pkg jpeg
    brew_pkg freetype
    brew_pkg zlib
    brew_pkg glew
    brew_pkg glfw
    
    echo ""
    # Assemblers - THE IMPORTANT ONES
    brew_pkg nasm
    brew_pkg yasm
    
    echo ""
    # Retro dev tools
    brew_pkg rgbds
    brew_pkg cc65
    brew_pkg sdcc
    brew_pkg wla-dx
    
    echo ""
    # Utilities
    brew_pkg wget
    brew_pkg curl
    brew_pkg p7zip
    brew_pkg python
    brew_pkg node
    brew_pkg raylib
    
    # Refresh PATH
    eval "$("$BREW" shellenv)"
    export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
    hash -r 2>/dev/null || true
fi

# ============================================================================
step "PYTHON PACKAGES"
# ============================================================================

PIP="$BREW_PREFIX/bin/pip3"
[[ ! -x "$PIP" ]] && PIP="pip3"

info "Installing Python packages..."
$PIP install --user --break-system-packages \
    pygame pillow numpy pysdl2 pyyaml toml intelhex pyserial capstone \
    >> "$LOG" 2>&1 && ok "Python packages" || warn "Some Python packages failed (non-critical)"

# ============================================================================
step "DOCKER CHECK"
# ============================================================================

if command -v docker &>/dev/null; then
    HAS_DOCKER=true
    ok "Docker installed"
    if docker info &>/dev/null; then
        ok "Docker daemon running"
    else
        warn "Docker not running - start Docker Desktop for N64 dev"
    fi
else
    warn "Docker not found - needed for N64 dev on macOS"
    info "Install: https://docker.com/products/docker-desktop"
fi

# ============================================================================
step "N64 DEVELOPMENT (libdragon)"
# ============================================================================

mkdir -p "$COMPILERS/n64"
cd "$COMPILERS/n64"

if $IS_MAC; then
    info "N64 on macOS: Docker + libdragon CLI"
    
    if command -v npm &>/dev/null; then
        info "Installing libdragon CLI..."
        npm install -g libdragon >> "$LOG" 2>&1 && ok "libdragon CLI" || warn "libdragon CLI failed"
        
        if $HAS_DOCKER && command -v libdragon &>/dev/null; then
            info "Pulling Docker image..."
            docker pull ghcr.io/dragonminded/libdragon:latest >> "$LOG" 2>&1 && ok "libdragon Docker image" || warn "Docker pull failed"
        fi
    else
        warn "Node.js not installed - libdragon CLI needs npm"
        info "Try: $BREW install node"
    fi
fi

# ============================================================================
step "DEVKITPRO (GBA/NDS/3DS/Switch)"
# ============================================================================

mkdir -p "$COMPILERS/devkitpro"
cd "$COMPILERS/devkitpro"

if $IS_MAC; then
    if dl "https://github.com/devkitPro/pacman/releases/latest/download/devkitpro-pacman-installer.pkg" devkitpro.pkg; then
        ok "DevkitPro installer downloaded"
        info "Run: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"
    else
        fail "DevkitPro download"
    fi
fi

# ============================================================================
step "GBDK-2020 (Game Boy)"
# ============================================================================

cd "$SDKS"
rm -rf gbdk gbdk.tar.gz 2>/dev/null

GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz"
$IS_MAC || GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"

if dl "$GB_URL" gbdk.tar.gz; then
    tar xzf gbdk.tar.gz >> "$LOG" 2>&1
    rm -f gbdk.tar.gz
    ok "GBDK-2020 4.3.0"
else
    fail "GBDK-2020"
fi

# ============================================================================
step "ASSEMBLERS (6502/Z80/68K)"
# ============================================================================

# ASM6F
mkdir -p "$TOOLS/asm6"
cd "$TOOLS/asm6"
info "Building ASM6F..."
if dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c; then
    cc -O3 -o asm6f asm6f.c >> "$LOG" 2>&1 && chmod +x asm6f && ok "ASM6F" || warn "ASM6F build failed"
else
    warn "ASM6F download failed"
fi

# DASM
mkdir -p "$SDKS/atari"
cd "$SDKS/atari"
DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz"
$IS_MAC || DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"

if dl "$DASM_URL" dasm.tar.gz; then
    tar xzf dasm.tar.gz >> "$LOG" 2>&1
    rm -f dasm.tar.gz
    chmod +x dasm* 2>/dev/null
    ok "DASM"
else
    fail "DASM"
fi

# VASM
mkdir -p "$TOOLS/vasm"
cd "$TOOLS/vasm"
info "Building VASM..."

VASM_OK=false
for url in "http://phoenix.owl.de/tags/vasm1_9i.tar.gz" "http://sun.hasenbraten.de/vasm/release/vasm.tar.gz"; do
    if dl "$url" vasm.tar.gz; then
        tar xzf vasm.tar.gz >> "$LOG" 2>&1
        rm -f vasm.tar.gz
        VASM_DIR=$(find . -maxdepth 1 -type d -name "vasm*" | head -1)
        if [[ -n "$VASM_DIR" ]]; then
            cd "$VASM_DIR"
            make CPU=6502 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasm6502_oldstyle "$TOOLS/vasm/" 2>/dev/null
            make clean >> "$LOG" 2>&1
            make CPU=m68k SYNTAX=mot -j$NCPU >> "$LOG" 2>&1 && cp vasmm68k_mot "$TOOLS/vasm/" 2>/dev/null
            VASM_OK=true
            cd "$TOOLS/vasm"
            rm -rf "$VASM_DIR"
        fi
        break
    fi
done

$VASM_OK && [[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM (6502, 68K)" || warn "VASM build failed"

# ============================================================================
step "GENESIS SDK (SGDK)"
# ============================================================================

cd "$SDKS"
rm -rf sgdk SGDK-* sgdk.tar.gz 2>/dev/null
if dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz; then
    tar xzf sgdk.tar.gz >> "$LOG" 2>&1
    mv SGDK-2.00 sgdk 2>/dev/null
    rm -f sgdk.tar.gz
    ok "SGDK 2.00"
else
    fail "SGDK"
fi

# ============================================================================
step "SNES SDK (PVSnesLib)"
# ============================================================================

cd "$SDKS"
rm -rf pvsneslib pvsneslib-* pvs.zip 2>/dev/null
if dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip; then
    unzip -qo pvs.zip >> "$LOG" 2>&1
    mv pvsneslib-master pvsneslib 2>/dev/null
    rm -f pvs.zip
    ok "PVSnesLib"
else
    fail "PVSnesLib"
fi

# ============================================================================
step "ROM HACKING TOOLS"
# ============================================================================

mkdir -p "$TOOLS/flips"
cd "$TOOLS/flips"

FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-mac.zip"
$IS_MAC || FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"

if dl "$FLIPS_URL" flips.zip; then
    unzip -qo flips.zip >> "$LOG" 2>&1
    rm -f flips.zip
    chmod +x * 2>/dev/null
    $IS_MAC && xattr -dr com.apple.quarantine . 2>/dev/null
    ok "Flips v198"
else
    info "Building Flips..."
    cd "$TOOLS"
    if dl "https://github.com/Alcaro/Flips/archive/refs/heads/master.tar.gz" flips-src.tar.gz; then
        tar xzf flips-src.tar.gz >> "$LOG" 2>&1
        cd Flips-master
        make CFLAGS="-O3" >> "$LOG" 2>&1 && cp flips "$TOOLS/flips/" && ok "Flips (built)" || fail "Flips"
        cd "$TOOLS"
        rm -rf Flips-master flips-src.tar.gz
    else
        fail "Flips"
    fi
fi

# ============================================================================
step "EMULATORS"
# ============================================================================

mkdir -p "$EMUS"
cd "$EMUS"

# mGBA
if $IS_MAC; then
    if dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-macos.dmg" mgba.dmg; then
        hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1
        cp -R /Volumes/mGBA*/mGBA.app . 2>/dev/null
        hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1
        xattr -dr com.apple.quarantine mGBA.app 2>/dev/null
        rm -f mgba.dmg
        ok "mGBA 0.10.5"
    else
        fail "mGBA"
    fi
fi

# Ares
ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-macos-universal.zip"
$IS_MAC || ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"

if dl "$ARES_URL" ares.zip; then
    unzip -qo ares.zip >> "$LOG" 2>&1
    rm -f ares.zip
    $IS_MAC && xattr -dr com.apple.quarantine Ares* ares* 2>/dev/null
    ok "Ares v146"
else
    fail "Ares"
fi

# ============================================================================
step "MODERN ENGINES"
# ============================================================================

cd "$TOOLS"

GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip"
$IS_MAC || GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"

if dl "$GODOT_URL" godot.zip; then
    unzip -qo godot.zip >> "$LOG" 2>&1
    rm -f godot.zip
    $IS_MAC && xattr -dr com.apple.quarantine Godot* 2>/dev/null
    ok "Godot 4.3"
else
    fail "Godot"
fi

$IS_MAC && ok "Raylib (via brew)"

# ============================================================================
step "ENVIRONMENT SCRIPT"
# ============================================================================

cat > "$INSTALL_DIR/env.sh" << 'ENVEOF'
#!/bin/bash
# Cat's Tweaker v1.9.2 Environment

export RETRO_DEV="$HOME/retro-dev"

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# DevkitPro
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"

# SDKs
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"

# N64 (Linux)
[[ -d "$RETRO_DEV/compilers/n64/bin" ]] && export N64_INST="$RETRO_DEV/compilers/n64" && export PATH="$N64_INST/bin:$PATH"

# Tools
export PATH="$DEVKITARM/bin:$GBDK/bin:$PATH"
export PATH="$RETRO_DEV/tools/asm6:$PATH"
export PATH="$RETRO_DEV/tools/vasm:$PATH"
export PATH="$RETRO_DEV/tools/flips:$PATH"
export PATH="$RETRO_DEV/sdks/atari:$PATH"

echo "  🐱 CAT'S TWEAKER v1.9.2 loaded! 🎮"
ENVEOF

chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script"

add_path ""
add_path "# Cat's Tweaker v1.9.2"
add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
step "FINAL VERIFICATION"
# ============================================================================

source "$INSTALL_DIR/env.sh" 2>/dev/null || true
[[ -n "$BREW" ]] && eval "$("$BREW" shellenv)"

echo ""
command -v nasm &>/dev/null && ok "nasm: $(nasm -v 2>&1 | head -1)" || fail "nasm not installed"
command -v yasm &>/dev/null && ok "yasm: $(yasm --version 2>&1 | head -1)" || fail "yasm not installed"
command -v cc65 &>/dev/null && ok "cc65: installed" || fail "cc65 not installed"
command -v sdcc &>/dev/null && ok "sdcc: installed" || fail "sdcc not installed"
command -v rgbasm &>/dev/null && ok "rgbasm: installed" || fail "rgbasm not installed"
[[ -x "$SDKS/gbdk/bin/lcc" ]] && ok "GBDK lcc: installed" || warn "GBDK lcc not found"
command -v node &>/dev/null && ok "node: $(node -v)" || fail "node not installed"
command -v npm &>/dev/null && ok "npm: $(npm -v)" || fail "npm not installed"
command -v libdragon &>/dev/null && ok "libdragon: installed" || warn "libdragon: run 'npm install -g libdragon'"

# ============================================================================
# COMPLETE
# ============================================================================

echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v1.9.2 INSTALLATION COMPLETE! ✨${RST}                ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${C}Architecture:${RST} $(uname -m)                                          ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Homebrew:${RST}     $BREW_PREFIX                                  ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Installed to:${RST} ~/retro-dev                                    ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Log:${RST}          ~/retro-dev/install.log                        ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${Y}ACTIVATE:${RST}     ${W}source ~/.zshrc${RST}                                 ${G}║${RST}\n"
printf "${G}  ╚═══════════════════════════════════════════════════════════════════╝${RST}\n"
echo ""
printf "                             ${M}/\\_____/\\${RST}\n"
printf "                            ${M}/  o   o  \\${RST}\n"
printf "                           ${M}( ==  ^  == )${RST}\n"
printf "                            ${M})  ~nya~  (${RST}\n"
printf "                           ${M}(           )${RST}\n"
printf "                          ${M}( (  )   (  ) )${RST}\n"
printf "                         ${M}(__(__)___(__)__)${RST}\n"
echo ""
info "POST-INSTALL:"
echo "  1. ${W}source ~/.zshrc${RST}"
echo "  2. DevkitPro: sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /"
echo "  3. N64: Install Docker Desktop, then: mkdir proj && cd proj && libdragon init"
echo ""
