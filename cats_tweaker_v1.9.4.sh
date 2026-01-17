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
#                                      「  v1.9.4 - retro dev toolkit  」
#                                         by Flames / Team Flames 🐱
#                                  Auto: Docker, wget, curl, libdragon
#                                            ⛔ NO GIT REQUIRED ⛔
#
#===============================================================================

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

G=$'\033[0;32m'; Y=$'\033[0;33m'; C=$'\033[0;36m'; M=$'\033[0;35m'; R=$'\033[0;31m'; W=$'\033[1;37m'; RST=$'\033[0m'

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

BREW=""; BREW_PREFIX=""
[[ -x /opt/homebrew/bin/brew ]] && BREW="/opt/homebrew/bin/brew" && BREW_PREFIX="/opt/homebrew"
[[ -z "$BREW" && -x /usr/local/bin/brew ]] && BREW="/usr/local/bin/brew" && BREW_PREFIX="/usr/local"

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

NCPU=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
SHELL_RC="$HOME/.zshrc"; [[ "$(uname)" != "Darwin" ]] && SHELL_RC="$HOME/.bashrc"
IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
IS_APPLE_SILICON=false; [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"Apple"* ]] && IS_APPLE_SILICON=true
HAS_DOCKER=false

dl() {
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 -L -o "$2" "$1" 2>>"$LOG"
    [[ -s "$2" ]]
}

add_path() { [[ -n "$1" ]] && grep -qxF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

brew_pkg() {
    local pkg="$1"
    "$BREW" list "$pkg" &>/dev/null && { ok "$pkg (installed)"; return 0; }
    printf "  ${C}[*]${RST} Installing %s..." "$pkg"
    local out; out=$("$BREW" install "$pkg" 2>&1); local ret=$?
    echo "$out" | grep -q "brew link" && "$BREW" link --overwrite "$pkg" >> "$LOG" 2>&1 && ret=0
    if [[ $ret -eq 0 ]] || "$BREW" list "$pkg" &>/dev/null; then
        printf "\r  ${G}[✓]${RST} %-20s\n" "$pkg"; return 0
    else
        printf "\r  ${R}[✗]${RST} %-20s\n" "$pkg"
        echo "$out" >> "$LOG"; return 1
    fi
}

# ============================================================================
clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                                      「  v1.9.4 - retro dev toolkit  」
                                    ⛔ NO GIT REQUIRED - Full Auto Install ⛔
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )         (
                                          (           )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF

# ============================================================================
step "SYSTEM"
# ============================================================================
$IS_MAC && ok "macOS $(uname -m)"
$IS_APPLE_SILICON && ok "Apple Silicon"

# ============================================================================
step "XCODE CLI"
# ============================================================================
if $IS_MAC; then
    xcode-select -p &>/dev/null && ok "Xcode CLI tools" || { xcode-select --install; warn "Install Xcode CLI, then re-run"; exit 1; }
fi

# ============================================================================
step "HOMEBREW"
# ============================================================================
if $IS_MAC; then
    if [[ -n "$BREW" ]]; then
        ok "Homebrew: $BREW"
        eval "$("$BREW" shellenv)"; export PATH="$BREW_PREFIX/bin:$PATH"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ -x /opt/homebrew/bin/brew ]] && BREW="/opt/homebrew/bin/brew" && BREW_PREFIX="/opt/homebrew"
        [[ -z "$BREW" && -x /usr/local/bin/brew ]] && BREW="/usr/local/bin/brew" && BREW_PREFIX="/usr/local"
        [[ -n "$BREW" ]] && eval "$("$BREW" shellenv)" && ok "Homebrew" || { fail "Homebrew"; exit 1; }
    fi
    [[ "$BREW_PREFIX" == "/usr/local" ]] && sed -i.bak 's|eval "\$(/opt/homebrew|# &|g' "$HOME/.zprofile" "$HOME/.zshrc" 2>/dev/null
    add_path "# Homebrew"
    [[ "$BREW_PREFIX" == "/opt/homebrew" ]] && add_path 'eval "$(/opt/homebrew/bin/brew shellenv)"' || add_path 'eval "$(/usr/local/bin/brew shellenv)"'
    "$BREW" update >> "$LOG" 2>&1
fi

# ============================================================================
step "WGET + CURL (auto-install)"
# ============================================================================
if $IS_MAC; then
    brew_pkg curl
    brew_pkg wget
    eval "$("$BREW" shellenv)"; export PATH="$BREW_PREFIX/bin:$PATH"
    command -v wget &>/dev/null && ok "wget ready" || warn "wget not in path yet"
    command -v curl &>/dev/null && ok "curl ready" || warn "curl not in path yet"
fi

# ============================================================================
step "DOCKER DESKTOP (auto-download + install)"
# ============================================================================
if command -v docker &>/dev/null; then
    HAS_DOCKER=true
    ok "Docker installed"
    docker info &>/dev/null && ok "Docker running" || warn "Start Docker Desktop"
else
    info "Downloading Docker Desktop..."
    mkdir -p "$TOOLS/docker"; cd "$TOOLS/docker"
    
    $IS_APPLE_SILICON && DOCKER_URL="https://desktop.docker.com/mac/main/arm64/Docker.dmg" || \
                         DOCKER_URL="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
    
    if dl "$DOCKER_URL" Docker.dmg; then
        ok "Docker downloaded"
        info "Mounting and installing..."
        hdiutil attach Docker.dmg -nobrowse >> "$LOG" 2>&1
        
        if [[ -d "/Volumes/Docker/Docker.app" ]]; then
            cp -R "/Volumes/Docker/Docker.app" /Applications/ 2>> "$LOG"
            hdiutil detach /Volumes/Docker >> "$LOG" 2>&1
            rm -f Docker.dmg
            ok "Docker installed to /Applications"
            
            info "Starting Docker Desktop..."
            open -a Docker
            
            info "Waiting for Docker to start (up to 90 sec)..."
            for i in {1..45}; do
                if docker info &>/dev/null 2>&1; then
                    HAS_DOCKER=true
                    ok "Docker is running!"
                    break
                fi
                sleep 2; printf "."
            done
            echo ""
            $HAS_DOCKER || warn "Docker still starting - continue, may need to re-run for N64"
        else
            hdiutil detach /Volumes/Docker 2>/dev/null
            fail "Docker mount failed"
        fi
    else
        fail "Docker download"
    fi
fi

# ============================================================================
step "BUILD TOOLS"
# ============================================================================
if $IS_MAC; then
    echo ""
    brew_pkg gcc; brew_pkg llvm; brew_pkg cmake; brew_pkg ninja; brew_pkg meson
    brew_pkg autoconf; brew_pkg automake; brew_pkg libtool; brew_pkg pkg-config
    echo ""
    brew_pkg sdl2; brew_pkg sdl2_image; brew_pkg sdl2_mixer; brew_pkg sdl2_ttf
    brew_pkg libpng; brew_pkg jpeg; brew_pkg freetype; brew_pkg zlib; brew_pkg glew; brew_pkg glfw
    echo ""
    brew_pkg nasm; brew_pkg yasm
    echo ""
    brew_pkg rgbds; brew_pkg cc65; brew_pkg sdcc; brew_pkg wla-dx
    echo ""
    brew_pkg p7zip; brew_pkg python; brew_pkg node; brew_pkg raylib
    eval "$("$BREW" shellenv)"; hash -r 2>/dev/null
fi

# ============================================================================
step "PYTHON PACKAGES"
# ============================================================================
PIP="$BREW_PREFIX/bin/pip3"; [[ ! -x "$PIP" ]] && PIP="pip3"
$PIP install --user --break-system-packages pygame pillow numpy pysdl2 pyyaml toml intelhex pyserial capstone >> "$LOG" 2>&1 && ok "Python packages" || warn "Some failed"

# ============================================================================
step "N64 / LIBDRAGON (auto-install, no git)"
# ============================================================================
mkdir -p "$COMPILERS/n64"; cd "$COMPILERS/n64"

if $IS_MAC; then
    if command -v npm &>/dev/null; then
        info "Installing libdragon CLI (via npm, no git)..."
        npm install -g libdragon >> "$LOG" 2>&1
        
        if command -v libdragon &>/dev/null; then
            ok "libdragon CLI"
            
            if $HAS_DOCKER && docker info &>/dev/null; then
                info "Pulling libdragon Docker image..."
                docker pull ghcr.io/dragonminded/libdragon:latest >> "$LOG" 2>&1 && ok "libdragon Docker image" || warn "Docker pull failed"
                ok "N64 dev ready!"
                info "Usage: mkdir proj && cd proj && libdragon init && libdragon make"
            else
                warn "Docker not running - start Docker Desktop then run:"
                info "  docker pull ghcr.io/dragonminded/libdragon:latest"
            fi
        else
            fail "libdragon CLI"
        fi
    else
        fail "npm not found - node install failed?"
    fi
else
    # Linux: prebuilt toolchain
    dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz" tc.tar.gz && \
        tar xzf tc.tar.gz >> "$LOG" 2>&1 && rm -f tc.tar.gz && ok "N64 toolchain" || fail "N64 toolchain"
fi

# ============================================================================
step "DEVKITPRO"
# ============================================================================
mkdir -p "$COMPILERS/devkitpro"; cd "$COMPILERS/devkitpro"
dl "https://github.com/devkitPro/pacman/releases/latest/download/devkitpro-pacman-installer.pkg" devkitpro.pkg && ok "DevkitPro installer" || fail "DevkitPro"
info "Run: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"

# ============================================================================
step "GBDK-2020"
# ============================================================================
cd "$SDKS"; rm -rf gbdk* 2>/dev/null
$IS_MAC && U="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz" || U="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"
dl "$U" gbdk.tar.gz && tar xzf gbdk.tar.gz >> "$LOG" 2>&1 && rm -f gbdk.tar.gz && ok "GBDK-2020" || fail "GBDK-2020"

# ============================================================================
step "ASSEMBLERS (no git)"
# ============================================================================
mkdir -p "$TOOLS/asm6"; cd "$TOOLS/asm6"
dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c && cc -O3 -o asm6f asm6f.c >> "$LOG" 2>&1 && ok "ASM6F" || warn "ASM6F"

mkdir -p "$SDKS/atari"; cd "$SDKS/atari"
$IS_MAC && U="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz" || U="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"
dl "$U" dasm.tar.gz && tar xzf dasm.tar.gz >> "$LOG" 2>&1 && rm -f dasm.tar.gz && chmod +x dasm* 2>/dev/null && ok "DASM" || fail "DASM"

mkdir -p "$TOOLS/vasm"; cd "$TOOLS/vasm"
for u in "http://phoenix.owl.de/tags/vasm1_9i.tar.gz" "http://sun.hasenbraten.de/vasm/release/vasm.tar.gz"; do
    if dl "$u" vasm.tar.gz; then
        tar xzf vasm.tar.gz >> "$LOG" 2>&1; rm -f vasm.tar.gz
        D=$(find . -maxdepth 1 -type d -name "vasm*" | head -1)
        [[ -n "$D" ]] && cd "$D" && make CPU=6502 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasm6502_oldstyle "$TOOLS/vasm/" 2>/dev/null
        make clean >> "$LOG" 2>&1; make CPU=m68k SYNTAX=mot -j$NCPU >> "$LOG" 2>&1 && cp vasmm68k_mot "$TOOLS/vasm/" 2>/dev/null
        cd "$TOOLS/vasm"; rm -rf "$D"; break
    fi
done
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM" || warn "VASM"

# ============================================================================
step "GENESIS SDK"
# ============================================================================
cd "$SDKS"; rm -rf sgdk* SGDK* 2>/dev/null
dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz && tar xzf sgdk.tar.gz >> "$LOG" 2>&1 && mv SGDK-2.00 sgdk && rm -f sgdk.tar.gz && ok "SGDK" || fail "SGDK"

# ============================================================================
step "SNES SDK"
# ============================================================================
cd "$SDKS"; rm -rf pvsneslib* 2>/dev/null
dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip && unzip -qo pvs.zip >> "$LOG" 2>&1 && mv pvsneslib-master pvsneslib && rm -f pvs.zip && ok "PVSnesLib" || fail "PVSnesLib"

# ============================================================================
step "ROM TOOLS"
# ============================================================================
mkdir -p "$TOOLS/flips"; cd "$TOOLS/flips"
$IS_MAC && U="https://github.com/Alcaro/Flips/releases/download/v198/flips-mac.zip" || U="https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"
dl "$U" flips.zip && unzip -qo flips.zip >> "$LOG" 2>&1 && rm -f flips.zip && chmod +x * 2>/dev/null && $IS_MAC && xattr -dr com.apple.quarantine . 2>/dev/null && ok "Flips" || warn "Flips"

# ============================================================================
step "EMULATORS"
# ============================================================================
mkdir -p "$EMUS"; cd "$EMUS"
if $IS_MAC; then
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-macos.dmg" mgba.dmg && hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1 && cp -R /Volumes/mGBA*/mGBA.app . && hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1 && xattr -dr com.apple.quarantine mGBA.app 2>/dev/null && rm -f mgba.dmg && ok "mGBA" || fail "mGBA"
fi
$IS_MAC && U="https://github.com/ares-emulator/ares/releases/download/v146/ares-macos-universal.zip" || U="https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"
dl "$U" ares.zip && unzip -qo ares.zip >> "$LOG" 2>&1 && rm -f ares.zip && $IS_MAC && xattr -dr com.apple.quarantine Ares* 2>/dev/null && ok "Ares" || fail "Ares"

# ============================================================================
step "ENGINES"
# ============================================================================
cd "$TOOLS"
$IS_MAC && U="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip" || U="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
dl "$U" godot.zip && unzip -qo godot.zip >> "$LOG" 2>&1 && rm -f godot.zip && $IS_MAC && xattr -dr com.apple.quarantine Godot* 2>/dev/null && ok "Godot 4.3" || fail "Godot"
$IS_MAC && ok "Raylib (brew)"

# ============================================================================
step "ENVIRONMENT"
# ============================================================================
cat > "$INSTALL_DIR/env.sh" << 'ENVEOF'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"
[[ -d "$RETRO_DEV/compilers/n64/bin" ]] && export PATH="$RETRO_DEV/compilers/n64/bin:$PATH"
export PATH="$DEVKITARM/bin:$GBDK/bin:$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/vasm:$RETRO_DEV/tools/flips:$RETRO_DEV/sdks/atari:$PATH"
echo "  🐱 CAT'S TWEAKER v1.9.4 loaded!"
ENVEOF
chmod +x "$INSTALL_DIR/env.sh"; ok "env.sh"
add_path ""; add_path "# Cat's Tweaker v1.9.4"; add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
step "VERIFY"
# ============================================================================
source "$INSTALL_DIR/env.sh" 2>/dev/null; [[ -n "$BREW" ]] && eval "$("$BREW" shellenv)"
echo ""
command -v wget &>/dev/null && ok "wget" || fail "wget"
command -v curl &>/dev/null && ok "curl" || fail "curl"
command -v docker &>/dev/null && ok "docker" || fail "docker"
command -v nasm &>/dev/null && ok "nasm" || fail "nasm"
command -v yasm &>/dev/null && ok "yasm" || fail "yasm"
command -v cc65 &>/dev/null && ok "cc65" || fail "cc65"
command -v sdcc &>/dev/null && ok "sdcc" || fail "sdcc"
command -v rgbasm &>/dev/null && ok "rgbasm" || fail "rgbasm"
command -v node &>/dev/null && ok "node" || fail "node"
command -v npm &>/dev/null && ok "npm" || fail "npm"
command -v libdragon &>/dev/null && ok "libdragon" || warn "libdragon"
[[ -x "$SDKS/gbdk/bin/lcc" ]] && ok "GBDK lcc" || warn "GBDK"

# ============================================================================
echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v1.9.4 COMPLETE! ✨${RST}                              ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Homebrew:${RST} %-52s ${G}║${RST}\n" "$BREW_PREFIX"
printf "${G}  ║${RST}  ${C}Docker:${RST}   %-52s ${G}║${RST}\n" "$($HAS_DOCKER && echo "Running" || echo "Installed - start Docker Desktop")"
printf "${G}  ║${RST}  ${Y}ACTIVATE:${RST} ${W}source ~/.zshrc${RST}                                       ${G}║${RST}\n"
printf "${G}  ╚═══════════════════════════════════════════════════════════════════╝${RST}\n"
printf "\n                             ${M}/\\_____/\\${RST}\n"
printf "                            ${M}/  o   o  \\${RST}\n"
printf "                           ${M}( ==  ^  == )${RST}\n"
printf "                            ${M})  ~nya~  (${RST}\n"
printf "                           ${M}(           )${RST}\n"
printf "                          ${M}( (  )   (  ) )${RST}\n"
printf "                         ${M}(__(__)___(__)__)${RST}\n\n"
info "POST-INSTALL:"
echo "  1. ${W}source ~/.zshrc${RST}"
echo "  2. DevkitPro: sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /"
echo "  3. N64: mkdir proj && cd proj && libdragon init && libdragon make"
echo ""
