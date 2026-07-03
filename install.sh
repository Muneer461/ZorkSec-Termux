#!/data/data/com.termux/files/usr/bin/bash
#===============================================================================#
#                                                                               #
#                 ███████╗ ██████╗ ██████╗ ██╗  ██╗███████╗███████╗              #
#                 ╚══███╔╝██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝              #
#                   ███╔╝ ██║   ██║██████╔╝█████╔╝ ███████╗█████╗                #
#                  ███╔╝  ██║   ██║██╔══██╗██╔═██╗ ╚════██║██╔══╝                #
#                 ███████╗╚██████╔╝██║  ██║██║  ██╗███████║███████╗              #
#                 ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝              #
#                                                                               #
#              ZorkSec-Termux - Professional Cybersecurity Platform             #
#                                                                               #
#      Automated Installation • Management • Verification • Updates            #
#      200+ Cybersecurity Tools for Android (Termux)                            #
#                                                                               #
#  Author   : Mohammad Muneeruddin (Muneer461 / Zork)                           #
#  GitHub   : https://github.com/Muneer461                                      #
#  Project  : https://github.com/Muneer461/ZorkSec-Termux                       #
#  License  : MIT License                                                       #
#  Version  : 2.0.0                                                             #
#                                                                               #
#===============================================================================#

# ====================== SAFETY SETTINGS ======================
set -euo pipefail
IFS=$'\n\t'

# ====================== GLOBALS ======================
VERSION="2.0.0"
AUTHOR="Mohammad Muneeruddin (Muneer461 / Zork)"
REPO_URL="https://github.com/Muneer461/ZorkSec-Termux"
START_TIME=$(date +%s)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.zorksec"
TOOLS_DIR="${HOME}/zorksec-tools"
LOG_DIR="${SCRIPT_DIR}/logs"
BACKUP_DIR="${CONFIG_DIR}/backups"
PKG_DB="${CONFIG_DIR}/packages.db"
TOTAL_PACKAGES=0
INSTALLED_COUNT=0
SKIPPED_COUNT=0
UPDATED_COUNT=0
FAILED_COUNT=0
FAILED_TOOLS=""
ARCH=$(uname -m)
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")

# ====================== COLOR CODES ======================
R='\033[0m'; B='\033[1m'; D='\033[2m'; I='\033[3m'; U='\033[4m'
BL='\033[0;30m'; Rr='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; BLE='\033[0;34m'; M='\033[0;35m'; C='\033[0;36m'; W='\033[0;37m'
BGBL='\033[40m'; BGR='\033[41m'; BGG='\033[42m'; BGY='\033[43m'; BGBLE='\033[44m'; BGM='\033[45m'; BGC='\033[46m'; BGW='\033[47m'

# ====================== INITIALIZATION ======================
mkdir -p "${CONFIG_DIR}" "${TOOLS_DIR}" "${BACKUP_DIR}"
mkdir -p "${LOG_DIR}"
: > "${LOG_DIR}/install.log" 2>/dev/null || true
: > "${LOG_DIR}/errors.log" 2>/dev/null || true
: > "${LOG_DIR}/success.log" 2>/dev/null || true
: > "${PKG_DB}" 2>/dev/null || true

exec 3>>"${LOG_DIR}/install.log"
exec 4>>"${LOG_DIR}/errors.log"
exec 5>>"${LOG_DIR}/success.log"

# ====================== LOGGING FUNCTIONS ======================
log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >&3; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&4; echo -e "${Rr}[ERROR] $*${R}" >&2; }
log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $*" >&5; }

# ====================== UI FUNCTIONS ======================
banner() {
    clear
    echo -e "${B}${Rr}"
    echo '███████╗ ██████╗ ██████╗ ██╗  ██╗███████╗ ██████╗'
    echo '╚══███╔╝██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝'
    echo '  ███╔╝ ██║   ██║██████╔╝█████╔╝ ███████╗██║     '
    echo ' ███╔╝  ██║   ██║██╔══██╗██╔═██╗ ╚════██║██║     '
    echo '███████╗╚██████╔╝██║  ██║██║  ██╗███████║╚██████╗'
    echo '╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝'
    echo -e "${R}"
    echo -e "${B}${BLE}═══════════════════════════════════════════════════════════════${R}"
    echo -e "  ${B}${W}Termux Cybersecurity Platform v${VERSION}${R}"
    echo -e "  ${D}Author : ${AUTHOR}${R}"
    echo -e "  ${D}Arch   : ${ARCH} | Android: ${ANDROID_VER}${R}"
    echo -e "${B}${BLE}═══════════════════════════════════════════════════════════════${R}"
    echo ""
}

progress() {
    local cur=$1 total=$2
    local bar=40 pct=$((cur*100/total)) fill=$((cur*bar/total)) emp=$((bar-fill))
    local barstr=$(printf "%-${fill}s" "=" | tr ' ' '=')
    barstr="${barstr}$(printf "%-${emp}s" "" | tr ' ' ' ')"
    echo -ne "\r${C}[${barstr}]${R} ${B}${pct}%${R} (${cur}/${total}) "
}

confirm() {
    local prompt="${1:-Continue?}"
    read -r -p "$(echo -e "${Y}[?] ${prompt} [y/N]:${R} ")" yn
    case "${yn}" in [yY]*) return 0;; *) return 1;; esac
}

section() {
    echo ""; echo -e "${B}${BLE}┌─────────────────────────────────────────────────────────────┐${R}"
    printf "${B}${BLE}│${R} %-59s ${B}${BLE}│${R}\n" "$1"
    echo -e "${B}${BLE}└─────────────────────────────────────────────────────────────┘${R}"
}

sub() { echo -e "\n${B}${C}── $1${R}"; }

# ====================== CORE HELPERS ======================
check_termux() {
    if [ ! -d "${PREFIX:-/data/data/com.termux/files/usr}" ]; then
        echo -e "${Rr}[!] Must run inside Termux (Android).${R}"
        echo -e "${Y}[!] Download from: https://f-droid.org/packages/com.termux/${R}"
        exit 1
    fi
    log_info "Android ${ANDROID_VER} / ${ARCH}"
}

check_network() {
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1
}

check_storage() {
    local req=${1:-500}
    local avail=$(df "$HOME" 2>/dev/null | awk 'NR==2{print $4}')
    local mb=$((avail/1024))
    [ "$mb" -lt "$req" ] && echo -e "${Y}[!] Low storage: ${mb}MB free (${req}MB recommended)${R}" && return 1
    return 0
}

record_pkg() {
    local cat="$1" name="$2" status="$3"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|${cat}|${name}|${status}" >> "${PKG_DB}"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|${cat}|${name}|${status}" >> "${LOG_DIR}/packages.log"
}

update_stats() {
    case "$1" in
        installed) INSTALLED_COUNT=$((INSTALLED_COUNT+1)) ;;
        skipped)   SKIPPED_COUNT=$((SKIPPED_COUNT+1)) ;;
        updated)   UPDATED_COUNT=$((UPDATED_COUNT+1)) ;;
        failed)    FAILED_COUNT=$((FAILED_COUNT+1)); FAILED_TOOLS="${FAILED_TOOLS} $2" ;;
    esac
    TOTAL_PACKAGES=$((INSTALLED_COUNT+SKIPPED_COUNT+UPDATED_COUNT+FAILED_COUNT))
}

# ====================== INSTALLATION ENGINE ======================
pkg_inst() {
    local pkg=$1
    pkg list-installed 2>/dev/null | grep -q "^${pkg}$" && return 0
    echo -e "${C}[*] Installing package: ${pkg}${R}"
    pkg install -y "${pkg}" 2>/dev/null || { log_error "pkg install failed: ${pkg}"; return 1; }
    log_success "Installed: ${pkg}"; return 0
}

pip_inst() {
    local pkg=$1
    echo -e "${C}[*] Installing Python: ${pkg}${R}"
    pip3 install --upgrade "${pkg}" 2>/dev/null || pip install --upgrade "${pkg}" 2>/dev/null || { log_error "pip install failed: ${pkg}"; return 1; }
    log_success "Python installed: ${pkg}"; return 0
}

go_inst() {
    local pkg=$1 bin=${2:-}
    command -v go >/dev/null 2>&1 || pkg_inst "golang" || return 1
    echo -e "${C}[*] Installing Go: ${pkg}${R}"
    go install -v "${pkg}" 2>/dev/null || { log_error "Go install failed: ${pkg}"; return 1; }
    [ -n "$bin" ] && [ -f "${HOME}/go/bin/${bin}" ] && cp "${HOME}/go/bin/${bin}" "${PREFIX}/bin/" 2>/dev/null || true
    log_success "Go installed: ${pkg}"; return 0
}

cargo_inst() {
    local pkg=$1
    if ! command -v cargo >/dev/null 2>&1; then
        [ -f "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"
        command -v cargo >/dev/null 2>&1 || { pkg_inst "rust" || return 1; }
    fi
    echo -e "${C}[*] Installing Cargo: ${pkg}${R}"
    cargo install "${pkg}" 2>/dev/null || { log_error "Cargo install failed: ${pkg}"; return 1; }
    log_success "Cargo installed: ${pkg}"; return 0
}

gem_inst() {
    local pkg=$1
    echo -e "${C}[*] Installing Ruby gem: ${pkg}${R}"
    gem install "${pkg}" 2>/dev/null || { log_error "Gem install failed: ${pkg}"; return 1; }
    log_success "Gem installed: ${pkg}"; return 0
}

git_inst() {
    local url=$1 dir=$2
    if [ -d "${dir}/.git" ]; then
        echo -e "${C}[*] Updating: $(basename "${dir}")${R}"
        (cd "${dir}" && git pull --ff-only 2>/dev/null) && return 0
    fi
    echo -e "${C}[*] Cloning: $(basename "${dir}")${R}"
    git clone --depth 1 "${url}" "${dir}" 2>/dev/null || { log_error "Git clone failed: ${url}"; return 1; }
    # Auto-detect dependencies
    cd "${dir}"
    [ -f "requirements.txt" ] && (pip3 install -r requirements.txt 2>/dev/null || pip install -r requirements.txt 2>/dev/null || true)
    [ -f "setup.py" ] && (pip3 install -e . 2>/dev/null || true)
    [ -f "pyproject.toml" ] && (pip3 install -e . 2>/dev/null || true)
    [ -f "go.mod" ] && (go mod download 2>/dev/null || true)
    [ -f "Cargo.toml" ] && (cargo build --release 2>/dev/null && [ -f "target/release/$(basename "${dir}")" ] && cp "target/release/$(basename "${dir}")" "${PREFIX}/bin/" 2>/dev/null || true)
    [ -f "package.json" ] && (npm install 2>/dev/null || true)
    [ -f "Gemfile" ] && (bundle install 2>/dev/null || true)
    [ -f "Makefile" ] && (make 2>/dev/null && make install 2>/dev/null || true)
    [ -f "install.sh" ] && (chmod +x install.sh && bash install.sh 2>/dev/null || true)
    [ -f "setup.sh" ] && (chmod +x setup.sh && bash setup.sh 2>/dev/null || true)
    cd "${SCRIPT_DIR}"
    log_success "Cloned: $(basename "${dir}")"; return 0
}

verify_tool() {
    local tool=$1
    if command -v "${tool}" >/dev/null 2>&1; then
        local ver
        ver=$("${tool}" --version 2>/dev/null || "${tool}" -v 2>/dev/null || "${tool}" version 2>/dev/null || echo "")
        log_success "Verified: ${tool} ${ver%%$'\n'*}"
        return 0
    fi
    # Check in common locations
    for p in "${HOME}/go/bin/${tool}" "${TOOLS_DIR}"/*/"${tool}" "${TOOLS_DIR}"/*/"${tool}/${tool}" "${PREFIX}/bin/${tool}"; do
        [ -f "$p" ] && { chmod +x "$p" 2>/dev/null; ln -sf "$p" "${PREFIX}/bin/${tool}" 2>/dev/null; log_success "Linked: ${tool}"; return 0; }
    done
    log_error "Verification failed: ${tool} not found"
    return 1
}

# ====================== INSTALL SINGLE TOOL ======================
install_tool() {
    local tool=$1 category=$2
    local dir="${TOOLS_DIR}/${category}/${tool}"
    
    # Already installed check
    if command -v "${tool}" >/dev/null 2>&1; then
        echo -e "  ${G}[✓] Already available: ${tool}${R}"
        update_stats "skipped"; record_pkg "${category}" "${tool}" "skipped"; return 0
    fi
    
    echo -e "${C}[*] Installing: ${tool}${R}"
    
    case "${tool}" in
        # === INFORMATION GATHERING ===
        nmap)         pkg_inst "nmap" ;;
        rustscan)     cargo_inst "rustscan" || { echo -e "${Y}[!] Trying binary...${R}"; curl -sSfL "https://github.com/RustScan/RustScan/releases/latest/download/rustscan_amd64.deb" -o /tmp/rustscan.deb 2>/dev/null && dpkg -i /tmp/rustscan.deb 2>/dev/null || pkg_inst "rustscan" || true; } ;;
        masscan)      pkg_inst "masscan" ;;
        naabu)        go_inst "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" "naabu" ;;
        amass)        pkg_inst "amass" || go_inst "github.com/owasp-amass/amass/v4/...@master" "amass" ;;
        assetfinder)  go_inst "github.com/tomnomnom/assetfinder@latest" "assetfinder" ;;
        subfinder)    go_inst "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" "subfinder" ;;
        findomain)    cargo_inst "findomain" ;;
        bbot)         pip_inst "bbot" || git_inst "https://github.com/blacklanternsecurity/bbot.git" "${dir}" ;;
        theharvester) git_inst "https://github.com/laramies/theHarvester.git" "${dir}" ;;
        dnsx)         go_inst "github.com/projectdiscovery/dnsx/cmd/dnsx@latest" "dnsx" ;;
        dnsrecon)     git_inst "https://github.com/darkoperator/dnsrecon.git" "${dir}" && cd "${dir}" && pip3 install -r requirements.txt 2>/dev/null && cd "${SCRIPT_DIR}" && ln -sf "${dir}/dnsrecon" "${PREFIX}/bin/dnsrecon" 2>/dev/null || true ;;
        dnsenum)      pkg_inst "dnsenum" || git_inst "https://github.com/fwaeytens/dnsenum.git" "${dir}" ;;
        massdns)      git_inst "https://github.com/blechschmidt/massdns.git" "${dir}" && cd "${dir}" && make 2>/dev/null && cp bin/massdns "${PREFIX}/bin/" 2>/dev/null && cd "${SCRIPT_DIR}" ;;
        fierce)       pip_inst "fierce" || git_inst "https://github.com/mschwager/fierce.git" "${dir}" ;;
        httpx)        go_inst "github.com/projectdiscovery/httpx/cmd/httpx@latest" "httpx" ;;
        httprobe)     go_inst "github.com/tomnomnom/httprobe@latest" "httprobe" ;;
        katana)       go_inst "github.com/projectdiscovery/katana/cmd/katana@latest" "katana" ;;
        gau)          go_inst "github.com/lc/gau/v2/cmd/gau@latest" "gau" ;;
        waybackurls)  go_inst "github.com/tomnomnom/waybackurls@latest" "waybackurls" ;;
        hakrawler)    go_inst "github.com/hakluke/hakrawler@latest" "hakrawler" ;;
        # === OSINT ===
        sherlock)     git_inst "https://github.com/sherlock-project/sherlock.git" "${dir}" && (cd "${dir}" && pip3 install -r requirements.txt 2>/dev/null) && ln -sf "${dir}/sherlock" "${PREFIX}/bin/sherlock" 2>/dev/null || true ;;
        maigret)      pip_inst "maigret" || git_inst "https://github.com/soxoj/maigret.git" "${dir}" ;;
        phoneinfoga)  git_inst "https://github.com/sundowndev/phoneinfoga.git" "${dir}" && (cd "${dir}" && go build -o phoneinfoga 2>/dev/null && cp phoneinfoga "${PREFIX}/bin/" 2>/dev/null) || true ;;
        holehe)       pip_inst "holehe" || git_inst "https://github.com/megadose/holehe.git" "${dir}" ;;
        social-analyzer) git_inst "https://github.com/qeeqbox/social-analyzer.git" "${dir}" ;;
        ghunt)        git_inst "https://github.com/mxrch/GHunt.git" "${dir}" ;;
        # === WEB SECURITY ===
        ffuf)         go_inst "github.com/ffuf/ffuf/v2@latest" "ffuf" ;;
        gobuster)     go_inst "github.com/OJ/gobuster/v3@latest" "gobuster" ;;
        dirsearch)    git_inst "https://github.com/maurosoria/dirsearch.git" "${dir}" && ln -sf "${dir}/dirsearch.py" "${PREFIX}/bin/dirsearch" 2>/dev/null && chmod +x "${PREFIX}/bin/dirsearch" 2>/dev/null || true ;;
        feroxbuster)  cargo_inst "feroxbuster" ;;
        nikto)        pkg_inst "nikto" || git_inst "https://github.com/sullo/nikto.git" "${dir}" && ln -sf "${dir}/program/nikto.pl" "${PREFIX}/bin/nikto" 2>/dev/null || true ;;
        nuclei)       go_inst "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" "nuclei" && nuclei -update-templates 2>/dev/null || true ;;
        wpscan)       gem_inst "wpscan" ;;
        dalfox)       go_inst "github.com/hahwul/dalfox/v2@latest" "dalfox" ;;
        xsstrike)     git_inst "https://github.com/s0md3v/XSStrike.git" "${dir}" && (cd "${dir}" && pip3 install -r requirements.txt 2>/dev/null && ln -sf "${dir}/xsstrike.py" "${PREFIX}/bin/xsstrike" 2>/dev/null) || true ;;
        paramspider)  git_inst "https://github.com/devanshbatham/ParamSpider.git" "${dir}" && (cd "${dir}" && pip3 install -r requirements.txt 2>/dev/null) && ln -sf "${dir}/paramspider.py" "${PREFIX}/bin/paramspider" 2>/dev/null || true ;;
        arjun)        pip_inst "arjun" || git_inst "https://github.com/s0md3v/Arjun.git" "${dir}" ;;
        # === NETWORK ===
        tcpdump)      pkg_inst "tcpdump" ;;
        tshark)       pkg_inst "tshark" ;;
        termshark)    pkg_inst "termshark" || go_inst "github.com/gcla/termshark/v2/cmd/termshark@latest" "termshark" ;;
        netcat)       pkg_inst "netcat-openbsd" ;;
        socat)        pkg_inst "socat" ;;
        bettercap)    pkg_inst "root-repo" 2>/dev/null; pkg_inst "bettercap" || go_inst "github.com/bettercap/bettercap@latest" "bettercap" ;;
        # === WIRELESS ===
        aircrack-ng)  pkg_inst "aircrack-ng" || git_inst "https://github.com/aircrack-ng/aircrack-ng.git" "${dir}" ;;
        hcxdumptool)  pkg_inst "hcxdumptool" ;;
        reaver)       pkg_inst "reaver" ;;
        mdk4)         pkg_inst "mdk4" || pkg_inst "mdk3" || true ;;
        kismet)       pkg_inst "kismet" ;;
        wifite)       git_inst "https://github.com/derv82/wifite2.git" "${dir}" && ln -sf "${dir}/Wifite.py" "${PREFIX}/bin/wifite" 2>/dev/null || true ;;
        # === PASSWORD AUDITING ===
        john)         pkg_inst "john" ;;
        hashcat)      pkg_inst "hashcat" ;;
        hydra)        pkg_inst "hydra" ;;
        crunch)       pkg_inst "crunch" ;;
        cewl)         gem_inst "cewl" || git_inst "https://github.com/digininja/CeWL.git" "${dir}" && (cd "${dir}" && gem build cewl.gemspec 2>/dev/null && gem install cewl*.gem 2>/dev/null) || true ;;
        hash-identifier) git_inst "https://github.com/psypanda/hashID.git" "${dir}" && ln -sf "${dir}/hashid.py" "${PREFIX}/bin/hashid" 2>/dev/null || true ;;
        # === EXPLOITATION ===
        metasploit)   cabal_install_metasploit ;;
        sqlmap)       git_inst "https://github.com/sqlmapproject/sqlmap.git" "${dir}" && ln -sf "${dir}/sqlmap.py" "${PREFIX}/bin/sqlmap" 2>/dev/null || true ;;
        commix)       git_inst "https://github.com/commixproject/commix.git" "${dir}" && ln -sf "${dir}/commix.py" "${PREFIX}/bin/commix" 2>/dev/null || true ;;
        searchsploit) pkg_inst "exploitdb" ;;
        beef)         git_inst "https://github.com/beefproject/beef.git" "${dir}" && (cd "${dir}" && ./install 2>/dev/null || true) && ln -sf "${dir}/beef" "${PREFIX}/bin/beef" 2>/dev/null || true ;;
        yersinia)     pkg_inst "yersinia" ;;
        setoolkit)    git_inst "https://github.com/trustedsec/social-engineer-toolkit.git" "${dir}" && (cd "${dir}" && pip3 install -r requirements.txt 2>/dev/null && python setup.py 2>/dev/null) && ln -sf "${dir}/setoolkit" "${PREFIX}/bin/setoolkit" 2>/dev/null || true ;;
        # === POST EXPLOITATION ===
        empire)       git_inst "https://github.com/BC-SECURITY/Empire.git" "${dir}" && (cd "${dir}" && pip3 install -r requirements.txt 2>/dev/null && python setup.py 2>/dev/null) || true ;;
        pwncat)       pip_inst "pwncat-cs" || pip_inst "pwncat" || true ;;
        chisel)       go_inst "github.com/jpillora/chisel@latest" "chisel" ;;
        ligolo-ng)    go_inst "github.com/nicocha30/ligolo-ng/cmd/ligolo-agent@latest" "ligolo-agent" && go_inst "github.com/nicocha30/ligolo-ng/cmd/ligolo-proxy@latest" "ligolo-proxy" ;;
        # === REVERSE ENGINEERING ===
        radare2)      command -v r2 >/dev/null 2>&1 || { git clone --depth 1 "https://github.com/radareorg/radare2" "${dir}" 2>/dev/null && cd "${dir}" && bash sys/termux.sh 2>/dev/null; } || pkg_inst "radare2" || true; cd "${SCRIPT_DIR}" ;;
        strings)      pkg_inst "binutils" ;;
        binwalk)      git_inst "https://github.com/ReFirmLabs/binwalk.git" "${dir}" && (cd "${dir}" && pip3 install -r requirements.txt 2>/dev/null && python setup.py install 2>/dev/null) || true ;;
        apktool)      pkg_inst "apktool" ;;
        jadx)         git_inst "https://github.com/skylot/jadx.git" "${dir}" && (cd "${dir}" && ./gradlew dist 2>/dev/null) || true ;;
        # === MALWARE ANALYSIS / FORENSICS ===
        clamav)       pkg_inst "clamav" ;;
        volatility)   git_inst "https://github.com/volatilityfoundation/volatility3.git" "${dir}" && ln -sf "${dir}/vol.py" "${PREFIX}/bin/volatility" 2>/dev/null && chmod +x "${PREFIX}/bin/volatility" 2>/dev/null || true ;;
        yara)         pkg_inst "yara" ;;
        exiftool)     pkg_inst "exiftool" ;;
        foremost)     pkg_inst "foremost" ;;
        sleuthkit)    pkg_inst "sleuthkit" ;;
        # === THREAT INTEL ===
        sigma)        git_inst "https://github.com/SigmaHQ/sigma.git" "${dir}" ;;
        misp-client)  pip_inst "pymisp" || git_inst "https://github.com/MISP/MISP.git" "${dir}" ;;
        # === ADDITIONAL ATTACK TOOLS ===
        mitmproxy)    pip_inst "mitmproxy" || true ;;
        ettercap)     pkg_inst "ettercap" ;;
        dnsspoof)     pkg_inst "dsniff" ;;
        macchanger)   pkg_inst "macchanger" ;;
        medusa)       pkg_inst "medusa" ;;
        ncrack)       git_inst "https://github.com/nmap/ncrack.git" "${dir}" && (cd "${dir}" && ./configure 2>/dev/null && make 2>/dev/null && cp ncrack "${PREFIX}/bin/" 2>/dev/null) || true ;;
        patator)      pip_inst "patator" || git_inst "https://github.com/lanjelot/patator.git" "${dir}" ;;
        # === UTILITIES ===
        git)          command -v git >/dev/null 2>&1 || pkg_inst "git" ;;
        curl)         command -v curl >/dev/null 2>&1 || pkg_inst "curl" ;;
        wget)         command -v wget >/dev/null 2>&1 || pkg_inst "wget" ;;
        nano)         command -v nano >/dev/null 2>&1 || pkg_inst "nano" ;;
        vim)          command -v vim >/dev/null 2>&1 || pkg_inst "vim" ;;
        tmux)         pkg_inst "tmux" ;;
        tree)         pkg_inst "tree" ;;
        zip)          pkg_inst "zip" ;;
        unzip)        pkg_inst "unzip" ;;
        # === FALLBACK ===
        *)            pkg_inst "${tool}" || pip_inst "${tool}" || { echo -e "${Y}[!] Trying git clone...${R}"; git_inst "https://github.com/search?q=${tool}" "${dir}" 2>/dev/null || true; } ;;
    esac
    
    local result=$?
    if [ $result -eq 0 ]; then
        verify_tool "${tool}" || true
        update_stats "installed"; record_pkg "${category}" "${tool}" "installed"
        echo -e "  ${G}[✓] ${tool} installed successfully!${R}"
    else
        update_stats "failed" "${tool}"; record_pkg "${category}" "${tool}" "failed"
        echo -e "  ${Rr}[✗] ${tool} installation FAILED${R}"
    fi
    return $result
}

cabal_install_metasploit() {
    if command -v msfconsole >/dev/null 2>&1; then echo -e "  ${G}[✓] Metasploit already installed${R}"; return 0; fi
    echo -e "${Y}[!] Metasploit requires ~500MB+ and takes time${R}"
    confirm "Install Metasploit?" || return 1
    echo -e "${C}[*] Downloading Metasploit installer...${R}"
    mkdir -p "${TOOLS_DIR}/exploitation"
    cd "${TOOLS_DIR}/exploitation"
    curl -fsSL "https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh" -o metasploit_install.sh
    chmod +x metasploit_install.sh
    bash metasploit_install.sh 2>/dev/null || { echo -e "${Y}[!] Trying pkg...${R}"; pkg_inst "metasploit" 2>/dev/null || true; }
    cd "${SCRIPT_DIR}"
    command -v msfconsole >/dev/null 2>&1 && log_success "Metasploit installed" && return 0
    return 1
}

# ====================== SUBMENU SYSTEM ======================
# Each submenu has: 0) Back to Main  1) Install All Category  2+) Individual tools

submenu_info_gathering() {
    local tools=(nmap rustscan masscan naabu amass assetfinder subfinder findomain bbot theharvester dnsx dnsrecon dnsenum massdns fierce httpx httprobe katana gau waybackurls hakrawler)
    while true; do
        section "INFORMATION GATHERING TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Information Gathering Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/InfoGathering]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "information-gathering"; done ;;
            *) 
                if [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -ge 1 ] && [ "$ch" -le "${#tools[@]}" ]; then
                    install_tool "${tools[$((ch-1))]}" "information-gathering"
                fi
                ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_osint() {
    local tools=(sherlock maigret phoneinfoga holehe social-analyzer ghunt)
    while true; do
        section "OSINT TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL OSINT Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/OSINT]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "osint"; done ;;
            *) 
                if [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -ge 1 ] && [ "$ch" -le "${#tools[@]}" ]; then
                    install_tool "${tools[$((ch-1))]}" "osint"
                fi
                ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_subdomain() {
    local tools=(subfinder assetfinder findomain amass dnsx httpx httprobe)
    while true; do
        section "SUBDOMAIN ENUMERATION TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Subdomain Enumeration Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Subdomain]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "subdomain"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "subdomain" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_dns() {
    local tools=(dnsx dnsrecon dnsenum massdns fierce)
    while true; do
        section "DNS TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL DNS Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/DNS]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "dns"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "dns" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_web() {
    local tools=(ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun)
    while true; do
        section "WEB APPLICATION SECURITY TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Web Security Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/WebSec]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "web-security"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "web-security" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_network() {
    local tools=(tcpdump tshark termshark netcat socat bettercap nmap masscan)
    while true; do
        section "NETWORK TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Network Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Network]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "network"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "network" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_wireless() {
    local tools=(aircrack-ng hcxdumptool reaver mdk4 kismet wifite)
    while true; do
        section "WIRELESS SECURITY TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Wireless Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Wireless]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "wireless"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "wireless" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_password() {
    local tools=(john hashcat hydra crunch cewl hash-identifier medusa ncrack patator)
    while true; do
        section "PASSWORD AUDITING TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Password Auditing Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Password]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "password-auditing"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "password-auditing" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_exploit() {
    local tools=(metasploit sqlmap commix searchsploit beef yersinia setoolkit)
    while true; do
        section "EXPLOITATION TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Exploitation Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Exploitation]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "exploitation"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "exploitation" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_postexploit() {
    local tools=(empire pwncat chisel ligolo-ng)
    while true; do
        section "POST EXPLOITATION TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Post Exploitation Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/PostExploit]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "post-exploitation"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "post-exploitation" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_reverse() {
    local tools=(radare2 strings binwalk apktool jadx)
    while true; do
        section "REVERSE ENGINEERING TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Reverse Engineering Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/ReverseEng]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "reverse-engineering"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "reverse-engineering" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_malware() {
    local tools=(clamav radare2 strings yara)
    while true; do
        section "MALWARE ANALYSIS TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Malware Analysis Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Malware]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "malware-analysis"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "malware-analysis" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_forensics() {
    local tools=(volatility yara exiftool foremost sleuthkit binwalk)
    while true; do
        section "DIGITAL FORENSICS TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Forensics Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Forensics]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "forensics"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "forensics" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_threat() {
    local tools=(yara sigma misp-client)
    while true; do
        section "THREAT INTELLIGENCE TOOLS"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Threat Intel Tools"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/ThreatIntel]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "threat-intel"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "threat-intel" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_utilities() {
    local tools=(git curl wget nano vim tmux tree zip unzip python go nodejs ruby)
    while true; do
        section "UTILITIES"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Utilities"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Utilities]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "utilities"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "utilities" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

submenu_additional_attacks() {
    local tools=(mitmproxy ettercap dnsspoof macchanger hydra medusa ncrack patator setoolkit beef yersinia)
    while true; do
        section "ADDITIONAL ATTACK TOOLS (Phishing, MITM, Brute Force)"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL Additional Attack Tools"
        echo ""
        echo -e "  ${D}Includes: Phishing (SET), MITM (ettercap, mitmproxy),${R}"
        echo -e "  ${D}Brute Force (hydra, medusa, ncrack, patator), Spoofing${R}"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/AttackTools]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A) for t in "${tools[@]}"; do install_tool "$t" "attack-tools"; done ;;
            *) [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#tools[@]}" ] && install_tool "${tools[$((ch-1))]}" "attack-tools" ;;
        esac
        echo ""; read -r -p "Press Enter to continue..." 
    done
}

# ====================== INSTALL EVERYTHING ======================
install_everything() {
    section "FULL INSTALLATION — ALL TOOLS"
    echo -e "${Y}[!] This will install ALL ~200+ cybersecurity tools${R}"
    echo -e "${Y}[!] Requires 2-5GB storage and 30-90 minutes${R}"
    confirm "Proceed with full installation?" || return
    
    check_network || { echo -e "${Rr}[!] Network required.${R}"; return; }
    check_storage 2000 || { confirm "Low storage. Continue?" || return; }
    
    # Install prerequisites first
    sub "Installing core prerequisites"
    pkg update -y 2>/dev/null || true; pkg upgrade -y 2>/dev/null || true
    for p in git curl wget python python3 golang rust nodejs ruby make clang cmake; do
        command -v "$p" >/dev/null 2>&1 || pkg_inst "$p" || true
    done
    
    # Install all categories
    for t in nmap rustscan masscan naabu amass assetfinder subfinder findomain bbot theharvester dnsx dnsrecon dnsenum massdns fierce httpx httprobe katana gau waybackurls hakrawler; do install_tool "$t" "information-gathering"; done
    for t in sherlock maigret phoneinfoga holehe social-analyzer ghunt; do install_tool "$t" "osint"; done
    for t in ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun; do install_tool "$t" "web-security"; done
    for t in tcpdump tshark termshark netcat socat bettercap; do install_tool "$t" "network"; done
    for t in aircrack-ng hcxdumptool reaver mdk4 kismet wifite; do install_tool "$t" "wireless"; done
    for t in john hashcat hydra crunch cewl hash-identifier medusa ncrack patator; do install_tool "$t" "password-auditing"; done
    for t in metasploit sqlmap commix searchsploit beef yersinia setoolkit; do install_tool "$t" "exploitation"; done
    for t in empire pwncat chisel ligolo-ng; do install_tool "$t" "post-exploitation"; done
    for t in radare2 strings binwalk apktool jadx; do install_tool "$t" "reverse-engineering"; done
    for t in clamav volatility yara exiftool foremost sleuthkit; do install_tool "$t" "forensics"; done
    for t in sigma misp-client; do install_tool "$t" "threat-intel"; done
    for t in mitmproxy ettercap dnsspoof macchanger; do install_tool "$t" "attack-tools"; done
    
    echo -e "\n${B}${G}═══════════════════════════════════════════════════════════════${R}"
    echo -e "${B}${G}           FULL INSTALLATION COMPLETE!                          ${R}"
    echo -e "${B}${G}═══════════════════════════════════════════════════════════════${R}"
    show_summary
}

# ====================== UPDATE / REPAIR / HEALTH ======================

update_all() {
    section "UPDATE ALL INSTALLED TOOLS"

    pkg update -y 2>/dev/null || true
    pkg upgrade -y 2>/dev/null || true

    if command -v go >/dev/null 2>&1; then
        echo -e "${C}[*] Updating Go tools...${R}"

        for p in \
            "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" \
            "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" \
            "github.com/projectdiscovery/httpx/cmd/httpx@latest" \
            "github.com/projectdiscovery/dnsx/cmd/dnsx@latest" \
            "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" \
            "github.com/projectdiscovery/katana/cmd/katana@latest" \
            "github.com/tomnomnom/assetfinder@latest" \
            "github.com/tomnomnom/httprobe@latest" \
            "github.com/tomnomnom/waybackurls@latest" \
            "github.com/ffuf/ffuf/v2@latest" \
            "github.com/OJ/gobuster/v3@latest" \
            "github.com/hahwul/dalfox/v2@latest" \
            "github.com/lc/gau/v2/cmd/gau@latest" \
            "github.com/hakluke/hakrawler@latest" \
            "github.com/bettercap/bettercap@latest"
        do
            echo -e "${C}[*] ${p}${R}"
            GO111MODULE=on go install -v "$p" 2>/dev/null || true
        done
    fi

    if command -v cargo >/dev/null 2>&1; then
        echo -e "${C}[*] Updating Rust tools...${R}"

        for p in rustscan feroxbuster findomain
        do
            cargo install "$p" 2>/dev/null || true
        done
    fi

    command -v nuclei >/dev/null 2>&1 && nuclei -update-templates 2>/dev/null || true

    find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | while read -r gd
    do
        rd="$(dirname "$gd")"

        echo -e "${C}[*] Git: $(basename "$rd")${R}"

        (
            cd "$rd" || exit
            git pull --ff-only
        ) 2>/dev/null || true
    done

    echo -e "${G}[✓] Update complete${R}"
}

repair_broken() {
    section "REPAIR BROKEN PACKAGES"

    pkg install -y termux-tools 2>/dev/null || true
    apt --fix-broken install -y 2>/dev/null || true
    python3 -m pip install --upgrade pip 2>/dev/null || true

    if [ -f "${PKG_DB}" ]; then
        while IFS='|' read -r ts category name status
        do
            [ "$status" = "installed" ] || continue

            if ! command -v "$name" >/dev/null 2>&1; then
                echo -e "${Y}[!] Re-installing broken: ${name}${R}"
                install_tool "$name" "$category" || true
            fi

        done < "${PKG_DB}"
    fi

    echo -e "${G}[✓] Repair process complete${R}"
}

health_check() {

    section "SYSTEM HEALTH CHECK"

    local issues=0

    # 1. Storage
    local avail
    avail=$(df "$HOME" 2>/dev/null | awk 'NR==2{print $4}')
    avail=${avail:-0}

    local mb=$((avail / 1024))

    echo -e "  ${B}[1] Storage:${R} ${mb}MB available"

    if [ "$mb" -lt 500 ]; then
        echo -e "    ${Rr}✗ LOW STORAGE${R}"
        issues=$((issues + 1))
    else
        echo -e "    ${G}✓ OK${R}"
    fi

    # 2. Network
    echo -e "  ${B}[2] Network:${R}"

    if check_network; then
        echo -e "    ${G}✓ Connected${R}"
    else
        echo -e "    ${Y}⚠ Offline${R}"
        issues=$((issues + 1))
    fi

    # 3. Core Packages
    echo -e "  ${B}[3] Core Packages:${R}"

    for p in git curl wget python3 nmap
    do
        if command -v "$p" >/dev/null 2>&1; then
            echo -e "    ${G}✓ ${p}${R}"
        else
            echo -e "    ${Rr}✗ ${p} MISSING${R}"
            issues=$((issues + 1))
        fi
    done

    # 4. Language Runtimes
    echo -e "  ${B}[4] Language Runtimes:${R}"

    for r in go python3 node ruby cargo
    do
        if command -v "$r" >/dev/null 2>&1; then
            echo -e "    ${G}✓ ${r}${R}"
        else
            echo -e "    ${Y}⚠ ${r} not installed${R}"
        fi
    done

    # 5. Installed Tools Verification
    echo -e "  ${B}[5] Installed Tools Verification:${R}"

    local verified=0
    local failed=0

    if [ -f "${PKG_DB}" ]; then
        while IFS='|' read -r ts category name status
        do
            [ "$status" = "installed" ] || continue

            if command -v "$name" >/dev/null 2>&1; then
                verified=$((verified + 1))
            else
                failed=$((failed + 1))
                echo -e "    ${Y}⚠ ${name} (${category}) - binary not found${R}"
            fi

        done < "${PKG_DB}"
    fi

    echo -e "    ${G}✓ ${verified} verified${R}   ${Y}${failed} missing${R}"

    # 6. Storage Usage
    echo -e "  ${B}[6] Storage Usage:${R}"

    [ -d "${TOOLS_DIR}" ] && du -sh "${TOOLS_DIR}" 2>/dev/null | awk '{print "    Tools : " $1}'
    [ -d "${LOG_DIR}" ] && du -sh "${LOG_DIR}" 2>/dev/null | awk '{print "    Logs  : " $1}'

    # 7. PATH Check
    echo -e "  ${B}[7] PATH Sanity:${R}"

    local path_ok=0

    for d in \
        "${HOME}/go/bin" \
        "${HOME}/.cargo/bin" \
        "${HOME}/.local/bin" \
        "${PREFIX}/bin"
    do
        echo "$PATH" | grep -Fq "$d" && path_ok=$((path_ok + 1))
    done

    echo -e "    ${G}✓ PATH contains ${path_ok}/4 standard directories${R}"

    echo

    if [ "$issues" -eq 0 ]; then
        echo -e "${G}✓ All health checks passed!${R}"
    else
        echo -e "${Y}⚠ ${issues} issue(s) found. Run 'Repair Broken Packages' from the menu.${R}"
    fi
}
# ====================== REPOSITORY MANAGER ======================
repo_manager() {
    while true; do
        section "REPOSITORY MANAGER"
        echo -e "  ${B}${G}1${R}  List all cloned repositories"
        echo -e "  ${B}${G}2${R}  Update all repositories"
        echo -e "  ${B}${G}3${R}  Delete a repository"
        echo -e "  ${B}${G}4${R}  Show repository sizes"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/RepoMgr]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            1) echo ""; find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | while read -r gd; do echo "  $(dirname "$gd")" | sed "s|${TOOLS_DIR}/||"; done | sort ;;
            2) find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | while read -r gd; do
                rd=$(dirname "$gd"); echo -e "${C}[*] $(basename "$rd")${R}"
                (cd "$rd" && git pull --ff-only 2>/dev/null) || echo -e "  ${Y}⚠ Failed${R}"
               done ;;
            3) echo ""; local i=1; local -a repos=()
               while IFS= read -r gd; do
                   rd=$(dirname "$gd"); repos+=("$rd")
                   echo "  $i) $(echo "$rd" | sed "s|${TOOLS_DIR}/||")"
                   i=$((i+1))
               done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null)
               echo ""; read -r -p "Enter number to delete: " dn
               if [[ "$dn" =~ ^[0-9]+$ ]] && [ "$dn" -le "${#repos[@]}" ]; then
                   confirm "Delete $(basename "${repos[$((dn-1))]}")?" && rm -rf "${repos[$((dn-1))]}" && echo -e "${G}✓ Deleted${R}"
               fi ;;
            4) echo ""; du -sh "${TOOLS_DIR}"/*/ 2>/dev/null | sort -rh | head -20 ;;
        esac
        echo ""; read -r -p "Press Enter to continue..."
    done
}

# ====================== SHOW INSTALLED ======================
show_installed() {
    section "INSTALLED TOOLS"
    [ ! -f "${PKG_DB}" ] && echo -e "${Y}[!] No installation records${R}" && return
    echo -e "${D}────────────────────────────────────────────────────────${R}"
    local cat=""
    while IFS='|' read -r ts c n s; do
        [ "$c" != "$cat" ] && echo "" && echo -e "${B}${BLE}► ${c}${R}" && cat="$c"
        local scolor="${G}"; [ "$s" = "failed" ] && scolor="${Rr}"; [ "$s" = "skipped" ] && scolor="${Y}"
        printf "  %-18s ${scolor}%-10s${R}\n" "$n" "$s"
    done < "${PKG_DB}"
    echo ""; echo -e "${D}Total: $(wc -l < "${PKG_DB}") records${R}"
}

# ====================== BACKUP / RESTORE ======================
backup_config() {
    section "BACKUP CONFIGURATION"
    local bk="${BACKUP_DIR}/zorksec-backup-$(date '+%Y%m%d-%H%M%S').tar.gz"
    tar -czf "$bk" -C "${CONFIG_DIR}" . 2>/dev/null && echo -e "${G}✓ Backup saved: ${bk}${R}" || echo -e "${Rr}✗ Backup failed${R}"
}

restore_config() {
    section "RESTORE CONFIGURATION"
    local backups=($(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null))
    [ ${#backups[@]} -eq 0 ] && echo -e "${Y}[!] No backups found${R}" && return
    local i=1
    for b in "${backups[@]}"; do echo "  $i) $(basename "$b")"; i=$((i+1)); done
    echo ""; read -r -p "Select backup to restore: " ch
    [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#backups[@]}" ] && {
        tar -xzf "${backups[$((ch-1))]}" -C "${CONFIG_DIR}" 2>/dev/null
        echo -e "${G}✓ Restored from: $(basename "${backups[$((ch-1))]}")${R}"
    }
}

# ====================== ABOUT ======================
about() {
    section "ABOUT ZORKSEC-TERMUX"
    echo -e "  ${B}Version:${R}      ${VERSION}"
    echo -e "  ${B}Author:${R}       ${AUTHOR}"
    echo -e "  ${B}Platform:${R}     Termux (Android 10+ / ARM64 / ARM / x86_64)"
    echo -e "  ${B}Repository:${R}   ${REPO_URL}"
    echo -e "  ${B}License:${R}      MIT"
    echo ""
    echo -e "  ${D}ZorkSec-Termux is a professional open-source cybersecurity${R}"
    echo -e "  ${D}platform for Android/Termux. It automates installation,${R}"
    echo -e "  ${D}management, verification, updating, and execution of${R}"
    echo -e "  ${D}200+ cybersecurity tools.${R}"
    echo ""
    echo -e "  ${B}Features:${R}"
    echo -e "   • One-click installation of all tools"
    echo -e "   • Categorized menus with Install-All or per-tool selection"
    echo -e "   • Automatic dependency resolution (pip, go, cargo, npm, gem)"
    echo -e "   • Tool verification after every installation"
    echo -e "   • Automatic repair of failed/broken packages"
    echo -e "   • Comprehensive logging and health checks"
    echo -e "   • Backup & restore configuration"
    echo -e "   • Tools available directly from your Termux terminal"
}

# ====================== SUMMARY ======================
show_summary() {
    local end=$(date +%s); local dur=$((end-START_TIME))
    local stor=$(du -sh "${TOOLS_DIR}" 2>/dev/null | awk '{print $1}' || echo "0B")
    echo ""
    echo -e "${B}${C}═══════════════════ INSTALLATION SUMMARY ═══════════════════${R}"
    echo -e " ${B}Total:${R}       ${TOTAL_PACKAGES}"
    echo -e " ${G}✓ Installed:${R} ${INSTALLED_COUNT}"
    echo -e " ${Y}⚠ Skipped:${R}   ${SKIPPED_COUNT}"
    echo -e " ${BLE}↻ Updated:${R}   ${UPDATED_COUNT}"
    echo -e " ${Rr}✗ Failed:${R}     ${FAILED_COUNT}"
    [ -n "$FAILED_TOOLS" ] && echo -e " ${Rr}Failed:${R}     ${FAILED_TOOLS}"
    echo -e " ${D}Time:${R}        $((dur/60))m $((dur%60))s"
    echo -e " ${D}Storage:${R}     ${stor}"
    echo -e " ${D}Logs:${R}        ${LOG_DIR}/"
    echo -e "${B}${C}═══════════════════════════════════════════════════════════${R}"
}

# ====================== EXIT HANDLER ======================
cleanup() {
    echo -e "\n${Y}[!] Interrupted.${R}"
    show_summary; exit 1
}
trap cleanup SIGINT SIGTERM

# ====================== MAIN MENU ======================
main_menu() {
    while true; do
        banner
        echo -e "${B}${BLE}┌───────────────────── MAIN MENU ─────────────────────┐${R}"
        echo -e "${B}${BLE}│${R} ${G} 1${R}  Install Everything                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 2${R}  Information Gathering                  ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 3${R}  OSINT                                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 4${R}  Subdomain Enumeration                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 5${R}  DNS Tools                             ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 6${R}  Web Application Security              ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 7${R}  Network Tools                         ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 8${R}  Wireless Security                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 9${R}  Password Auditing                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}10${R}  Exploitation                          ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}11${R}  Post Exploitation                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}12${R}  Reverse Engineering                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}13${R}  Malware Analysis                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}14${R}  Digital Forensics                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}15${R}  Threat Intelligence                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}16${R}  Utilities                             ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Y}17${R}  Update Installed Tools                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Y}18${R}  Repair Broken Packages                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}19${R}  Installed Tools List                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}20${R}  System Health Check                    ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}21${R}  Repository Manager                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${M}22${R}  Additional Attack Tools (Phishing,MITM)${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${M}23${R}  Backup Configuration                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${M}24${R}  Restore Configuration                  ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${W}25${R}  About                                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Rr}26${R}  Exit                                  ${B}${BLE}│${R}"
        echo -e "${B}${BLE}└────────────────────────────────────────────────────┘${R}"
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec]${R} Select [1-26]: ")" ch
        case "$ch" in
            1)  install_everything ;;
            2)  submenu_info_gathering ;;
            3)  submenu_osint ;;
            4)  submenu_subdomain ;;
            5)  submenu_dns ;;
            6)  submenu_web ;;
            7)  submenu_network ;;
            8)  submenu_wireless ;;
            9)  submenu_password ;;
            10) submenu_exploit ;;
            11) submenu_postexploit ;;
            12) submenu_reverse ;;
            13) submenu_malware ;;
            14) submenu_forensics ;;
            15) submenu_threat ;;
            16) submenu_utilities ;;
            17) update_all ;;
            18) repair_broken ;;
            19) show_installed ;;
            20) health_check ;;
            21) repo_manager ;;
            22) submenu_additional_attacks ;;
            23) backup_config ;;
            24) restore_config ;;
            25) about ;;
            26) echo -e "${G}[✓] Thank you for using ZorkSec-Termux!${R}"; show_summary; exit 0 ;;
            *) echo -e "${Rr}[!] Invalid${R}"; sleep 1 ;;
        esac
        echo ""; read -r -p "Press Enter to return to menu..."
    done
}

# ====================== ENTRY POINT ======================
check_termux
main_menu

