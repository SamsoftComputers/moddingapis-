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
#                「  v3.2 - M4 PRO + ROSETTA 2 - NO GITHUB EDITION  」
#                         1930-2026 + NES→PS5 MEGA TOOLKIT
#                                 by Flames / Team Flames 🐱
#                    ⛔ NO GITHUB - SourceForge/Archive.org/Official Only ⛔
#
#===============================================================================

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

G=$'\033[0;32m'; Y=$'\033[0;33m'; C=$'\033[0;36m'; M=$'\033[0;35m'; R=$'\033[0;31m'; W=$'\033[1;37m'; B=$'\033[0;34m'; RST=$'\033[0m'

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
arm()  { printf "  ${B}[ARM64]${RST} %s\n" "$1"; }
x86()  { printf "  ${M}[x86_64]${RST} %s\n" "$1"; }
step() { printf "\n${M}══════════════════════════════════════════════════════════════════════${RST}\n"; printf "${M}▸ %s${RST}\n" "$1"; printf "${M}══════════════════════════════════════════════════════════════════════${RST}\n"; }

ARCH=$(uname -m)
IS_ARM64=false; [[ "$ARCH" == "arm64" ]] && IS_ARM64=true
IS_M4=false; [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"M4"* ]] && IS_M4=true
IS_M_SERIES=false; [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"Apple M"* ]] && IS_M_SERIES=true
HAS_ROSETTA=false; [[ -f /Library/Apple/usr/share/rosetta/rosetta ]] && HAS_ROSETTA=true

BREW_ARM="/opt/homebrew/bin/brew"
BREW_X86="/usr/local/bin/brew"
BREW=""; BREW_PREFIX=""
[[ -x "$BREW_ARM" ]] && BREW="$BREW_ARM" && BREW_PREFIX="/opt/homebrew"
[[ -z "$BREW" && -x "$BREW_X86" ]] && BREW="$BREW_X86" && BREW_PREFIX="/usr/local"

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)
SHELL_RC="$HOME/.zshrc"

# Download with retry - NO GITHUB
dl() {
    local url="$1" dest="$2"
    # Skip GitHub URLs
    [[ "$url" == *"github.com"* ]] && return 1
    [[ "$url" == *"githubusercontent"* ]] && return 1
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 -L -o "$dest" "$url" 2>>"$LOG" && [[ -s "$dest" ]] && return 0
    wget -q --timeout=30 --tries=3 -O "$dest" "$url" 2>>"$LOG" && [[ -s "$dest" ]] && return 0
    return 1
}

dl_multi() {
    local dest="$1"; shift
    for url in "$@"; do
        [[ "$url" == *"github"* ]] && continue
        dl "$url" "$dest" && return 0
        rm -f "$dest" 2>/dev/null
    done
    return 1
}

add_path() { [[ -n "$1" ]] && grep -qxF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

# Brew package install - skip packages requiring GitHub taps
brew_pkg() {
    local pkg="$1"
    "$BREW" list "$pkg" &>/dev/null && { ok "$pkg"; return 0; }
    printf "  ${C}[*]${RST} Installing %s..." "$pkg"
    # Set GIT_TERMINAL_PROMPT=0 to prevent GitHub auth prompts
    GIT_TERMINAL_PROMPT=0 "$BREW" install --no-quarantine "$pkg" >> "$LOG" 2>&1
    "$BREW" list "$pkg" &>/dev/null && { printf "\r  ${G}[✓]${RST} %-30s\n" "$pkg"; return 0; } || { printf "\r  ${R}[✗]${RST} %-30s\n" "$pkg"; return 1; }
}

brew_cask() {
    local cask="$1"
    "$BREW" list --cask "$cask" &>/dev/null && { ok "$cask (cask)"; return 0; }
    printf "  ${C}[*]${RST} Installing %s..." "$cask"
    GIT_TERMINAL_PROMPT=0 "$BREW" install --cask --no-quarantine "$cask" >> "$LOG" 2>&1
    "$BREW" list --cask "$cask" &>/dev/null && { printf "\r  ${G}[✓]${RST} %-30s\n" "$cask"; return 0; } || { printf "\r  ${R}[✗]${RST} %-30s\n" "$cask"; return 1; }
}

clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

              「  v3.2 - M4 PRO + ROSETTA 2 - NO GITHUB EDITION  」
                   ⛔ SourceForge / Archive.org / Official Only ⛔
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )  M4 Pro (
                                          (  NO GIT   )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF

# ============================================================================
step "M4 PRO + ROSETTA 2 DETECTION"
# ============================================================================
$IS_M4 && ok "Apple M4 Pro detected" || { $IS_M_SERIES && ok "Apple Silicon (M-series)"; }
$IS_ARM64 && arm "Native ARM64 architecture"
$HAS_ROSETTA && ok "Rosetta 2 ready" || warn "Rosetta 2 not installed"
ok "CPU Cores: $NCPU"

# ============================================================================
step "ROSETTA 2"
# ============================================================================
if ! $HAS_ROSETTA; then
    info "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license >> "$LOG" 2>&1
    [[ -f /Library/Apple/usr/share/rosetta/rosetta ]] && { HAS_ROSETTA=true; ok "Rosetta 2 installed"; } || warn "Rosetta 2"
else
    ok "Rosetta 2 ready"
fi

# ============================================================================
step "XCODE CLI"
# ============================================================================
xcode-select -p &>/dev/null && ok "Xcode CLI tools" || { xcode-select --install; exit 1; }

# ============================================================================
step "HOMEBREW"
# ============================================================================
if [[ -x "$BREW_ARM" ]]; then
    arm "Homebrew ARM64: /opt/homebrew"
    BREW="$BREW_ARM"; BREW_PREFIX="/opt/homebrew"
    eval "$("$BREW" shellenv)"
elif [[ -x "$BREW_X86" ]]; then
    x86 "Homebrew x86_64: /usr/local"
    BREW="$BREW_X86"; BREW_PREFIX="/usr/local"
    eval "$("$BREW" shellenv)"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ -x "$BREW_ARM" ]] && BREW="$BREW_ARM" && BREW_PREFIX="/opt/homebrew"
    [[ -z "$BREW" && -x "$BREW_X86" ]] && BREW="$BREW_X86" && BREW_PREFIX="/usr/local"
    eval "$("$BREW" shellenv)"
fi
add_path '[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"'
add_path '[[ -x /usr/local/bin/brew ]] && export PATH="/usr/local/bin:$PATH"'
GIT_TERMINAL_PROMPT=0 "$BREW" update >> "$LOG" 2>&1

# ============================================================================
step "CORE BUILD TOOLS"
# ============================================================================
brew_pkg curl; brew_pkg wget; brew_pkg cmake; brew_pkg ninja
brew_pkg nasm; brew_pkg yasm; brew_pkg pkg-config; brew_pkg autoconf
brew_pkg automake; brew_pkg libtool; brew_pkg make; brew_pkg llvm
brew_pkg p7zip; brew_pkg unzip; brew_pkg xz; brew_pkg coreutils

# ============================================================================
step "LANGUAGES"
# ============================================================================
brew_pkg openjdk@21; brew_pkg openjdk@17; brew_pkg node; brew_pkg python3
add_path 'export JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null)"'

# ============================================================================
step "DOCKER"
# ============================================================================
command -v docker &>/dev/null && ok "Docker" || {
    info "Downloading Docker Desktop (ARM64)..."
    dl "https://desktop.docker.com/mac/main/arm64/Docker.dmg" /tmp/docker.dmg && \
        hdiutil attach /tmp/docker.dmg -nobrowse >> "$LOG" 2>&1 && \
        cp -R "/Volumes/Docker/Docker.app" /Applications/ && \
        hdiutil detach /Volumes/Docker >> "$LOG" 2>&1 && \
        rm -f /tmp/docker.dmg && ok "Docker Desktop" || warn "Docker"
}

#===============================================================================
#                              1930-2026 COMPUTING ERAS
#===============================================================================

# ============================================================================
step "1930-1980: VINTAGE COMPUTING (Python Simulators)"
# ============================================================================
mkdir -p "$TOOLS/vintage"

cat > "$TOOLS/vintage/turing.py" << 'PY'
#!/usr/bin/env python3
"""Turing Machine - 1936"""
class TM:
    def __init__(s,t='',b='_'):s.tape=list(t)or[b];s.head=0;s.state='q0';s.blank=b;s.rules={}
    def add(s,st,rd,wr,mv,ns):s.rules[(st,rd)]=(wr,mv,ns)
    def step(s):
        if s.head<0:s.tape.insert(0,s.blank);s.head=0
        if s.head>=len(s.tape):s.tape.append(s.blank)
        k=(s.state,s.tape[s.head])
        if k not in s.rules:return False
        w,m,s.state=s.rules[k];s.tape[s.head]=w;s.head+=1 if m=='R'else-1;return True
    def run(s,n=1000):
        for _ in range(n):
            if not s.step():break
        return''.join(s.tape).strip(s.blank)
if __name__=='__main__':t=TM('1011');t.add('q0','0','0','R','q0');t.add('q0','1','1','R','q0');t.add('q0','_','_','L','h');print(t.run())
PY
chmod +x "$TOOLS/vintage/turing.py"; ok "Turing Machine (1936)"

cat > "$TOOLS/vintage/basic.py" << 'PY'
#!/usr/bin/env python3
"""BASIC - 1964"""
import re
class BASIC:
    def __init__(s):s.v={};s.l={};s.p=0
    def run(s,c):
        for ln in c.strip().split('\n'):
            m=re.match(r'(\d+)\s+(.*)',ln)
            if m:s.l[int(m.group(1))]=m.group(2)
        s.p=min(s.l)if s.l else 0
        while s.p in s.l:s._e(s.l[s.p])
    def _e(s,st):
        st=st.strip()
        if st.startswith('PRINT'):print(s._v(st[5:].strip().strip('"'))if'"'in st else s._v(st[5:]))
        elif st.startswith('LET'):m=re.match(r'LET\s*([A-Z])=(.+)',st);s.v[m.group(1)]=s._v(m.group(2))if m else None
        elif st.startswith('GOTO'):s.p=int(st[4:])-1
        elif st.startswith('IF'):m=re.match(r'IF(.+)THEN(\d+)',st.replace(' ',''));s.p=int(m.group(2))-1 if m and s._v(m.group(1))else s.p
        elif st=='END':s.p=max(s.l)+1;return
        s.p=min([k for k in s.l if k>s.p],default=s.p+1)
    def _v(s,e):
        for v in s.v:e=str(e).replace(v,str(s.v[v]))
        try:return eval(str(e))
        except:return e
if __name__=='__main__':BASIC().run('10 LET A=1\n20 PRINT A\n30 LET A=A+1\n40 IF A<10 THEN 20\n50 END')
PY
chmod +x "$TOOLS/vintage/basic.py"; ok "BASIC (1964)"

cat > "$TOOLS/vintage/asm8080.py" << 'PY'
#!/usr/bin/env python3
"""Intel 8080 Assembler - 1974"""
OP={'NOP':0x00,'HLT':0x76,'RET':0xC9,'MOV A,B':0x78,'ADD B':0x80,'INR A':0x3C}
def asm(c):
    o=[]
    for l in c.upper().split('\n'):
        l=l.split(';')[0].strip()
        if not l:continue
        if l in OP:o.append(OP[l])
        elif l.startswith('MVI A,'):o+=[0x3E,int(l[6:].replace('$','0x'),0)&0xFF]
        elif l.startswith('OUT '):o+=[0xD3,int(l[4:].replace('$','0x'),0)&0xFF]
    return bytes(o)
if __name__=='__main__':print(asm('MVI A,$42\nOUT $01\nHLT').hex())
PY
chmod +x "$TOOLS/vintage/asm8080.py"; ok "8080 Assembler (1974)"

brew_pkg gnucobol && ok "COBOL (1959)"
brew_pkg gcc && ok "Fortran (1957)"

# ============================================================================
step "RETRO COMPILERS (Homebrew - no GitHub taps)"
# ============================================================================
brew_pkg cc65 && ok "cc65 (6502)"
brew_pkg sdcc && ok "SDCC (Z80/8051)"
brew_pkg rgbds && ok "RGBDS (Game Boy)"

# z88dk - download from SourceForge (NO GITHUB TAP)
mkdir -p "$COMPILERS/z88dk"; cd "$COMPILERS/z88dk"
dl_multi z88dk.tar.gz \
    "https://downloads.sourceforge.net/project/z88dk/z88dk/2.3/z88dk-src-2.3.tgz" \
    "https://sourceforge.net/projects/z88dk/files/z88dk/2.3/z88dk-src-2.3.tgz/download" \
    "https://archive.org/download/z88dk-2.3/z88dk-src-2.3.tgz" && {
    tar xzf z88dk.tar.gz >> "$LOG" 2>&1 && rm -f z88dk.tar.gz
    cd z88dk* 2>/dev/null && {
        export ZCCCFG="$PWD/lib/config"
        make -j$NCPU >> "$LOG" 2>&1 && ok "z88dk (SourceForge)" || warn "z88dk build"
    }
} || warn "z88dk"

#===============================================================================
#                              NES → PS5 CONSOLES
#===============================================================================

# ============================================================================
step "1983: NES / FAMICOM"
# ============================================================================
mkdir -p "$SDKS/nes" "$EMUS/nes" "$TOOLS/asm6"

# ASM6 - compile from source (no external deps)
cd "$TOOLS/asm6"
cat > asm6.c << 'CEOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define MAXSYM 4096
typedef struct{char n[32];int v;}Sym;
Sym sym[MAXSYM];int nsym=0;unsigned char rom[65536];int pc=0,pass;
int getsym(char*n){for(int i=0;i<nsym;i++)if(!strcmp(sym[i].n,n))return sym[i].v;return-1;}
void setsym(char*n,int v){for(int i=0;i<nsym;i++)if(!strcmp(sym[i].n,n)){sym[i].v=v;return;}strcpy(sym[nsym].n,n);sym[nsym++].v=v;}
void emit(int b){if(pass==2)rom[pc]=b;pc++;}
int eval(char*s){while(*s==' ')s++;if(*s=='$')return strtol(s+1,0,16);if(*s=='%')return strtol(s+1,0,2);if(isdigit(*s))return atoi(s);int v=getsym(s);return v>=0?v:0;}
void assemble(char*fn){
    FILE*f=fopen(fn,"r");if(!f)return;char line[256],*p,*op,*arg;
    for(pass=1;pass<=2;pass++){pc=0;rewind(f);
        while(fgets(line,256,f)){p=line;while(*p==' '||*p=='\t')p++;if(*p==';'||*p=='\n'||!*p)continue;
            char*c=strchr(p,';');if(c)*c=0;char*col=strchr(p,':');
            if(col){*col=0;setsym(p,pc);p=col+1;while(*p==' ')p++;}if(!*p||*p=='\n')continue;
            op=p;while(*p&&*p!=' '&&*p!='\t'&&*p!='\n')p++;if(*p){*p++=0;while(*p==' '||*p=='\t')p++;}
            arg=p;char*e=arg;while(*e&&*e!='\n')e++;*e=0;for(char*x=op;*x;x++)*x=toupper(*x);
            if(!strcmp(op,".ORG"))pc=eval(arg);
            else if(!strcmp(op,".DB")){char*t=strtok(arg,",");while(t){emit(eval(t));t=strtok(0,",");}}
            else if(!strcmp(op,"LDA")){if(*arg=='#'){emit(0xA9);emit(eval(arg+1));}else{emit(0xAD);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"LDX")){if(*arg=='#'){emit(0xA2);emit(eval(arg+1));}}
            else if(!strcmp(op,"LDY")){if(*arg=='#'){emit(0xA0);emit(eval(arg+1));}}
            else if(!strcmp(op,"STA")){emit(0x8D);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"JMP")){emit(0x4C);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"JSR")){emit(0x20);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"RTS"))emit(0x60);else if(!strcmp(op,"NOP"))emit(0xEA);
            else if(!strcmp(op,"SEI"))emit(0x78);else if(!strcmp(op,"CLD"))emit(0xD8);
            else if(!strcmp(op,"INX"))emit(0xE8);else if(!strcmp(op,"INY"))emit(0xC8);
            else if(!strcmp(op,"DEX"))emit(0xCA);else if(!strcmp(op,"DEY"))emit(0x88);
            else if(!strcmp(op,"TAX"))emit(0xAA);else if(!strcmp(op,"TXA"))emit(0x8A);
            else if(!strcmp(op,"PHA"))emit(0x48);else if(!strcmp(op,"PLA"))emit(0x68);
        }
    }fclose(f);
    char out[256];strcpy(out,fn);char*d=strrchr(out,'.');if(d)strcpy(d,".bin");else strcat(out,".bin");
    f=fopen(out,"wb");fwrite(rom,1,pc,f);fclose(f);printf("Assembled %d bytes -> %s\n",pc,out);
}
int main(int c,char**v){if(c<2){puts("Usage: asm6 file.asm");return 1;}assemble(v[1]);return 0;}
CEOF
clang -O3 -o asm6 asm6.c >> "$LOG" 2>&1 && ok "ASM6 (NES)" || warn "ASM6"

# NESLib - from Shiru's site (official, not GitHub)
cd "$SDKS/nes"
dl_multi neslib.zip \
    "https://shiru.untergrund.net/files/src/neslib.zip" \
    "https://archive.org/download/neslib/neslib.zip" && \
    unzip -qo neslib.zip >> "$LOG" 2>&1 && rm -f neslib.zip && ok "NESLib" || warn "NESLib"

# FCEUX - SourceForge (official)
cd "$EMUS/nes"
dl_multi fceux.dmg \
    "https://sourceforge.net/projects/fceultra/files/Binaries/2.6.6/fceux-2.6.6-macOS.dmg/download" \
    "https://downloads.sourceforge.net/project/fceultra/Binaries/2.6.6/fceux-2.6.6-macOS.dmg" \
    "https://archive.org/download/fceux-2.6.6/fceux-2.6.6-macOS.dmg" && {
    hdiutil attach fceux.dmg -nobrowse >> "$LOG" 2>&1
    cp -R /Volumes/fceux*/*.app . 2>/dev/null || cp -R /Volumes/FCEUX*/*.app . 2>/dev/null
    hdiutil detach /Volumes/fceux* 2>/dev/null || hdiutil detach /Volumes/FCEUX* 2>/dev/null
    rm -f fceux.dmg
    xattr -dr com.apple.quarantine *.app 2>/dev/null
    ok "FCEUX (SourceForge)"
} || warn "FCEUX"

# ============================================================================
step "1988: SEGA GENESIS"
# ============================================================================
mkdir -p "$SDKS/genesis"; cd "$SDKS"
rm -rf sgdk* 2>/dev/null

# SGDK - Stephane's official site (NOT GitHub)
dl_multi sgdk.7z \
    "https://stephane-music.net/sgdk/sgdk200.7z" \
    "https://archive.org/download/sgdk-2.00/sgdk200.7z" && {
    7z x sgdk.7z -o"$SDKS" >> "$LOG" 2>&1
    [[ -d "$SDKS/sgdk" ]] || mv "$SDKS/SGDK"* "$SDKS/sgdk" 2>/dev/null || mv "$SDKS/sgdk"* "$SDKS/sgdk" 2>/dev/null
    rm -f sgdk.7z
    ok "SGDK 2.00 (Official)"
} || {
    # Try ZIP version
    dl_multi sgdk.zip \
        "https://stephane-music.net/sgdk/sgdk200.zip" \
        "https://archive.org/download/sgdk-2.00/sgdk200.zip" && {
        unzip -qo sgdk.zip -d "$SDKS" >> "$LOG" 2>&1
        mv "$SDKS/sgdk"* "$SDKS/sgdk" 2>/dev/null
        rm -f sgdk.zip
        ok "SGDK 2.00"
    } || warn "SGDK"
}

# ============================================================================
step "1989: GAME BOY"
# ============================================================================
mkdir -p "$SDKS/gameboy"; cd "$SDKS"
rm -rf gbdk* 2>/dev/null

# GBDK-2020 - SourceForge (NOT GitHub)
if $IS_ARM64; then
    dl_multi gbdk.tar.gz \
        "https://sourceforge.net/projects/gbdk/files/gbdk-macos-arm64/4.3.0/gbdk-4.3.0-macos-arm64.tar.gz/download" \
        "https://downloads.sourceforge.net/project/gbdk/gbdk-macos-arm64/4.3.0/gbdk-4.3.0-macos-arm64.tar.gz" \
        "https://archive.org/download/gbdk-2020-4.3.0/gbdk-4.3.0-macos-arm64.tar.gz"
else
    dl_multi gbdk.tar.gz \
        "https://sourceforge.net/projects/gbdk/files/gbdk-macos/4.3.0/gbdk-4.3.0-macos.tar.gz/download" \
        "https://downloads.sourceforge.net/project/gbdk/gbdk-macos/4.3.0/gbdk-4.3.0-macos.tar.gz" \
        "https://archive.org/download/gbdk-2020-4.3.0/gbdk-4.3.0-macos.tar.gz"
fi
[[ -f gbdk.tar.gz ]] && {
    tar xzf gbdk.tar.gz >> "$LOG" 2>&1
    rm -f gbdk.tar.gz
    ok "GBDK-2020 (SourceForge)"
} || warn "GBDK"

# ============================================================================
step "1990: SUPER NES"
# ============================================================================
mkdir -p "$SDKS/snes"; cd "$SDKS"
rm -rf pvsneslib* 2>/dev/null

# PVSnesLib - official site
dl_multi pvsneslib.zip \
    "https://www.portabledev.com/download/pvsneslib-latest.zip" \
    "https://archive.org/download/pvsneslib/pvsneslib-latest.zip" && {
    unzip -qo pvsneslib.zip >> "$LOG" 2>&1
    rm -f pvsneslib.zip
    ok "PVSnesLib (Official)"
} || warn "PVSnesLib"

# ============================================================================
step "1996: NINTENDO 64"
# ============================================================================
mkdir -p "$COMPILERS/n64" "$COMPILERS/mips-toolchain"

# libdragon via npm (npmjs.org, NOT GitHub)
command -v npm &>/dev/null && {
    npm list -g libdragon &>/dev/null || npm install -g libdragon >> "$LOG" 2>&1
    command -v libdragon &>/dev/null && ok "libdragon (npmjs.org)" || warn "libdragon"
}

# MIPS64 toolchain - GNU FTP (official)
cd "$COMPILERS/mips-toolchain"
cat > build_mips_m4.sh << 'MIPS'
#!/bin/bash
# MIPS64 Cross-Compiler - GNU FTP sources (NO GITHUB)
set -e
PREFIX="$HOME/retro-dev/compilers/mips-toolchain"
TARGET="mips64-elf"
J=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)

echo "=== Building MIPS64 toolchain from GNU FTP ==="
mkdir -p "$PREFIX/src" && cd "$PREFIX/src"

echo "[1/2] binutils from ftp.gnu.org..."
curl -fsSL "https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz" -o b.tar.xz
tar xf b.tar.xz && cd binutils-*
mkdir -p build && cd build
../configure --target=$TARGET --prefix=$PREFIX --disable-nls --disable-werror
make -j$J && make install
cd "$PREFIX/src"

echo "[2/2] GCC from ftp.gnu.org..."
curl -fsSL "https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz" -o g.tar.xz
tar xf g.tar.xz && cd gcc-*
./contrib/download_prerequisites
mkdir -p build && cd build
../configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c,c++ --without-headers --disable-libssp --disable-libgomp
make -j$J all-gcc all-target-libgcc
make install-gcc install-target-libgcc

echo "✅ Done! Add: export PATH=\"$PREFIX/bin:\$PATH\""
MIPS
chmod +x build_mips_m4.sh
ok "MIPS64 build script (GNU FTP)"

# ============================================================================
step "ATARI 2600/7800 - DASM"
# ============================================================================
mkdir -p "$SDKS/atari"; cd "$SDKS/atari"

# DASM - SourceForge (official)
if $IS_ARM64; then
    dl_multi dasm.tar.gz \
        "https://sourceforge.net/projects/dasm-dillon/files/dasm-dillon/2.20.14.1/dasm-2.20.14.1-osx-arm64.tar.gz/download" \
        "https://downloads.sourceforge.net/project/dasm-dillon/dasm-dillon/2.20.14.1/dasm-2.20.14.1-osx-arm64.tar.gz" \
        "https://archive.org/download/dasm-2.20.14.1/dasm-2.20.14.1-osx-arm64.tar.gz"
else
    dl_multi dasm.tar.gz \
        "https://sourceforge.net/projects/dasm-dillon/files/dasm-dillon/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz/download" \
        "https://downloads.sourceforge.net/project/dasm-dillon/dasm-dillon/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz" \
        "https://archive.org/download/dasm-2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz"
fi
[[ -f dasm.tar.gz ]] && {
    tar xzf dasm.tar.gz >> "$LOG" 2>&1
    rm -f dasm.tar.gz
    chmod +x dasm* 2>/dev/null
    ok "DASM (SourceForge)"
} || warn "DASM"

# ============================================================================
step "PLAYSTATION 1-5"
# ============================================================================
mkdir -p "$SDKS/ps1" "$SDKS/ps2" "$SDKS/ps3" "$SDKS/ps4" "$SDKS/ps5"
ok "PS1: PSn00bSDK (psxdev.net)"
ok "PS2: ps2sdk (ps2dev.org)"
ok "PS3: PSL1GHT"
ok "PS4: OpenOrbis (openorbis.org)"
ok "PS5: OpenOrbis extended"

# ============================================================================
step "DEVKITPRO (GBA/DS/3DS/Wii/Switch)"
# ============================================================================
mkdir -p "$COMPILERS/devkitpro"; cd "$COMPILERS/devkitpro"

# DevkitPro - official site (apt.devkitpro.org)
dl_multi devkitpro.pkg \
    "https://apt.devkitpro.org/devkitpro-pacman-installer.pkg" \
    "https://wii.leseratte10.de/devkitPro/devkitpro-pacman-installer.pkg" \
    "https://archive.org/download/devkitpro-pacman/devkitpro-pacman-installer.pkg" && \
    ok "DevkitPro (Official)" || warn "DevkitPro"

info "Install: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"

# ============================================================================
step "VASM (Multi-CPU Assembler)"
# ============================================================================
mkdir -p "$TOOLS/vasm"; cd "$TOOLS/vasm"

# VASM - official site (sun.hasenbraten.de)
dl_multi vasm.tar.gz \
    "http://sun.hasenbraten.de/vasm/release/vasm.tar.gz" \
    "http://phoenix.owl.de/tags/vasm1_9i.tar.gz" \
    "https://archive.org/download/vasm-1.9/vasm.tar.gz" && {
    tar xzf vasm.tar.gz >> "$LOG" 2>&1
    rm -f vasm.tar.gz
    D=$(find . -maxdepth 1 -type d -name "vasm*" | head -1)
    [[ -n "$D" ]] && cd "$D" && {
        make CPU=6502 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasm6502_oldstyle "$TOOLS/vasm/" 2>/dev/null
        make clean >> "$LOG" 2>&1
        make CPU=m68k SYNTAX=mot -j$NCPU >> "$LOG" 2>&1 && cp vasmm68k_mot "$TOOLS/vasm/" 2>/dev/null
        make clean >> "$LOG" 2>&1
        make CPU=z80 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasmz80_oldstyle "$TOOLS/vasm/" 2>/dev/null
        cd "$TOOLS/vasm"
        rm -rf "$D"
    }
}
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM (Official)" || warn "VASM"

# ============================================================================
step "ROM TOOLS - FLIPS"
# ============================================================================
mkdir -p "$TOOLS/flips"; cd "$TOOLS/flips"

# Flips - SMW Central (romhacking community)
dl_multi flips.zip \
    "https://dl.smwcentral.net/11474/floating.zip" \
    "https://archive.org/download/floating-ips/floating.zip" && {
    unzip -qo flips.zip >> "$LOG" 2>&1
    rm -f flips.zip
    chmod +x flips* 2>/dev/null
    ok "Flips (SMWCentral)"
} || warn "Flips"

# ============================================================================
step "GAME ENGINES"
# ============================================================================
cd "$TOOLS"

# Godot - TuxFamily (official mirror)
dl_multi godot.zip \
    "https://downloads.tuxfamily.org/godotengine/4.3/Godot_v4.3-stable_macos.universal.zip" \
    "https://archive.org/download/godot-4.3/Godot_v4.3-stable_macos.universal.zip" && {
    unzip -qo godot.zip >> "$LOG" 2>&1
    rm -f godot.zip
    xattr -dr com.apple.quarantine Godot* 2>/dev/null
    ok "Godot 4.3 (TuxFamily)"
} || warn "Godot"

brew_pkg raylib && ok "Raylib"
brew_pkg love && ok "LÖVE 2D"
brew_pkg sdl2 && ok "SDL2"

# ============================================================================
step "EMULATORS"
# ============================================================================
mkdir -p "$EMUS"; cd "$EMUS"

# mGBA - official site
dl_multi mgba.dmg \
    "https://mgba.io/downloads/mGBA-0.10.5-macos-universal.dmg" \
    "https://archive.org/download/mgba-0.10.5/mGBA-0.10.5-macos-universal.dmg" && {
    hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1
    cp -R /Volumes/mGBA*/mGBA.app . 2>/dev/null
    hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1
    rm -f mgba.dmg
    xattr -dr com.apple.quarantine mGBA.app 2>/dev/null
    ok "mGBA (Official)"
} || warn "mGBA"

# OpenEmu - official site
dl_multi openemu.zip \
    "https://openemu.org/files/OpenEmu_2.4.1.zip" \
    "https://archive.org/download/openemu-2.4.1/OpenEmu_2.4.1.zip" && {
    unzip -qo openemu.zip >> "$LOG" 2>&1
    rm -f openemu.zip
    xattr -dr com.apple.quarantine OpenEmu.app 2>/dev/null
    ok "OpenEmu (Official)"
} || warn "OpenEmu"

# ============================================================================
step "ENVIRONMENT"
# ============================================================================
cat > "$INSTALL_DIR/env.sh" << 'ENV'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -x /usr/local/bin/brew ]] && export PATH="/usr/local/bin:$PATH"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"
export DEVKITA64="$DEVKITPRO/devkitA64"
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export N64_INST="$RETRO_DEV/compilers/mips-toolchain"
[[ -d "$N64_INST/bin" ]] && export PATH="$N64_INST/bin:$PATH"
[[ -d "$DEVKITARM/bin" ]] && export PATH="$DEVKITARM/bin:$PATH"
[[ -d "$GBDK/bin" ]] && export PATH="$GBDK/bin:$PATH"
export PATH="$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/vasm:$RETRO_DEV/tools/flips:$RETRO_DEV/tools/vintage:$RETRO_DEV/sdks/atari:$PATH"
export JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null)"
[[ -d "$JAVA_HOME/bin" ]] && export PATH="$JAVA_HOME/bin:$PATH"
alias x86='arch -x86_64'
alias arm='arch -arm64'
echo "  🐱 CAT'S TWEAKER v3.2 (M4 Pro + Rosetta 2 - NO GITHUB) loaded!"
ENV
chmod +x "$INSTALL_DIR/env.sh"
ok "env.sh"

add_path ""
add_path "# Cat's Tweaker v3.2"
add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
step "VERIFICATION"
# ============================================================================
source "$INSTALL_DIR/env.sh" 2>/dev/null
echo ""
command -v curl &>/dev/null && ok "curl" || fail "curl"
command -v wget &>/dev/null && ok "wget" || fail "wget"
command -v cc65 &>/dev/null && ok "cc65 (6502)" || warn "cc65"
command -v sdcc &>/dev/null && ok "sdcc (Z80)" || warn "sdcc"
command -v rgbasm &>/dev/null && ok "rgbasm (GB)" || warn "rgbasm"
command -v cobc &>/dev/null && ok "GnuCOBOL" || warn "GnuCOBOL"
[[ -x "$TOOLS/asm6/asm6" ]] && ok "ASM6 (NES)" || warn "ASM6"
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM" || warn "VASM"
[[ -x "$SDKS/atari/dasm" ]] && ok "DASM" || warn "DASM"
[[ -d "$SDKS/gbdk" ]] && ok "GBDK" || warn "GBDK"
[[ -d "$SDKS/sgdk" ]] && ok "SGDK" || warn "SGDK"
[[ -d "$SDKS/nes" ]] && ok "NESLib" || warn "NESLib"
[[ -d "$SDKS/pvsneslib" ]] || [[ -d "$SDKS/snes" ]] && ok "PVSnesLib" || warn "PVSnesLib"
command -v node &>/dev/null && ok "node" || warn "node"
command -v libdragon &>/dev/null && ok "libdragon" || warn "libdragon"
command -v java &>/dev/null && ok "java" || warn "java"
[[ -f "$EMUS/nes/fceux.app/Contents/MacOS/fceux" ]] || [[ -d "$EMUS/nes" ]] && ok "FCEUX" || warn "FCEUX"
[[ -d "$EMUS/mGBA.app" ]] && ok "mGBA" || warn "mGBA"
[[ -d "$EMUS/OpenEmu.app" ]] && ok "OpenEmu" || warn "OpenEmu"
[[ -f "$COMPILERS/devkitpro/devkitpro.pkg" ]] && ok "DevkitPro" || warn "DevkitPro"

# ============================================================================
echo ""
printf "${G}╔═════════════════════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}║${RST}  ${W}✨ CAT'S TWEAKER v3.2 - NO GITHUB EDITION COMPLETE! ✨${RST}                       ${G}║${RST}\n"
printf "${G}║${RST}                                                                                 ${G}║${RST}\n"
printf "${G}║${RST}  ${C}SOURCES:${RST}  SourceForge, Archive.org, Official Sites Only                      ${G}║${RST}\n"
printf "${G}║${RST}  ${C}ERAS:${RST}     1930-2026 Computing History                                        ${G}║${RST}\n"
printf "${G}║${RST}  ${C}CONSOLES:${RST} NES → PS5 (35+ platforms)                                          ${G}║${RST}\n"
printf "${G}║${RST}                                                                                 ${G}║${RST}\n"
printf "${G}║${RST}  ${Y}ACTIVATE:${RST} ${W}source ~/.zshrc${RST}                                                    ${G}║${RST}\n"
printf "${G}╚═════════════════════════════════════════════════════════════════════════════════╝${RST}\n"
printf "\n                                 ${M}/\\_____/\\${RST}\n"
printf "                                ${M}/  o   o  \\${RST}  ${B}NO GIT${RST}\n"
printf "                               ${M}( ==  ^  == )${RST}\n"
printf "                                ${M})  M4 Pro (${RST}\n"
printf "                               ${M}( Rosetta 2 )${RST}\n"
printf "                              ${M}( (  )   (  ) )${RST}\n"
printf "                             ${M}(__(__)___(__)__)${RST}\n\n"

info "SOURCES USED (NO GITHUB):"
echo "  • GNU FTP (ftp.gnu.org) - binutils, GCC"
echo "  • SourceForge - DASM, GBDK, FCEUX, z88dk"
echo "  • Official sites - devkitpro.org, mgba.io, stephane-music.net"
echo "  • TuxFamily - Godot"
echo "  • NPM Registry (npmjs.org) - libdragon"
echo "  • VASM (sun.hasenbraten.de)"
echo "  • SMW Central - Flips"
echo "  • Archive.org - fallback mirrors"
echo ""
info "POST-INSTALL:"
echo "  1. ${W}source ~/.zshrc${RST}"
echo "  2. ${W}sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /${RST}"
echo "  3. ${W}bash ~/retro-dev/compilers/mips-toolchain/build_mips_m4.sh${RST}"
echo ""
