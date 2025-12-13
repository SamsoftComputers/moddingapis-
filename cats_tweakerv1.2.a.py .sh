#!/bin/bash
#===============================================================================
#     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
#    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
#    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
#    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
#    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
#     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
#                                        「  v1.2 - retro dev toolkit  」
#                                         by Flames / Team Flames 🐱
#===============================================================================
# USAGE: bash cats_tweaker.sh
#===============================================================================

[[ -z "$BASH_VERSION" ]] && { echo "Run with: bash $0"; exit 1; }

INSTALL_DIR="${HOME}/retro-dev"
TOOLS="${INSTALL_DIR}/tools"
SDKS="${INSTALL_DIR}/sdks"
EMUS="${INSTALL_DIR}/emulators"
COMPILERS="${INSTALL_DIR}/compilers"
LOG="${INSTALL_DIR}/install.log"
FAILED=""

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
NCPU=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
SHELL_RC="$HOME/.zshrc"; $IS_MAC || SHELL_RC="$HOME/.bashrc"

dl() {
    local url="$1" out="$2"
    curl -fsSL --connect-timeout 15 --max-time 300 --retry 3 -L -o "$out" "$url" 2>>"$LOG" && [[ -s "$out" ]] && return 0
    wget -q --timeout=15 --tries=3 -O "$out" "$url" 2>>"$LOG" && [[ -s "$out" ]] && return 0
    rm -f "$out"; return 1
}

safe() { "$@" >> "$LOG" 2>&1 || true; }
add_path() { grep -qF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

TOTAL=32; CURRENT=0
bar() {
    CURRENT=$((CURRENT + 1))
    local pct=$((CURRENT * 100 / TOTAL)) filled=$((pct / 2)) empty=$((50 - filled)) i
    printf "\r\033[K  \033[36m[\033[0m"
    for ((i=0;i<filled;i++)); do printf "█"; done
    for ((i=0;i<empty;i++)); do printf "░"; done
    printf "\033[36m]\033[0m \033[33m%3d%%\033[0m  \033[35m%s\033[0m" "$pct" "$1"
}

clear
cat << 'EOF'
     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                       「  v1.2 - retro dev toolkit  」
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )         (
                                          (           )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)
EOF
echo ""

bar "system deps..."
if $IS_MAC; then
    safe brew install gcc llvm cmake ninja meson autoconf automake libtool sdl2 sdl2_image sdl2_mixer sdl2_ttf libpng jpeg freetype zlib python3 nasm yasm flex bison texinfo readline ncurses wget curl p7zip libusb libftdi qemu dosbox-x glew glfw boost
else
    safe sudo apt-get update -qq
    safe sudo apt-get install -y -qq build-essential gcc g++ clang llvm cmake ninja-build meson autoconf automake libtool libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libpng-dev libjpeg-dev libfreetype6-dev zlib1g-dev python3 python3-pip nasm yasm flex bison texinfo libncurses-dev libreadline-dev curl wget unzip p7zip-full libusb-1.0-0-dev qemu-system-misc dosbox libgtk-3-dev libglew-dev libglfw3-dev xxd
fi

bar "python packages..."
safe pip3 install --user --break-system-packages -q pygame ursina pillow numpy pysdl2 pysdl2-dll pyyaml toml intelhex pyserial capstone keystone-engine unicorn || safe pip3 install --user -q pygame ursina pillow numpy pysdl2 pyyaml toml intelhex pyserial capstone

bar "libdragon n64..."
cd "$SDKS"
if dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.zip" libdragon.zip; then
    safe unzip -qo libdragon.zip && safe mv libdragon-trunk libdragon 2>/dev/null; rm -f libdragon.zip
else FAILED+="libdragon "; fi

bar "n64 toolchain..."
mkdir -p "${COMPILERS}/n64" && cd "${COMPILERS}/n64"
TC_OK=false
if $IS_MAC; then
    dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-macos-arm64.tar.gz" tc.tar.gz && TC_OK=true
    $TC_OK || { dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-macos-x86_64.tar.gz" tc.tar.gz && TC_OK=true; }
else
    dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz" tc.tar.gz && TC_OK=true
fi
if $TC_OK; then safe tar xzf tc.tar.gz; rm -f tc.tar.gz; add_path "export N64_INST=\"${COMPILERS}/n64\"; export PATH=\"\$N64_INST/bin:\$PATH\""; else FAILED+="n64-toolchain "; fi

bar "devkitpro..."
if $IS_MAC; then
    if dl "https://github.com/devkitPro/pacman/releases/download/v1.0.2/devkitpro-pacman-installer.pkg" "${COMPILERS}/devkitpro.pkg"; then
        echo "DevkitPro installer saved. Run: sudo installer -pkg ~/retro-dev/compilers/devkitpro.pkg -target /" >> "$LOG"
    else FAILED+="devkitpro "; fi
else
    mkdir -p "${COMPILERS}/devkitpro" && cd "${COMPILERS}/devkitpro"
    if dl "https://apt.devkitpro.org/install-devkitpro-pacman" dkp-install.sh; then
        chmod +x dkp-install.sh; echo "Run: sudo ./dkp-install.sh" >> "$LOG"
    else FAILED+="devkitpro "; fi
fi
add_path "export DEVKITPRO=\"/opt/devkitpro\"; export DEVKITARM=\"\$DEVKITPRO/devkitARM\"; export PATH=\"\$DEVKITARM/bin:\$PATH\""

bar "gbdk-2020..."
cd "$SDKS"
GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"
$IS_MAC && GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz"
if dl "$GB_URL" gbdk.tar.gz; then safe tar xzf gbdk.tar.gz; rm -f gbdk.tar.gz; add_path "export GBDK=\"${SDKS}/gbdk\"; export PATH=\"\$GBDK/bin:\$PATH\""; else FAILED+="gbdk "; fi

bar "rgbds..."
if $IS_MAC; then
    safe brew install rgbds
else
    cd "$TOOLS" && mkdir -p rgbds
    if dl "https://github.com/gbdev/rgbds/releases/download/v0.8.0/rgbds-0.8.0-linux-x86_64.tar.xz" rgbds.tar.xz; then
        safe tar xJf rgbds.tar.xz -C rgbds; rm -f rgbds.tar.xz; add_path "export PATH=\"${TOOLS}/rgbds:\$PATH\""
    else FAILED+="rgbds "; fi
fi

bar "cc65..."
if $IS_MAC; then safe brew install cc65
else
    cd "$COMPILERS"
    if dl "https://github.com/cc65/cc65/archive/refs/tags/V2.19.tar.gz" cc65.tar.gz; then
        safe tar xzf cc65.tar.gz && cd cc65-2.19 && safe make -j$NCPU && safe make PREFIX="${COMPILERS}/cc65-install" install; cd ..
        rm -f cc65.tar.gz; add_path "export CC65_HOME=\"${COMPILERS}/cc65-install\"; export PATH=\"\$CC65_HOME/bin:\$PATH\""
    else FAILED+="cc65 "; fi
fi

bar "sdcc..."
if $IS_MAC; then safe brew install sdcc
else
    cd "$COMPILERS"
    if dl "https://sourceforge.net/projects/sdcc/files/sdcc-linux-amd64/4.4.0/sdcc-4.4.0-amd64-unknown-linux2.5.tar.bz2/download" sdcc.tar.bz2; then
        safe tar xjf sdcc.tar.bz2 && safe mv sdcc-4.4.0 sdcc; rm -f sdcc.tar.bz2; add_path "export PATH=\"${COMPILERS}/sdcc/bin:\$PATH\""
    else FAILED+="sdcc "; fi
fi

bar "wla-dx..."
cd "$TOOLS"
if dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz; then
    safe tar xzf wla.tar.gz && cd wla-dx-10.6 && mkdir -p build && cd build && safe cmake .. -DCMAKE_BUILD_TYPE=Release && safe make -j$NCPU; cd ../..
    rm -f wla.tar.gz; add_path "export PATH=\"${TOOLS}/wla-dx-10.6/build/binaries:\$PATH\""
else FAILED+="wla-dx "; fi

bar "asm6f..."
cd "$TOOLS" && mkdir -p asm6 && cd asm6
if dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c || dl "https://raw.githubusercontent.com/loopy-ru/asm6f/master/asm6f.c" asm6f.c; then
    safe gcc -O3 -o asm6f asm6f.c && add_path "export PATH=\"${TOOLS}/asm6:\$PATH\""
else FAILED+="asm6 "; fi

bar "nesasm..."
cd "$TOOLS" && mkdir -p nesasm && cd nesasm
if dl "https://github.com/camsaul/nesasm/archive/refs/heads/master.zip" nesasm.zip; then
    safe unzip -qo nesasm.zip && cd nesasm-master/source && safe make; cd ../..
    rm -f nesasm.zip
else FAILED+="nesasm "; fi

bar "dasm..."
cd "$SDKS" && mkdir -p atari && cd atari
DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"
$IS_MAC && DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz"
if dl "$DASM_URL" dasm.tar.gz; then safe tar xzf dasm.tar.gz; rm -f dasm.tar.gz; add_path "export PATH=\"${SDKS}/atari:\$PATH\""; else FAILED+="dasm "; fi

bar "sgdk..."
cd "$SDKS"
if dl "https://github.com/Stephane-D/SGDK/releases/download/v2.00/sgdk200.7z" sgdk.7z; then
    mkdir -p sgdk && cd sgdk && safe 7z x -y ../sgdk.7z; cd ..; rm -f sgdk.7z; add_path "export SGDK=\"${SDKS}/sgdk\""
elif dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz; then
    safe tar xzf sgdk.tar.gz && safe mv SGDK-2.00 sgdk; rm -f sgdk.tar.gz; add_path "export SGDK=\"${SDKS}/sgdk\""
else FAILED+="sgdk "; fi

bar "pvsneslib..."
cd "$SDKS"
if dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip; then
    safe unzip -qo pvs.zip && safe mv pvsneslib-master pvsneslib; rm -f pvs.zip; add_path "export PVSNESLIB=\"${SDKS}/pvsneslib\""
else FAILED+="pvsneslib "; fi

bar "vbcc..."
cd "$COMPILERS" && mkdir -p vbcc && cd vbcc
dl "http://phoenix.owl.de/tags/vbcc0_9h.tar.gz" vbcc.tar.gz && safe tar xzf vbcc.tar.gz && rm -f vbcc.tar.gz || FAILED+="vbcc "

bar "flips..."
cd "$TOOLS" && mkdir -p flips && cd flips
FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v1.31/flips-linux.zip"
$IS_MAC && FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v1.31/flips-mac.zip"
if dl "$FLIPS_URL" flips.zip; then safe unzip -qo flips.zip; rm -f flips.zip; add_path "export PATH=\"${TOOLS}/flips:\$PATH\""; else FAILED+="flips "; fi

bar "lunar ips..."
cd "$TOOLS" && mkdir -p lunar && cd lunar
if dl "https://www.romhacking.net/download/utilities/240/lips.zip" lips.zip || dl "https://fusoya.eludevisibility.org/lips/download/lips106.zip" lips.zip; then
    safe unzip -qo lips.zip; rm -f lips.zip
else FAILED+="lunar-ips "; fi

bar "fceux..."
cd "$EMUS"
if dl "https://github.com/TASEmulators/fceux/archive/refs/tags/v2.6.6.tar.gz" fceux.tar.gz; then safe tar xzf fceux.tar.gz; rm -f fceux.tar.gz; else FAILED+="fceux "; fi

bar "snes9x..."
if dl "https://github.com/snes9xgit/snes9x/archive/refs/tags/1.63.tar.gz" snes9x.tar.gz; then safe tar xzf snes9x.tar.gz; rm -f snes9x.tar.gz; else FAILED+="snes9x "; fi

bar "mgba..."
MGBA_OK=false
if $IS_MAC; then
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.3/mGBA-0.10.3-macos-arm64.dmg" mgba.dmg && MGBA_OK=true
    $MGBA_OK || { dl "https://github.com/mgba-emu/mgba/releases/download/0.10.3/mGBA-0.10.3-macos-x64.dmg" mgba.dmg && MGBA_OK=true; }
else
    dl "https://github.com/mgba-emu/mgba/archive/refs/tags/0.10.3.tar.gz" mgba.tar.gz && safe tar xzf mgba.tar.gz && rm -f mgba.tar.gz && MGBA_OK=true
fi
$MGBA_OK || FAILED+="mgba "

bar "mupen64plus..."
if dl "https://github.com/mupen64plus/mupen64plus-core/archive/refs/tags/2.6.0.tar.gz" mupen.tar.gz; then safe tar xzf mupen.tar.gz; rm -f mupen.tar.gz; else FAILED+="mupen64plus "; fi

bar "ares..."
ARES_OK=false
if $IS_MAC; then
    dl "https://github.com/ares-emulator/ares/releases/download/v141/ares-macos-arm64.zip" ares.zip && ARES_OK=true
    $ARES_OK || { dl "https://github.com/ares-emulator/ares/releases/download/v141/ares-macos-x64.zip" ares.zip && ARES_OK=true; }
else
    dl "https://github.com/ares-emulator/ares/releases/download/v141/ares-linux-x86_64.zip" ares.zip && ARES_OK=true
fi
if $ARES_OK; then mkdir -p ares && safe unzip -qo ares.zip -d ares; rm -f ares.zip; else FAILED+="ares "; fi

bar "stella..."
if dl "https://github.com/stella-emu/stella/archive/refs/tags/6.7.1.tar.gz" stella.tar.gz; then safe tar xzf stella.tar.gz; rm -f stella.tar.gz; else FAILED+="stella "; fi

bar "simh..."
cd "$TOOLS" && mkdir -p vintage
if $IS_MAC; then safe brew install simh
else
    if dl "https://github.com/simh/simh/archive/refs/tags/v3.12-4.tar.gz" simh.tar.gz; then
        safe tar xzf simh.tar.gz -C vintage; rm -f simh.tar.gz
    else FAILED+="simh "; fi
fi

bar "z80pack..."
cd "$TOOLS/vintage"
if dl "https://www.autometer.de/unix4fun/z80pack/ftp/z80pack-1.37.tgz" z80.tgz; then
    safe tar xzf z80.tgz; rm -f z80.tgz
else FAILED+="z80pack "; fi

bar "raylib..."
cd "$TOOLS"
if dl "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz" raylib.tar.gz; then safe tar xzf raylib.tar.gz; rm -f raylib.tar.gz; else FAILED+="raylib "; fi
$IS_MAC && safe brew install raylib

bar "love2d..."
if $IS_MAC; then
    dl "https://github.com/love2d/love/releases/download/11.5/love-11.5-macos.zip" love.zip && safe unzip -qo love.zip && rm -f love.zip || FAILED+="love2d "
else
    dl "https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.tar.gz" love.tar.gz && safe tar xzf love.tar.gz && rm -f love.tar.gz || FAILED+="love2d "
fi

bar "godot..."
GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
$IS_MAC && GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip"
if dl "$GODOT_URL" godot.zip; then safe unzip -qo godot.zip; rm -f godot.zip; else FAILED+="godot "; fi

bar "audio tools..."
cd "$TOOLS" && mkdir -p audio
if $IS_MAC; then safe brew install milkytracker
else
    dl "https://github.com/milkytracker/MilkyTracker/archive/refs/tags/v1.04.00.tar.gz" mt.tar.gz && safe tar xzf mt.tar.gz -C audio && rm -f mt.tar.gz || FAILED+="milkytracker "
fi

bar "finalizing..."
cat > "${INSTALL_DIR}/env.sh" << 'ENVEOF'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
export N64_INST="$RETRO_DEV/compilers/n64"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export GBDK="$RETRO_DEV/sdks/gbdk"
export CC65_HOME="$RETRO_DEV/compilers/cc65-install"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"
export PATH="$N64_INST/bin:$DEVKITARM/bin:$GBDK/bin:$CC65_HOME/bin:$RETRO_DEV/compilers/sdcc/bin:$RETRO_DEV/tools/rgbds:$RETRO_DEV/tools/flips:$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/wla-dx-10.6/build/binaries:$RETRO_DEV/sdks/atari:$PATH"
echo "🐱 CATS TWEAKER environment loaded! 🎮"
ENVEOF
chmod +x "${INSTALL_DIR}/env.sh"

echo ""
echo ""
printf "\033[32m  ╔═══════════════════════════════════════════════════════════════╗\033[0m\n"
printf "\033[32m  ║\033[0m  \033[1;37m✨ CATS TWEAKER 1.2 INSTALLATION COMPLETE! ✨\033[0m                \033[32m║\033[0m\n"
printf "\033[32m  ╠═══════════════════════════════════════════════════════════════╣\033[0m\n"
printf "\033[32m  ║\033[0m  \033[36mInstalled to:\033[0m %-44s \033[32m║\033[0m\n" "$INSTALL_DIR"
printf "\033[32m  ║\033[0m  \033[36mActivate:\033[0m     source ~/retro-dev/env.sh                      \033[32m║\033[0m\n"
printf "\033[32m  ║\033[0m  \033[36mLog:\033[0m          ~/retro-dev/install.log                       \033[32m║\033[0m\n"
printf "\033[32m  ╚═══════════════════════════════════════════════════════════════╝\033[0m\n"
[[ -n "$FAILED" ]] && printf "\033[33m  ⚠ Some components had issues: %s\033[0m\n" "$FAILED"
[[ -n "$FAILED" ]] && printf "\033[33m    Check install.log for details. Re-run to retry.\033[0m\n"
echo ""
printf "                           \033[35m/\\_____/\\\033[0m\n"
printf "                          \033[35m/  o   o  \\\033[0m\n"
printf "                         \033[35m( ==  ^  == )\033[0m\n"
printf "                          \033[35m)  ~nya~  (\033[0m\n"
printf "                         \033[35m(           )\033[0m\n"
printf "                        \033[35m( (  )   (  ) )\033[0m\n"
printf "                       \033[35m(__(__)___(__)__)\033[0m\n"
echo ""
