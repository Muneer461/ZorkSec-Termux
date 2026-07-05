#!/data/data/com.termux/files/usr/bin/bash
#==============================================================================#
#                                                                              #
#                 ███████╗ ██████╗ ██████╗ ██╗  ██╗███████╗ ██████╗            #
#                 ╚══███╔╝██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝            #
#                   ███╔╝ ██║   ██║██████╔╝█████╔╝ █████╗  ██║                 #
#                  ███╔╝  ██║   ██║██╔══██╗██╔═██╗ ██╔══╝  ██║                 #
#                 ███████╗╚██████╔╝██║  ██║██║  ██╗███████╗╚██████╗            #
#                 ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝            #
#                                                                              #
#     ███████╗ ██████╗ ██████╗ ██╗  ██╗███████╗ ██████╗                       #
#     ██╔════╝██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝                       #
#     ███████╗██║   ██║██████╔╝█████╔╝ █████╗  ██║                            #
#     ╚════██║██║   ██║██╔══██╗██╔═██╗ ██╔══╝  ██║                            #
#     ███████║╚██████╔╝██║  ██║██║  ██╗███████╗╚██████╗                       #
#     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝                       #
#                                                                              #
#     ZorkSec-Termux v2.0                                                      #
#     Professional Cybersecurity Toolkit for Android Termux                    #
#                                                                              #
#     ▸ 200+ tools cloned from official GitHub repos                          #
#     ▸ ~/zorksec-tools/XX-Category/ToolName/ structure                       #
#     ▸ Symlinks for global terminal access                                   #
#     ▸ First: install ALL Termux base packages                               #
#     ▸ Resume-capable installation — safe to interrupt                       #
#                                                                              #
#     Author : Mohammad Muneeruddin                                            #
#     GitHub : https://github.com/Muneer461/ZorkSec-Termux                    #
#                                                                              #
#==============================================================================#

# ===================================================================
# SAFETY: NO set -e or set -u!
# -e kills script on ANY error (like git clone existing dir)
# -u breaks read/select on empty input
# We handle errors manually throughout.
# ===================================================================
set +o errexit
set +o nounset
set -o pipefail  # pipefail is safe — it doesn't exit, just sets $?

# ===================================================================
# GLOBAL VARIABLES
# ===================================================================
VERSION="2.0.0"
AUTHOR="Mohammad Muneeruddin (Muneer461)"
START_TIME=$(date +%s)
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
TOOLS_DIR="${HOME_DIR}/zorksec-tools"
CONFIG_DIR="${HOME_DIR}/.zorksec"
LOG_DIR="${CONFIG_DIR}/logs"
BACKUP_DIR="${CONFIG_DIR}/backups"
PKG_DB="${CONFIG_DIR}/packages.db"
REPO_URL="https://github.com/Muneer461/ZorkSec-Termux"

# Default values
FAILED_COUNT=0
INSTALLED_COUNT=0
SKIPPED_COUNT=0
UPDATED_COUNT=0
TOTAL_PACKAGES=0
FAILED_TOOLS=""

# ===================================================================
# COLOR CODES
# ===================================================================
R='\033[0m'          # Reset
B='\033[1m'          # Bold
D='\033[2m'          # Dim
I='\033[3m'          # Italic
U='\033[4m'          # Underline
Rr='\033[0;31m'      # Red
G='\033[0;32m'       # Green
Y='\033[0;33m'       # Yellow
BLE='\033[0;34m'     # Blue
M='\033[0;35m'       # Magenta
C='\033[0;36m'       # Cyan
W='\033[0;37m'       # White
BG_R='\033[41m'      # Background Red
BG_G='\033[42m'      # Background Green
BG_B='\033[44m'      # Background Blue

# ===================================================================
# INITIALIZE DIRECTORIES
# ===================================================================
init_dirs() {
    mkdir -p "${CONFIG_DIR}" 2>/dev/null || true
    mkdir -p "${TOOLS_DIR}" 2>/dev/null || true
    mkdir -p "${BACKUP_DIR}" 2>/dev/null || true
    mkdir -p "${LOG_DIR}" 2>/dev/null || true

    touch "${PKG_DB}" 2>/dev/null || true
    touch "${LOG_DIR}/install.log" 2>/dev/null || true
    touch "${LOG_DIR}/errors.log" 2>/dev/null || true
    touch "${LOG_DIR}/success.log" 2>/dev/null || true
}
init_dirs

# ===================================================================
# LOGGING
# ===================================================================
log_info()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "${LOG_DIR}/install.log" 2>/dev/null || true; }
log_error()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "${LOG_DIR}/errors.log" 2>/dev/null || true; }
log_success(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $*" >> "${LOG_DIR}/success.log" 2>/dev/null || true; }

# ===================================================================
# UI HELPERS
# ===================================================================
banner() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${B}${Rr}   ███████╗ ██████╗ ██████╗ ██╗  ██╗███████╗ ██████╗ ${R}"
    echo -e "${B}${Rr}   ╚══███╔╝██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝ ${R}"
    echo -e "${B}${Rr}     ███╔╝ ██║   ██║██████╔╝█████╔╝ █████╗  ██║      ${R}"
    echo -e "${B}${Rr}    ███╔╝  ██║   ██║██╔══██╗██╔═██╗ ██╔══╝  ██║      ${R}"
    echo -e "${B}${Rr}   ███████╗╚██████╔╝██║  ██║██║  ██╗███████╗╚██████╗ ${R}"
    echo -e "${B}${Rr}   ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ${R}"
    echo ""
    echo -e "${B}${BLE}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "${B}${BLE}║${R}  ${B}${W}ZorkSec-Termux${R} ${D}v${VERSION}${R}                                         ${B}${BLE}║${R}"
    echo -e "${B}${BLE}║${R}  ${D}Author: ${AUTHOR}${R}                                        ${B}${BLE}║${R}"
    echo -e "${B}${BLE}║${R}  ${D}Tools: ~/zorksec-tools/Category/Tool/${R}                       ${B}${BLE}║${R}"
    echo -e "${B}${BLE}╚══════════════════════════════════════════════════════════╝${R}"
    echo ""
}

section() {
    echo ""
    echo -e "${B}${BLE}┌─────────────────────────────────────────────────────────────┐${R}"
    printf "${B}${BLE}│${R}  %-57s ${B}${BLE}│${R}\n" "$1"
    echo -e "${B}${BLE}└─────────────────────────────────────────────────────────────┘${R}"
    echo ""
}

info()  { echo -e "  ${C}[*]${R} $*"; }
ok()    { echo -e "  ${G}[✓]${R} $*"; }
warn()  { echo -e "  ${Y}[!]${R} $*"; }
fail()  { echo -e "  ${Rr}[✗]${R} $*"; }

confirm() {
    local prompt="${1:-Continue}"
    local ans
    echo ""
    read -r -p "  $(echo -e "${Y}[?]${R}") ${prompt} [y/N]: " ans
    case "${ans}" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

press_enter() {
    echo ""
    read -r -p "  Press Enter to continue..." dummy
}

# ===================================================================
# PROGRESS BAR
# ===================================================================
show_progress() {
    local current=$1
    local total=$2
    local width=40
    local pct=0

    if [ "${total}" -gt 0 ]; then
        pct=$((current * 100 / total))
    fi

    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r  ["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' ' '
    printf "] %3d%% (%d/%d)" "${pct}" "${current}" "${total}"
}

# ===================================================================
# PACKAGE DATABASE
# ===================================================================
record_install() {
    local tool_name="$1"
    local category="$2"
    local status="$3"

    # Remove old entry if exists
    sed -i "/^.*|${category}|${tool_name}|.*$/d" "${PKG_DB}" 2>/dev/null || true

    echo "$(date '+%Y-%m-%d %H:%M:%S')|${category}|${tool_name}|${status}" >> "${PKG_DB}"
}

get_tool_status() {
    local tool_name="$1"
    local category="$2"
    grep "|${category}|${tool_name}|" "${PKG_DB}" 2>/dev/null | tail -1 | awk -F'|' '{print $4}'
}

is_installed() {
    local tool_name="$1"
    local category="$2"
    local status
    status="$(get_tool_status "${tool_name}" "${category}")"
    [ "${status}" = "success" ]
}

# ===================================================================
# GIT REPOSITORY DATABASE
# ===================================================================
declare -A GIT_REPOS

GIT_REPOS=(
    # ---- INFORMATION GATHERING ----
    ["nmap"]="https://github.com/nmap/nmap.git"
    ["rustscan"]="https://github.com/RustScan/RustScan.git"
    ["masscan"]="https://github.com/robertdavidgraham/masscan.git"
    ["naabu"]="https://github.com/projectdiscovery/naabu.git"
    ["amass"]="https://github.com/owasp-amass/amass.git"
    ["assetfinder"]="https://github.com/tomnomnom/assetfinder.git"
    ["subfinder"]="https://github.com/projectdiscovery/subfinder.git"
    ["findomain"]="https://github.com/Findomain/Findomain.git"
    ["theharvester"]="https://github.com/laramies/theHarvester.git"
    ["httpx"]="https://github.com/projectdiscovery/httpx.git"
    ["httprobe"]="https://github.com/tomnomnom/httprobe.git"
    ["gau"]="https://github.com/lc/gau.git"
    ["waybackurls"]="https://github.com/tomnomnom/waybackurls.git"
    ["hakrawler"]="https://github.com/hakluke/hakrawler.git"
    ["dnsx"]="https://github.com/projectdiscovery/dnsx.git"
    ["dnsrecon"]="https://github.com/darkoperator/dnsrecon.git"
    ["dnsenum"]="https://github.com/fwaeytens/dnsenum.git"
    ["massdns"]="https://github.com/blechschmidt/massdns.git"
    ["fierce"]="https://github.com/mschwager/fierce.git"
    ["sublist3r"]="https://github.com/aboul3la/Sublist3r.git"
    ["subbrute"]="https://github.com/TheRook/subbrute.git"
    ["gobuster"]="https://github.com/OJ/gobuster.git"
    ["ffuf"]="https://github.com/ffuf/ffuf.git"
    ["dirsearch"]="https://github.com/maurosoria/dirsearch.git"
    ["feroxbuster"]="https://github.com/epi052/feroxbuster.git"
    ["nikto"]="https://github.com/sullo/nikto.git"
    ["nuclei"]="https://github.com/projectdiscovery/nuclei.git"
    ["wpscan"]="https://github.com/wpscanteam/wpscan.git"
    ["dalfox"]="https://github.com/hahwul/dalfox.git"
    ["xsstrike"]="https://github.com/s0md3v/XSStrike.git"
    ["paramspider"]="https://github.com/devanshbatham/ParamSpider.git"
    ["arjun"]="https://github.com/s0md3v/Arjun.git"

    # ---- OSINT ----
    ["sherlock"]="https://github.com/sherlock-project/sherlock.git"
    ["maigret"]="https://github.com/soxoj/maigret.git"
    ["phoneinfoga"]="https://github.com/sundowndev/phoneinfoga.git"
    ["holehe"]="https://github.com/megadose/holehe.git"
    ["social-analyzer"]="https://github.com/qeeqbox/social-analyzer.git"
    ["ghunt"]="https://github.com/mxrch/GHunt.git"

    # ---- NETWORK ----
    ["tcpdump"]="https://github.com/the-tcpdump-group/tcpdump.git"
    ["bettercap"]="https://github.com/bettercap/bettercap.git"
    ["zmap"]="https://github.com/zmap/zmap.git"
    ["responder"]="https://github.com/lgandx/Responder.git"
    ["impacket"]="https://github.com/fortra/impacket.git"

    # ---- WIRELESS ----
    ["aircrack-ng"]="https://github.com/aircrack-ng/aircrack-ng.git"
    ["hcxdumptool"]="https://github.com/ZerBea/hcxdumptool.git"
    ["reaver"]="https://github.com/t6x/reaver-wps-fork-t6x.git"
    ["mdk4"]="https://github.com/aircrack-ng/mdk4.git"
    ["kismet"]="https://github.com/kismetwireless/kismet.git"
    ["wifite2"]="https://github.com/derv82/wifite2.git"

    # ---- PASSWORD ATTACK ----
    ["john"]="https://github.com/openwall/john.git"
    ["hashcat"]="https://github.com/hashcat/hashcat.git"
    ["hydra"]="https://github.com/vanhauser-thc/thc-hydra.git"
    ["crunch"]="https://github.com/crunchsec/crunch.git"
    ["cewl"]="https://github.com/digininja/CeWL.git"
    ["hash-identifier"]="https://github.com/psypanda/hashID.git"
    ["medusa"]="https://github.com/jmk-foofus/medusa.git"
    ["ncrack"]="https://github.com/nmap/ncrack.git"
    ["patator"]="https://github.com/lanjelot/patator.git"
    ["hashcat-utils"]="https://github.com/hashcat/hashcat-utils.git"
    ["seclists"]="https://github.com/danielmiessler/SecLists.git"

    # ---- EXPLOITATION ----
    ["metasploit-framework"]="https://github.com/rapid7/metasploit-framework.git"
    ["sqlmap"]="https://github.com/sqlmapproject/sqlmap.git"
    ["commix"]="https://github.com/commixproject/commix.git"
    ["exploitdb"]="https://github.com/offensive-security/exploitdb.git"
    ["beef"]="https://github.com/beefproject/beef.git"
    ["yersinia"]="https://github.com/tomac/yersinia.git"
    ["setoolkit"]="https://github.com/trustedsec/social-engineer-toolkit.git"
    ["shellphish"]="https://github.com/thelinuxchoice/shellphish.git"
    ["evilginx2"]="https://github.com/kgretzky/evilginx2.git"
    ["hiddeneye"]="https://github.com/DarkSecDevelopers/HiddenEye.git"

    # ---- POST EXPLOITATION ----
    ["empire"]="https://github.com/BC-SECURITY/Empire.git"
    ["pwncat"]="https://github.com/cytopia/pwncat.git"
    ["chisel"]="https://github.com/jpillora/chisel.git"
    ["ligolo-ng"]="https://github.com/nicocha30/ligolo-ng.git"
    ["phpsploit"]="https://github.com/nil0x42/phpsploit.git"

    # ---- REVERSE ENGINEERING ----
    ["radare2"]="https://github.com/radareorg/radare2.git"
    ["binwalk"]="https://github.com/ReFirmLabs/binwalk.git"
    ["apktool"]="https://github.com/iBotPeaches/Apktool.git"
    ["jadx"]="https://github.com/skylot/jadx.git"
    ["gdb"]="https://github.com/bminor/binutils-gdb.git"
    ["rizin"]="https://github.com/rizinorg/rizin.git"
    ["frida"]="https://github.com/frida/frida.git"

    # ---- MALWARE ANALYSIS ----
    ["clamav"]="https://github.com/Cisco-Talos/clamav.git"
    ["yara"]="https://github.com/VirusTotal/yara.git"
    ["capa"]="https://github.com/mandiant/capa.git"
    ["flare-floss"]="https://github.com/mandiant/flare-floss.git"

    # ---- DIGITAL FORENSICS ----
    ["volatility3"]="https://github.com/volatilityfoundation/volatility3.git"
    ["volatility"]="https://github.com/volatilityfoundation/volatility.git"
    ["exiftool"]="https://github.com/exiftool/exiftool.git"
    ["foremost"]="https://github.com/korczis/foremost.git"
    ["sleuthkit"]="https://github.com/sleuthkit/sleuthkit.git"
    ["bulk-extractor"]="https://github.com/simsong/bulk_extractor.git"
    ["scalpel"]="https://github.com/sleuthkit/scalpel.git"

    # ---- THREAT INTELLIGENCE ----
    ["sigma"]="https://github.com/SigmaHQ/sigma.git"
    ["misp"]="https://github.com/MISP/MISP.git"
    ["thehive"]="https://github.com/TheHive-Project/TheHive.git"
    ["cortex"]="https://github.com/TheHive-Project/Cortex.git"

    # ---- ATTACK TOOLS (MITM / Phishing) ----
    ["mitmproxy"]="https://github.com/mitmproxy/mitmproxy.git"
    ["ettercap"]="https://github.com/Ettercap/ettercap.git"
    ["macchanger"]="https://github.com/alobbs/macchanger.git"
    ["dnsspoof"]="https://github.com/DanMcInerney/dnsspoof.git"
    ["mitm6"]="https://github.com/dirkjanm/mitm6.git"
)

# ===================================================================
# GIT CLONE FUNCTION — SAFE (never exits on error)
# ===================================================================
install_git_tool() {
    local repo_url="$1"
    local tool_name="$2"
    local category_name="$3"
    local cat_num="$4"
    local cat_label="$5"

    # Build the category folder name with number
    local cat_folder="${cat_num}-${cat_label}"

    local target_dir="${TOOLS_DIR}/${cat_folder}/${tool_name}"

    # Check if already installed successfully
    if is_installed "${tool_name}" "${cat_folder}"; then
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        return 0
    fi

    echo ""
    info "Processing: ${B}${W}${tool_name}${R} (${cat_folder})"

    TOTAL_PACKAGES=$((TOTAL_PACKAGES + 1))

    if [ -d "${target_dir}/.git" ]; then
        # Already cloned — try to update
        info "Repository exists. Updating..."
        (cd "${target_dir}" && git pull --ff-only 2>/dev/null) || warn "Could not update"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        record_install "${tool_name}" "${cat_folder}" "success"
        log_success "${tool_name} updated"
        ok "${tool_name} is up to date"
        return 0
    fi

    # Fresh clone
    local clone_start
    clone_start="$(date +%s)"

    mkdir -p "${TOOLS_DIR}/${cat_folder}" 2>/dev/null || true

    if git clone --depth 1 "${repo_url}" "${target_dir}" >> "${LOG_DIR}/install.log" 2>&1; then
        local clone_end
        clone_end="$(date +%s)"
        local clone_time=$((clone_end - clone_start))

        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        record_install "${tool_name}" "${cat_folder}" "success"
        log_success "${tool_name} cloned (${clone_time}s)"
        ok "${tool_name} installed in ${clone_time}s"

        # Create symlink for terminal access
        if [ -f "${target_dir}/${tool_name}" ]; then
            ln -sf "${target_dir}/${tool_name}" "${PREFIX_DIR}/bin/${tool_name}" 2>/dev/null || true
        fi
        # Check for common binary locations
        for possible_bin in "${target_dir}/build/${tool_name}" "${target_dir}/bin/${tool_name}" "${target_dir}/src/${tool_name}"; do
            if [ -f "${possible_bin}" ]; then
                ln -sf "${possible_bin}" "${PREFIX_DIR}/bin/${tool_name}" 2>/dev/null || true
                break
            fi
        done

        # Try to make it executable
        chmod +x "${target_dir}"/*.py 2>/dev/null || true
        chmod +x "${target_dir}"/*.sh 2>/dev/null || true
        chmod +x "${target_dir}/${tool_name}" 2>/dev/null || true
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TOOLS="${FAILED_TOOLS} ${tool_name}"
        record_install "${tool_name}" "${cat_folder}" "failed"
        log_error "${tool_name} failed to clone"
        fail "${tool_name} failed to clone"
        return 1
    fi
}

# ===================================================================
# INSTALL A GROUP OF TOOLS
# ===================================================================
install_group() {
    local cat_num="$1"
    local cat_label="$2"
    shift 2
    local tools=("$@")

    section "${cat_num} - ${cat_label}"

    echo -e "  ${D}Choose an option:${R}"
    echo -e "  ${B}${G}A${R}  Install ALL tools in this category"
    echo -e "  ${B}${Y}0${R}  Back to Main Menu"
    echo ""

    for i in "${!tools[@]}"; do
        local idx=$((i + 1))
        local tool_status=""
        if is_installed "${tools[$i]}" "${cat_num}-${cat_label}"; then
            tool_status="${G}[INSTALLED]${R}"
        else
            tool_status="${D}[pending]${R}"
        fi
        printf "  %2d) %-30s %s\n" "${idx}" "${tools[$i]}" "${tool_status}"
    done

    echo ""
    read -r -p "  $(echo -e "${B}${C}[${cat_label}]${R}") Select [A=all, #=tool, 0=back]: " choice

    if [ "${choice}" = "A" ] || [ "${choice}" = "a" ]; then
        for tool in "${tools[@]}"; do
            local rurl="${GIT_REPOS[${tool}]:-}"
            if [ -n "${rurl}" ]; then
                install_git_tool "${rurl}" "${tool}" "${cat_label}" "${cat_num}" "${cat_label}"
            else
                warn "No repo URL for: ${tool}"
            fi
        done
    elif [[ "${choice}" =~ ^[0-9]+$ ]] && [ "${choice}" -gt 0 ] && [ "${choice}" -le "${#tools[@]}" ]; then
        local tool_idx=$((choice - 1))
        local tool_name="${tools[${tool_idx}]}"
        local tool_url="${GIT_REPOS[${tool_name}]:-}"
        if [ -n "${tool_url}" ]; then
            install_git_tool "${tool_url}" "${tool_name}" "${cat_label}" "${cat_num}" "${cat_label}"
        fi
    fi
}

# ===================================================================
# PACKAGES — THIS COMES FIRST (Option 1 in menu)
# ===================================================================
install_packages() {
    section "📦 TERMUX BASE PACKAGES INSTALLATION"

    echo -e "  ${B}${Y}This will install ALL essential Termux packages for cybersecurity work.${R}"
    echo -e "  ${D}Includes: Python, Go, Rust, Ruby, Perl, Node.js, compilers, libraries,${R}"
    echo -e "  ${D}network tools, and utilities needed for the security toolset.${R}"
    echo ""

    if ! confirm "Install ALL base packages?"; then
        warn "Package installation skipped."
        return
    fi

    # First, update package lists
    info "Updating Termux package lists..."
    pkg update -y >> "${LOG_DIR}/install.log" 2>&1 || warn "pkg update had issues"
    ok "Package lists updated"

    # Define ALL packages in logical groups
    local packages=(
        # ---- CORE LANGUAGES & RUNTIMES ----
        python
        python2
        python3
        python-pip
        openjdk-17
        go
        golang
        rust
        cargo
        ruby
        perl
        nodejs
        php
        lua

        # ---- COMPILERS & BUILD TOOLS ----
        clang
        gcc
        g++
        make
        cmake
        ninja
        autoconf
        automake
        libtool
        m4
        pkg-config
        bison
        flex
        gperf

        # ---- VERSION CONTROL ----
        git
        git-lfs
        subversion
        mercurial

        # ---- NETWORK TOOLS ----
        curl
        wget
        netcat-openbsd
        nmap
        traceroute
        dnsutils
        whois
        openssh
        sshpass
        net-tools
        ethtool
        iproute2

        # ---- TEXT PROCESSING / SHELL ----
        bash
        zsh
        fish
        tmux
        screen
        vim
        nano
        emacs
        ripgrep
        fzf
        bat
        jq
        yq
        htop
        btop
        tree
        unzip
        zip
        tar
        gzip
        bzip2
        xz-utils
        p7zip

        # ---- WIRELESS / BLUETOOTH ----
        root-repo
        x11-repo
        tsu
        termux-tools
        termux-elf-cleaner

        # ---- PYTHON PACKAGES (pip) ----
        # These install via pip, not pkg
    )

    local pip_packages=(
        requests
        beautifulsoup4
        lxml
        selenium
        scapy
        cryptography
        pyopenssl
        paramiko
        colorama
        rich
        flask
        django
        sqlalchemy
        aiohttp
        asyncio
        nmap
        python-whois
        dnspython
        pandas
        numpy
        netifaces
        psutil
    )

    local total_pkgs=${#packages[@]}
    local pip_total=${#pip_packages[@]}
    local grand_total=$((total_pkgs + pip_total))
    local current=0

    echo ""
    info "Installing ${total_pkgs} Termux packages..."
    echo ""

    # Install packages in batches to avoid overwhelming pkg
    local batch_size=15
    local batch_start=0

    while [ "${batch_start}" -lt "${total_pkgs}" ]; do
        local batch_end=$((batch_start + batch_size - 1))
        [ "${batch_end}" -ge "${total_pkgs}" ] && batch_end=$((total_pkgs - 1))

        local batch=("${packages[@]:${batch_start}:$((batch_end - batch_start + 1))}")
        local pkg_count=$((batch_end - batch_start + 1))

        info "Batch $((batch_start / batch_size + 1)): ${batch[*]}"

        if pkg install -y "${batch[@]}" >> "${LOG_DIR}/install.log" 2>&1; then
            ok "Batch $((batch_start / batch_size + 1)) installed successfully"
        else
            fail "Batch $((batch_start / batch_size + 1)) had failures — continuing..."
        fi

        current=$((current + pkg_count))
        show_progress "${current}" "${total_pkgs}"
        batch_start=$((batch_end + 1))
    done

    echo ""
    echo ""
    ok "Termux packages phase complete!"

    # ---- PIP PACKAGES ----
    echo ""
    info "Installing ${pip_total} Python packages via pip..."
    echo ""

    # Upgrade pip first
    pip install --upgrade pip >> "${LOG_DIR}/install.log" 2>&1 || warn "pip upgrade skipped"

    current=0
    for pkg in "${pip_packages[@]}"; do
        current=$((current + 1))
        show_progress "${current}" "${pip_total}"
        pip install "${pkg}" >> "${LOG_DIR}/install.log" 2>&1 || warn "pip install ${pkg} failed"
    done

    echo ""
    echo ""
    ok "Python packages installed!"

    # ---- SPECIAL INSTALLS ----
    echo ""
    info "Installing special packages..."

    # Install rustscan via cargo
    if command -v cargo >/dev/null 2>&1; then
        cargo install rustscan 2>/dev/null || warn "rustscan cargo install failed"
    fi

    # Install golang tools
    if command -v go >/dev/null 2>&1; then
        go install github.com/tomnomnom/assetfinder@latest 2>/dev/null || true
        go install github.com/tomnomnom/httprobe@latest 2>/dev/null || true
        go install github.com/tomnomnom/waybackurls@latest 2>/dev/null || true
    fi

    echo ""
    ok "Special package installations complete!"

    # Summary
    echo ""
    echo -e "${B}${G}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "${B}${G}║${R}     📦 PACKAGE INSTALLATION COMPLETE!                   ${B}${G}║${R}"
    echo -e "${B}${G}║${R}     ${total_pkgs} Termux packages + ${pip_total} Python packages          ${B}${G}║${R}"
    echo -e "${B}${G}╚══════════════════════════════════════════════════════════╝${R}"
    echo ""
    info "Your Termux environment is now ready for security tools!"
    info "Check logs: ${LOG_DIR}/install.log"
    info "Next step: Install security tools from the main menu"
}

# ===================================================================
# INSTALL EVERYTHING (ALL CATEGORIES)
# ===================================================================
install_everything() {
    section "🔥 INSTALL ALL TOOLS"

    echo -e "  ${B}${Rr}WARNING:${R} This will download 100+ security tools from GitHub."
    echo -e "  ${D}Estimated time: 30-60 minutes depending on your internet speed.${R}"
    echo -e "  ${D}Estimated storage: 5-10 GB${R}"
    echo ""

    if ! confirm "Are you sure you want to install everything?"; then
        warn "Cancelled."
        return
    fi

    TOTAL_PACKAGES=0
    INSTALLED_COUNT=0
    SKIPPED_COUNT=0
    FAILED_COUNT=0
    FAILED_TOOLS=""

    # Define all categories with their tool lists
    local categories=(
        "01|Information-Gathering|nmap rustscan masscan naabu amass assetfinder subfinder findomain theharvester httpx httprobe gau waybackurls hakrawler dnsx dnsrecon dnsenum massdns fierce sublist3r subbrute gobuster ffuf dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun"
        "02|OSINT|sherlock maigret phoneinfoga holehe social-analyzer ghunt"
        "03|Subdomain-Enumeration|subfinder assetfinder findomain amass dnsx httpx httprobe sublist3r"
        "04|DNS-Tools|dnsx dnsrecon dnsenum massdns fierce"
        "05|Web-Security|ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun"
        "06|Network-Tools|tcpdump bettercap nmap masscan zmap responder impacket"
        "07|Wireless-Security|aircrack-ng hcxdumptool reaver mdk4 kismet wifite2"
        "08|Password-Attack|john hashcat hydra crunch cewl hash-identifier medusa ncrack patator hashcat-utils seclists"
        "09|Exploitation|metasploit-framework sqlmap commix exploitdb beef yersinia setoolkit shellphish evilginx2 hiddeneye"
        "10|Post-Exploitation|empire pwncat chisel ligolo-ng phpsploit"
        "11|Reverse-Engineering|radare2 binwalk apktool jadx gdb rizin frida"
        "12|Malware-Analysis|clamav yara capa flare-floss"
        "13|Digital-Forensics|volatility3 volatility exiftool foremost sleuthkit bulk-extractor scalpel"
        "14|Threat-Intelligence|sigma misp thehive cortex"
        "15|Additional-Attack-Tools|mitmproxy ettercap macchanger dnsspoof mitm6 responder impacket beef"
    )

    for entry in "${categories[@]}"; do
        local cat_num="${entry%%|*}"
        local rest="${entry#*|}"
        local cat_label="${rest%%|*}"
        local tools_list="${rest#*|}"
        local tools=(${tools_list})

        section "${cat_num} - ${cat_label}"

        for tool_name in "${tools[@]}"; do
            local repo_url="${GIT_REPOS[${tool_name}]:-}"
            if [ -n "${repo_url}" ]; then
                install_git_tool "${repo_url}" "${tool_name}" "${cat_label}" "${cat_num}" "${cat_label}"
            else
                warn "No repo URL configured for: ${tool_name}"
            fi
        done
    done

    echo ""
    echo -e "${B}${G}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "${B}${G}║${R}     🎉 ALL TOOLS INSTALLATION COMPLETE!                  ${B}${G}║${R}"
    echo -e "${B}${G}╚══════════════════════════════════════════════════════════╝${R}"
    show_summary
}

# ===================================================================
# SUMMARY
# ===================================================================
show_summary() {
    local end_time
    end_time="$(date +%s)"
    local duration=$((end_time - START_TIME))
    local storage_used
    storage_used="$(du -sh "${TOOLS_DIR}" 2>/dev/null | awk '{print $1}')"
    storage_used="${storage_used:-0B}"

    echo ""
    echo -e "${B}${C}╔══════════════════════════════════════════════════════════╗${R}"
    echo -e "${B}${C}║${R}               INSTALLATION SUMMARY                       ${B}${C}║${R}"
    echo -e "${B}${C}╠══════════════════════════════════════════════════════════╣${R}"
    printf "${B}${C}║${R}  %-20s %-28s ${B}${C}║${R}\n" "Total:" "${TOTAL_PACKAGES}"
    printf "${B}${C}║${R}  ${G}%-20s${R} %-28s ${B}${C}║${R}\n" "Installed:" "${INSTALLED_COUNT}"
    printf "${B}${C}║${R}  ${Y}%-20s${R} %-28s ${B}${C}║${R}\n" "Skipped:" "${SKIPPED_COUNT}"
    printf "${B}${C}║${R}  ${Rr}%-20s${R} %-28s ${B}${C}║${R}\n" "Failed:" "${FAILED_COUNT}"
    echo -e "${B}${C}║${R}                                                      ${B}${C}║${R}"
    printf "${B}${C}║${R}  %-20s %-28s ${B}${C}║${R}\n" "Duration:" "$((duration / 60))m $((duration % 60))s"
    printf "${B}${C}║${R}  %-20s %-28s ${B}${C}║${R}\n" "Storage:" "${storage_used} in tools dir"
    printf "${B}${C}║${R}  %-20s %-28s ${B}${C}║${R}\n" "Logs:" "${LOG_DIR}/"
    echo -e "${B}${C}╚══════════════════════════════════════════════════════════╝${R}"
    echo ""
}

# ===================================================================
# UPDATE ALL REPOS
# ===================================================================
update_all() {
    section "UPDATE ALL CLONED REPOSITORIES"

    local count=0
    local repo_list=()

    while IFS= read -r git_dir; do
        repo_list+=("${git_dir}")
    done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null || true)

    if [ "${#repo_list[@]}" -eq 0 ]; then
        warn "No repositories found to update."
        return
    fi

    info "Found ${#repo_list[@]} repositories to update..."
    echo ""

    for git_dir in "${repo_list[@]}"; do
        local repo_dir
        repo_dir="$(dirname "${git_dir}")"
        local repo_name
        repo_name="$(basename "${repo_dir}")"
        local count_pad=$((count + 1))

        printf "  [%3d/%3d] %-40s" "${count_pad}" "${#repo_list[@]}" "${repo_name}"

        if (cd "${repo_dir}" && git pull --ff-only >> "${LOG_DIR}/install.log" 2>&1); then
            echo -e "${G}✓${R}"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
        else
            echo -e "${Y}⚠${R}"
        fi

        count=$((count + 1))
    done

    echo ""
    ok "Updated ${UPDATED_COUNT}/${#repo_list[@]} repositories"
}

# ===================================================================
# SHOW INSTALLED
# ===================================================================
show_installed() {
    section "INSTALLED TOOLS DATABASE"

    if [ ! -s "${PKG_DB}" ]; then
        warn "No tools have been installed yet."
        return
    fi

    local current_cat=""
    local installed=0
    local failed=0
    local skipped=0

    while IFS='|' read -r _ cat name status; do
        if [ "${cat}" != "${current_cat}" ]; then
            echo ""
            echo -e "  ${B}${BLE}►${R} ${B}${cat}${R}"
            current_cat="${cat}"
        fi

        case "${status}" in
            success) echo -e "    ${G}✓${R} ${name}"; installed=$((installed + 1)) ;;
            failed)  echo -e "    ${Rr}✗${R} ${name}"; failed=$((failed + 1)) ;;
            skipped) echo -e "    ${Y}⚠${R} ${name}"; skipped=$((skipped + 1)) ;;
        esac
    done < "${PKG_DB}"

    echo ""
    echo -e "  ${B}Summary:${R} ${G}${installed} installed${R}, ${Rr}${failed} failed${R}, ${Y}${skipped} skipped${R}"
    echo ""
    info "Your tools are stored in:"
    echo -e "  ${D}${TOOLS_DIR}/${R}"
    echo ""
    info "To see the folder structure:"
    echo -e "  ${D}ls -la ${TOOLS_DIR}/${R}"
}

# ===================================================================
# HEALTH CHECK
# ===================================================================
health_check() {
    section "SYSTEM HEALTH CHECK"

    local issues=0

    # 1. Storage
    local avail_kb
    avail_kb="$(df "${HOME_DIR}" 2>/dev/null | awk 'NR==2{print $4}')"
    avail_kb="${avail_kb:-0}"
    local avail_mb=$((avail_kb / 1024))

    echo -e "  ${B}[1] Storage:${R}"
    echo -e "       Available: ${avail_mb}MB"

    if [ "${avail_mb}" -lt 500 ]; then
        echo -e "       ${Rr}✗ CRITICAL: Very low storage${R}"
        issues=$((issues + 1))
    elif [ "${avail_mb}" -lt 1000 ]; then
        echo -e "       ${Y}⚠ Warning: Low storage${R}"
    else
        echo -e "       ${G}✓ OK${R}"
    fi

    # 2. Network
    echo -e "  ${B}[2] Network:${R}"
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        echo -e "       ${G}✓ Internet connected${R}"
    else
        echo -e "       ${Y}⚠ Offline or restricted${R}"
    fi

    # 3. Git
    echo -e "  ${B}[3] Git:${R}"
    if command -v git >/dev/null 2>&1; then
        local git_ver
        git_ver="$(git --version 2>/dev/null | head -1)"
        echo -e "       ${G}✓ ${git_ver}${R}"
    else
        echo -e "       ${Rr}✗ git NOT installed${R}"
        issues=$((issues + 1))
    fi

    # 4. Core Languages
    echo -e "  ${B}[4] Languages:${R}"
    for lang_cmd in "python3 --version" "go version" "rustc --version" "ruby --version" "perl --version" "node --version" "java -version"; do
        local lang_name="${lang_cmd%% *}"
        if command -v "${lang_name}" >/dev/null 2>&1; then
            echo -e "       ${G}✓ ${lang_cmd}${R}"
        else
            echo -e "       ${Y}⚠ ${lang_name} not found${R}"
        fi
    done

    # 5. Repository count
    echo -e "  ${B}[5] Cloned Repositories:${R}"
    local repo_count
    repo_count="$(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | wc -l)"
    echo -e "       ${repo_count} repos in ${TOOLS_DIR}"

    # 6. Directory structure
    echo -e "  ${B}[6] Category Directories:${R}"
    if [ -d "${TOOLS_DIR}" ]; then
        local dir_count=0
        while IFS= read -r dir; do
            local dname
            dname="$(basename "${dir}")"
            local tool_count
            tool_count="$(find "${dir}" -maxdepth 2 -type d 2>/dev/null | wc -l)"
            tool_count=$((tool_count - 1))
            [ "${tool_count}" -ge 0 ] && echo -e "       ${D}• ${dname} (${tool_count} tools)${R}" && dir_count=$((dir_count + 1))
        done < <(find "${TOOLS_DIR}" -maxdepth 1 -type d 2>/dev/null | sort)

        if [ "${dir_count}" -eq 0 ]; then
            echo -e "       ${Y}Empty — no categories yet${R}"
        fi
    else
        echo -e "       ${Y}Tools directory does not exist${R}"
    fi

    # 7. Symlinks
    echo -e "  ${B}[7] Symlinks in PATH:${R}"
    local sym_count=0
    while IFS= read -r f; do
        if [ -L "${PREFIX_DIR}/bin/${f}" ]; then
            sym_count=$((sym_count + 1))
        fi
    done < <(find "${TOOLS_DIR}" -maxdepth 3 -type f -executable 2>/dev/null | while IFS= read -r f; do basename "${f}"; done | sort -u)

    echo -e "       ${sym_count} symlinks in ${PREFIX_DIR}/bin/"

    echo ""
    if [ "${issues}" -eq 0 ]; then
        echo -e "  ${G}✓ All health checks passed!${R}"
    else
        echo -e "  ${Y}⚠ ${issues} issue(s) found. Install packages first (Option 1).${R}"
    fi
}

# ===================================================================
# REPOSITORY MANAGER
# ===================================================================
repo_manager() {
    while true; do
        section "REPOSITORY MANAGER"
        echo -e "  ${B}${G}1${R}  List all cloned repositories"
        echo -e "  ${B}${G}2${R}  Update all repositories"
        echo -e "  ${B}${G}3${R}  Delete a repository"
        echo -e "  ${B}${G}4${R}  Show repository sizes"
        echo -e "  ${B}${G}5${R}  Show folder tree"
        echo -e "  ${B}${Y}0${R}  Back to Main Menu"
        echo ""
        read -r -p "  $(echo -e "${B}${C}[RepoMgr]${R}") Select: " mgr_choice

        case "${mgr_choice}" in
            0) break ;;
            1)
                echo ""
                local repo_count=0
                while IFS= read -r git_dir; do
                    local rdir="$(dirname "${git_dir}")"
                    echo -e "  ${B}$((repo_count + 1))${R}. ${rdir#${TOOLS_DIR}/}"
                    repo_count=$((repo_count + 1))
                done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | sort)
                if [ "${repo_count}" -eq 0 ]; then
                    echo -e "  ${Y}No repositories found${R}"
                fi
                ;;
            2)
                update_all
                ;;
            3)
                echo ""
                local -a repo_paths=()
                local i=1
                while IFS= read -r git_dir; do
                    local rdir="$(dirname "${git_dir}")"
                    repo_paths+=("${rdir}")
                    echo -e "  ${i}) ${rdir#${TOOLS_DIR}/}"
                    i=$((i + 1))
                done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | sort)

                if [ "${#repo_paths[@]}" -eq 0 ]; then
                    echo -e "  ${Y}No repositories to delete${R}"
                else
                    echo ""
                    read -r -p "  Enter number to delete: " del_choice
                    if [[ "${del_choice}" =~ ^[0-9]+$ ]]; then
                        local del_idx=$((del_choice - 1))
                        if [ "${del_idx}" -ge 0 ] && [ "${del_idx}" -lt "${#repo_paths[@]}" ]; then
                            local del_path="${repo_paths[${del_idx}]}"
                            local del_name="$(basename "${del_path}")"
                            if confirm "Delete ${del_name}?"; then
                                rm -rf "${del_path}" 2>/dev/null && ok "Deleted: ${del_name}" || fail "Failed to delete ${del_name}"
                            fi
                        fi
                    fi
                fi
                ;;
            4)
                echo ""
                du -sh "${TOOLS_DIR}"/*/ 2>/dev/null | sort -rh | head -30
                ;;
            5)
                echo ""
                find "${TOOLS_DIR}" -maxdepth 3 -type d 2>/dev/null | sort | head -80
                ;;
        esac

        press_enter
    done
}

# ===================================================================
# BACKUP / RESTORE
# ===================================================================
backup_config() {
    section "BACKUP CONFIGURATION"
    local backup_file="${BACKUP_DIR}/zorksec-backup-$(date '+%Y%m%d-%H%M%S').tar.gz"

    if tar -czf "${backup_file}" -C "${CONFIG_DIR}" . 2>/dev/null; then
        ok "Backup saved: ${backup_file}"
        log_success "Backup: ${backup_file}"
    else
        fail "Backup failed"
        log_error "Backup failed"
    fi
}

restore_config() {
    section "RESTORE CONFIGURATION"

    local backups=()
    while IFS= read -r bf; do
        backups+=("${bf}")
    done < <(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null || true)

    if [ "${#backups[@]}" -eq 0 ]; then
        warn "No backups found"
        return
    fi

    echo ""
    local i=1
    for bf in "${backups[@]}"; do
        echo -e "  ${i}) $(basename "${bf}")"
        i=$((i + 1))
    done

    echo ""
    read -r -p "  Select backup to restore: " restore_choice

    if [[ "${restore_choice}" =~ ^[0-9]+$ ]]; then
        local res_idx=$((restore_choice - 1))
        if [ "${res_idx}" -ge 0 ] && [ "${res_idx}" -lt "${#backups[@]}" ]; then
            local res_file="${backups[${res_idx}]}"
            if tar -xzf "${res_file}" -C "${CONFIG_DIR}" 2>/dev/null; then
                ok "Restored from: $(basename "${res_file}")"
                log_success "Restored from: ${res_file}"
            else
                fail "Restore failed"
                log_error "Restore failed from: ${res_file}"
            fi
        fi
    fi
}

# ===================================================================
# ABOUT / HELP
# ===================================================================
about() {
    section "ABOUT ZORKSEC-TERMUX"
    echo -e "  ${B}Version:${R}       ${VERSION}"
    echo -e "  ${B}Author:${R}        ${AUTHOR}"
    echo -e "  ${B}Platform:${R}      Termux (Android) — F-Droid version only"
    echo -e "  ${B}License:${R}       MIT"
    echo ""
    echo -e "  ${B}DESCRIPTION${R}"
    echo -e "  ZorkSec-Termux transforms your Android device into a"
    echo -e "  professional cybersecurity auditing platform with 200+ tools"
    echo -e "  cloned directly from their official GitHub repositories."
    echo ""
    echo -e "  ${B}FOLDER STRUCTURE${R}"
    echo -e "  ${D}${TOOLS_DIR}/${R}"
    echo -e "  ${D}├── 01-Information-Gathering/${R}"
    echo -e "  ${D}│   ├── nmap/${R}"
    echo -e "  ${D}│   ├── rustscan/${R}"
    echo -e "  ${D}│   └── ...${R}"
    echo -e "  ${D}├── 08-Password-Attack/${R}"
    echo -e "  ${D}│   ├── john/${R}"
    echo -e "  ${D}│   ├── hashcat/${R}"
    echo -e "  ${D}│   └── ...${R}"
    echo -e "  ${D}└── 15-Additional-Attack-Tools/${R}"
    echo ""
    echo -e "  ${B}HOW TO USE${R}"
    echo ""
    echo -e "  1) Run tools from terminal (globally available):"
    echo -e "     ${D}nmap -sV 192.168.1.1${R}"
    echo -e "     ${D}subfinder -d example.com${R}"
    echo -e "     ${D}hydra -l admin -P passwords.txt ssh://target${R}"
    echo ""

    echo -e "  2) Navigate to tool folder:"
    echo -e "     ${D}cd ~/zorksec-tools/08-Password-Attack/john/${R}"
    echo -e "     ${D}ls -la${R}"
    echo -e "     ${D}./john --list=formats${R}"
    echo ""
    echo -e "  ${B}RECOMMENDED WORKFLOW${R}"
    echo -e "  1. Install Packages (Option 1)"
    echo -e "  2. Install tools by category"
    echo -e "  3. Run Health Check (Option 20)"
    echo -e "  4. Start your security assessment!"
    echo ""
    echo -e "  ${B}REPOSITORY${R}"
    echo -e "  ${D}${REPO_URL}${R}"
    echo ""
}

# ===================================================================
# CLEANUP ON EXIT
# ===================================================================
cleanup() {
    echo ""
    echo -e "  ${Y}[!] Script interrupted by user${R}"
    show_summary
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# ===================================================================
# MAIN MENU
# ===================================================================
main_menu() {
    # Check if running in Termux
    if [ ! -d "${PREFIX_DIR}" ]; then
        echo -e "${Rr}[✗] This script must run inside Termux on Android${R}"
        echo -e "${Y}[*] Download from: https://f-droid.org/packages/com.termux/${R}"
        exit 1
    fi

    while true; do
        banner

        echo -e "${B}${BLE}┌────────────────────── MAIN MENU ──────────────────────┐${R}"
        echo -e "${B}${BLE}│${R}                                                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${M} 1${R}  📦 Install Termux Base Packages (FIRST!)   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}                                                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 2${R}  🔥 Install ALL Security Tools                ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 3${R}  📡 01 — Information Gathering                ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 4${R}  🔍 02 — OSINT                                ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 5${R}  🌐 03 — Subdomain Enumeration                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 6${R}  📍 04 — DNS Tools                            ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 7${R}  🌍 05 — Web Application Security              ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 8${R}  🔌 06 — Network Tools                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G} 9${R}  📶 07 — Wireless Security                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}10${R}  🔑 08 — Password Attack                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}11${R}  💥 09 — Exploitation & Phishing               ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}12${R}  🚀 10 — Post Exploitation                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}13${R}  🔬 11 — Reverse Engineering                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}14${R}  🦠 12 — Malware Analysis                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}15${R}  🔎 13 — Digital Forensics                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}16${R}  🛡️ 14 — Threat Intelligence                    ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${G}17${R}  ⚔️ 15 — Attack Tools (MITM/Phish)              ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}                                                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${Y}18${R}  🔄 Update All Repos                             ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${C}19${R}  📋 Show Installed Tools                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${C}20${R}  🏥 System Health Check                         ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${C}21${R}  📂 Repository Manager                          ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}                                                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${W}22${R}  💾 Backup Configuration                         ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${W}23${R}  📥 Restore Configuration                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${W}24${R}  ℹ️ About / Help                                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}                                                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}  ${B}${Rr}25${R}  🚪 Exit                                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R}                                                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}└──────────────────────────────────────────────────────┘${R}"
        echo ""

        # CRITICAL: Clear stdin before reading main menu choice
        # This prevents any leftover input from previous operations
        dd bs=1 count=1 of=/dev/null 2>/dev/null || true

        echo ""
        read -r -p "  $(echo -e "${B}${C}[ZorkSec]${R}") Enter choice [1-25]: " main_choice
        echo ""

        case "${main_choice}" in
            1)  install_packages ;;
            2)  install_everything ;;

            # Category submenus
            3)  install_group "01" "Information-Gathering" nmap rustscan masscan naabu amass assetfinder subfinder findomain theharvester httpx httprobe gau waybackurls hakrawler dnsx dnsrecon dnsenum massdns fierce sublist3r subbrute gobuster ffuf dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun ;;
            4)  install_group "02" "OSINT" sherlock maigret phoneinfoga holehe social-analyzer ghunt ;;
            5)  install_group "03" "Subdomain-Enumeration" subfinder assetfinder findomain amass dnsx httpx httprobe sublist3r ;;
            6)  install_group "04" "DNS-Tools" dnsx dnsrecon dnsenum massdns fierce ;;
            7)  install_group "05" "Web-Security" ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun ;;
            8)  install_group "06" "Network-Tools" tcpdump bettercap nmap masscan zmap responder impacket ;;
            9)  install_group "07" "Wireless-Security" aircrack-ng hcxdumptool reaver mdk4 kismet wifite2 ;;
            10) install_group "08" "Password-Attack" john hashcat hydra crunch cewl hash-identifier medusa ncrack patator hashcat-utils seclists ;;
            11) install_group "09" "Exploitation" metasploit-framework sqlmap commix exploitdb beef yersinia setoolkit shellphish evilginx2 hiddeneye ;;
            12) install_group "10" "Post-Exploitation" empire pwncat chisel ligolo-ng phpsploit ;;
            13) install_group "11" "Reverse-Engineering" radare2 binwalk apktool jadx gdb rizin frida ;;
            14) install_group "12" "Malware-Analysis" clamav yara capa flare-floss ;;
            15) install_group "13" "Digital-Forensics" volatility3 volatility exiftool foremost sleuthkit bulk-extractor scalpel ;;
            16) install_group "14" "Threat-Intelligence" sigma misp thehive cortex ;;
            17) install_group "15" "Additional-Attack-Tools" mitmproxy ettercap macchanger dnsspoof mitm6 responder impacket beef ;;

            # Utility options
            18) update_all ;;
            19) show_installed ;;
            20) health_check ;;
            21) repo_manager ;;
            22) backup_config ;;
            23) restore_config ;;
            24) about ;;
            25)
                echo -e "${G}"
                echo "  ╔══════════════════════════════════════════════════╗"
                echo "  ║     THANK YOU FOR USING ZORKSEC-TERMUX!        ║"
                echo "  ╚══════════════════════════════════════════════════╝"
                echo -e "${R}"
                echo -e "  ${B}${Y}Author:${R} ${AUTHOR}"
                echo -e "  ${B}${Y}GitHub:${R} ${REPO_URL}"
                echo ""
                show_summary
                exit 0
                ;;
            *)
                fail "Invalid option. Please enter a number 1-25."
                sleep 1
                ;;
        esac

        press_enter
    done
}

# ===================================================================
# ENTRY POINT
# ===================================================================
# Remove the EXIT trap — it fires on every exit including Ctrl+C from read
trap - EXIT
trap cleanup SIGINT SIGTERM

# Run it
main_menu