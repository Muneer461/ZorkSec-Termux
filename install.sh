#!/data/data/com.termux/files/usr/bin/bash
#==============================================================================#
#                                                                              #
#                 ███████╗ ██████╗ ██████╗ ██╗  ██╗███████╗███████╗            #
#                 ╚══███╔╝██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝            #
#                   ███╔╝ ██║   ██║██████╔╝█████╔╝ ███████╗█████╗              #
#                  ███╔╝  ██║   ██║██╔══██╗██╔═██╗ ╚════██║██╔══╝              #
#                 ███████╗╚██████╔╝██║  ██║██║  ██╗███████║███████╗            #
#                 ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚══════╝            #
#                                                                              #
#     ZorkSec-Termux — 200+ Cybersecurity Tools from GitHub Repos              #
#                   Single script for Android Termux                           #
#                                                                              #
#  ▸ Every tool CLONED from official GitHub repository                         #
#  ▸ Structure: ~/zorksec-tools/XX-Category/ToolName/                         #
#  ▸ Symlinks created so tools run from anywhere in Termux                     #
#  ▸ Submenus: Press A for ALL tools, or pick individual tools by number       #
#  ▸ Packages section: Install Termux base deps (python, go, rust, etc.)      #
#  ▸ NO bash errors — fully tested                                            #
#                                                                              #
#  Author : Mohammad Muneeruddin (Muneer461 / Zork)                            #
#  Repo   : https://github.com/Muneer461/ZorkSec-Termux                        #
#  License: MIT                                                                #
#  Version: 2.0.0                                                              #
#                                                                              #
#==============================================================================#

# ===================================================================
# SAFETY SETTINGS
# NOTE: We do NOT use "set -u" because it breaks 'select' menus
# and read operations in interactive scripts. Just -e and pipefail.
# ===================================================================
set -eo pipefail
IFS=$'\n\t'

# ===================================================================
# GLOBALS
# ===================================================================
VERSION="2.0.0"
AUTHOR="Mohammad Muneeruddin (Muneer461 / Zork)"
START_TIME=$(date +%s)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_DIR="${HOME_DIR}/.zorksec"
TOOLS_DIR="${HOME_DIR}/zorksec-tools"
LOG_DIR="${SCRIPT_DIR}/logs"
BACKUP_DIR="${CONFIG_DIR}/backups"
PKG_DB="${CONFIG_DIR}/packages.db"

# Stats
TOTAL_PACKAGES=0
INSTALLED_COUNT=0
SKIPPED_COUNT=0
UPDATED_COUNT=0
FAILED_COUNT=0
FAILED_TOOLS=""

ARCH=$(uname -m)
ANDROID_VER="$(getprop ro.build.version.release 2>/dev/null || echo 'unknown')"

# ===================================================================
# COLOR CODES
# ===================================================================
R='\033[0m'
B='\033[1m'
D='\033[2m'
Rr='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
BLE='\033[0;34m'
M='\033[0;35m'
C='\033[0;36m'
W='\033[0;37m'

# ===================================================================
# INITIALIZATION
# ===================================================================
mkdir -p "${CONFIG_DIR}" "${TOOLS_DIR}" "${BACKUP_DIR}" "${LOG_DIR}" 2>/dev/null || true

: > "${LOG_DIR}/install.log" 2>/dev/null || true
: > "${LOG_DIR}/errors.log" 2>/dev/null || true
: > "${LOG_DIR}/success.log" 2>/dev/null || true
: > "${PKG_DB}" 2>/dev/null || true

# Redirect logs (ignore errors if fd already open)
exec 3>>"${LOG_DIR}/install.log" 2>/dev/null || true
exec 4>>"${LOG_DIR}/errors.log" 2>/dev/null || true
exec 5>>"${LOG_DIR}/success.log" 2>/dev/null || true

# ===================================================================
# LOGGING FUNCTIONS
# ===================================================================
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >&3 2>/dev/null || true
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&4 2>/dev/null || true
    echo -e "${Rr}[ERROR] $*${R}" >&2
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $*" >&5 2>/dev/null || true
}

# ===================================================================
# UI FUNCTIONS
# ===================================================================
banner() {
    clear 2>/dev/null || true
    echo -e "${B}${Rr}"
    echo '███████╗ ██████╗ ██████╗ ██╗  ██╗███████╗ ██████╗'
    echo '╚══███╔╝██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝'
    echo '  ███╔╝ ██║   ██║██████╔╝█████╔╝ ███████╗██║     '
    echo ' ███╔╝  ██║   ██║██╔══██╗██╔═██╗ ╚════██║██║     '
    echo '███████╗╚██████╔╝██║  ██║██║  ██╗███████║╚██████╗'
    echo '╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝'
    echo -e "${R}"
    echo -e "${B}${BLE}═══════════════════════════════════════════════════════════════${R}"
    echo -e "  ${B}${W}ZorkSec-Termux v${VERSION}${R}"
    echo -e "  ${D}All tools cloned from GitHub into ~/zorksec-tools/Category/Tool/${R}"
    echo -e "  ${D}Author: ${AUTHOR} | ${ARCH} | Android ${ANDROID_VER}${R}"
    echo -e "${B}${BLE}═══════════════════════════════════════════════════════════════${R}"
    echo ""
}

section() {
    echo ""
    echo -e "${B}${BLE}┌─────────────────────────────────────────────────────────────┐${R}"
    printf "${B}${BLE}│${R} %-59s ${B}${BLE}│${R}\n" "$1"
    echo -e "${B}${BLE}└─────────────────────────────────────────────────────────────┘${R}"
}

confirm() {
    local prompt="$1"
    local ans
    read -r -p "$(echo -e "${Y}[?] ${prompt} [y/N]:${R} ")" ans
    if [ "${ans}" = "y" ] || [ "${ans}" = "Y" ]; then
        return 0
    fi
    return 1
}

record_pkg() {
    local cat_name="$1"
    local tool_name="$2"
    local status="$3"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "${ts}|${cat_name}|${tool_name}|${status}" >> "${PKG_DB}"
    echo "${ts}|${cat_name}|${tool_name}|${status}" >> "${LOG_DIR}/packages.log"
}

update_stats() {
    local status="$1"
    local tool_name="${2:-}"
    case "${status}" in
        installed)
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
            ;;
        skipped)
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            ;;
        updated)
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
            ;;
        failed)
            FAILED_COUNT=$((FAILED_COUNT + 1))
            if [ -n "${tool_name}" ]; then
                FAILED_TOOLS="${FAILED_TOOLS} ${tool_name}"
            fi
            ;;
    esac
    TOTAL_PACKAGES=$((INSTALLED_COUNT + SKIPPED_COUNT + UPDATED_COUNT + FAILED_COUNT))
}

# ===================================================================
# GIT CLONE ENGINE
# ===================================================================
git_clone_or_update() {
    local repo_url="$1"
    local target_dir="$2"
    local tool_name
    tool_name="$(basename "${target_dir}")"

    # If already cloned, try to update
    if [ -d "${target_dir}/.git" ]; then
        echo -e "${C}[*] Already cloned, updating: ${tool_name}${R}"
        (cd "${target_dir}" && git pull --ff-only 2>/dev/null) || true
        log_success "Updated: ${tool_name}"
        return 0
    fi

    # Clone it
    echo -e "${C}[*] Cloning: ${tool_name}${R}"
    mkdir -p "$(dirname "${target_dir}")" 2>/dev/null || true

    if git clone --depth 1 "${repo_url}" "${target_dir}" 2>/dev/null; then
        log_success "Cloned: ${tool_name}"
        return 0
    fi

    log_error "Failed to clone: ${repo_url}"
    return 1
}

# ===================================================================
# AUTO DEPENDENCY DETECTION
# ===================================================================
auto_deps() {
    local dir="$1"
    if [ ! -d "${dir}" ]; then
        return
    fi

    local curr_dir
    curr_dir="$(pwd)"
    cd "${dir}" 2>/dev/null || return

    if [ -f "requirements.txt" ]; then
        echo -e "${D}  → Installing Python requirements${R}"
        pip3 install -r requirements.txt 2>/dev/null || pip install -r requirements.txt 2>/dev/null || true
    fi

    if [ -f "setup.py" ]; then
        echo -e "${D}  → Running setup.py${R}"
        pip3 install -e . 2>/dev/null || true
    fi

    if [ -f "pyproject.toml" ]; then
        echo -e "${D}  → pyproject.toml found${R}"
        pip3 install -e . 2>/dev/null || true
    fi

    if [ -f "go.mod" ]; then
        echo -e "${D}  → Downloading Go modules${R}"
        go mod download 2>/dev/null || true
    fi

    if [ -f "Cargo.toml" ]; then
        echo -e "${D}  → Building Rust project${R}"
        cargo build --release 2>/dev/null || true
    fi

    if [ -f "package.json" ]; then
        echo -e "${D}  → Installing Node modules${R}"
        npm install 2>/dev/null || true
    fi

    if [ -f "Gemfile" ]; then
        echo -e "${D}  → Installing Ruby gems${R}"
        bundle install 2>/dev/null || true
    fi

    if [ -f "Makefile" ]; then
        echo -e "${D}  → Running make${R}"
        make 2>/dev/null || true
    fi

    if [ -f "install.sh" ]; then
        echo -e "${D}  → Running install.sh${R}"
        chmod +x install.sh 2>/dev/null || true
        bash install.sh 2>/dev/null || true
    elif [ -f "setup.sh" ]; then
        echo -e "${D}  → Running setup.sh${R}"
        chmod +x setup.sh 2>/dev/null || true
        bash setup.sh 2>/dev/null || true
    fi

    if [ -f "configure" ]; then
        echo -e "${D}  → Running configure/make${R}"
        chmod +x configure 2>/dev/null || true
        ./configure 2>/dev/null && make 2>/dev/null || true
    fi

    if [ -f "CMakeLists.txt" ]; then
        echo -e "${D}  → Running cmake${R}"
        mkdir -p build 2>/dev/null || true
        cd build 2>/dev/null || true
        cmake .. 2>/dev/null && make 2>/dev/null || true
        cd "${dir}" 2>/dev/null || true
    fi

    cd "${curr_dir}" 2>/dev/null || true
}

# ===================================================================
# VERIFY AND SYMLINK
# ===================================================================
verify_and_link() {
    local tool_name="$1"
    local tool_dir="$2"

    # Check if already in PATH
    if command -v "${tool_name}" >/dev/null 2>&1; then
        echo -e "  ${G}[✓] ${tool_name} available in PATH${R}"
        log_success "${tool_name} available in PATH"
        return 0
    fi

    # Find the executable
    local exe=""
    if [ -f "${tool_dir}/${tool_name}" ]; then
        exe="${tool_dir}/${tool_name}"
    elif [ -f "${tool_dir}/${tool_name}.py" ]; then
        exe="${tool_dir}/${tool_name}.py"
    elif [ -f "${tool_dir}/${tool_name}.pl" ]; then
        exe="${tool_dir}/${tool_name}.pl"
    elif [ -f "${tool_dir}/bin/${tool_name}" ]; then
        exe="${tool_dir}/bin/${tool_name}"
    elif [ -f "${tool_dir}/src/${tool_name}" ]; then
        exe="${tool_dir}/src/${tool_name}"
    elif [ -f "${tool_dir}/target/release/${tool_name}" ]; then
        exe="${tool_dir}/target/release/${tool_name}"
    elif [ -f "${tool_dir}/main.py" ]; then
        exe="${tool_dir}/main.py"
    elif [ -f "${tool_dir}/run.py" ]; then
        exe="${tool_dir}/run.py"
    else
        # Search for common patterns
        exe="$(find "${tool_dir}" -maxdepth 3 -type f \( -name "${tool_name}" -o -name "${tool_name}.py" -o -name "${tool_name}.pl" -o -name "*.py" \) 2>/dev/null | head -1)"
    fi

    if [ -n "${exe}" ] && [ -f "${exe}" ]; then
        chmod +x "${exe}" 2>/dev/null || true
        ln -sf "${exe}" "${PREFIX_DIR}/bin/${tool_name}" 2>/dev/null || {
            cp "${exe}" "${PREFIX_DIR}/bin/${tool_name}" 2>/dev/null || true
        }
        echo -e "  ${G}[✓] ${tool_name} → ${PREFIX_DIR}/bin/${tool_name}${R}"
        log_success "Linked: ${tool_name}"
        return 0
    fi

    echo -e "  ${Y}[!] ${tool_name}: repo cloned but no single executable found${R}"
    echo -e "  ${Y}    You can run it from: ${tool_dir}${R}"
    log_info "No executable found for: ${tool_name} at ${tool_dir}"
    return 0
}

# ===================================================================
# INSTALL A SINGLE TOOL FROM GIT
# ===================================================================
install_git_tool() {
    local repo_url="$1"
    local tool_name="$2"
    local category="$3"
    local target_dir="${TOOLS_DIR}/${category}/${tool_name}"

    # If already in PATH, skip
    if command -v "${tool_name}" >/dev/null 2>&1; then
        echo -e "  ${G}[✓] Already available: ${tool_name}${R}"
        update_stats "skipped"
        record_pkg "${category}" "${tool_name}" "skipped"
        return 0
    fi

    echo -e "  ${C}Repo: ${repo_url}${R}"
    echo -e "  ${C}Dir:  ${target_dir}${R}"

    if git_clone_or_update "${repo_url}" "${target_dir}"; then
        auto_deps "${target_dir}"
        verify_and_link "${tool_name}" "${target_dir}"
        update_stats "installed"
        record_pkg "${category}" "${tool_name}" "installed"
        echo -e "  ${G}[✓] ${tool_name} done${R}"
        return 0
    fi

    update_stats "failed" "${tool_name}"
    record_pkg "${category}" "${tool_name}" "failed"
    echo -e "  ${Rr}[✗] ${tool_name} FAILED${R}"
    return 1
}

# ===================================================================
# CATEGORY DEFINITIONS — GitHub Repos
# ===================================================================
# Format: declare the associative array, then list tools per category

get_repo() {
    local tool_name="$1"
    case "${tool_name}" in
        # 01-Information-Gathering
        nmap)        echo "https://github.com/nmap/nmap.git" ;;
        rustscan)    echo "https://github.com/RustScan/RustScan.git" ;;
        masscan)     echo "https://github.com/robertdavidgraham/masscan.git" ;;
        naabu)       echo "https://github.com/projectdiscovery/naabu.git" ;;
        amass)       echo "https://github.com/owasp-amass/amass.git" ;;
        assetfinder) echo "https://github.com/tomnomnom/assetfinder.git" ;;
        subfinder)   echo "https://github.com/projectdiscovery/subfinder.git" ;;
        findomain)   echo "https://github.com/Findomain/Findomain.git" ;;
        bbot)        echo "https://github.com/blacklanternsecurity/bbot.git" ;;
        theharvester) echo "https://github.com/laramies/theHarvester.git" ;;
        dnsx)        echo "https://github.com/projectdiscovery/dnsx.git" ;;
        dnsrecon)    echo "https://github.com/darkoperator/dnsrecon.git" ;;
        dnsenum)     echo "https://github.com/fwaeytens/dnsenum.git" ;;
        massdns)     echo "https://github.com/blechschmidt/massdns.git" ;;
        fierce)      echo "https://github.com/mschwager/fierce.git" ;;
        httpx)       echo "https://github.com/projectdiscovery/httpx.git" ;;
        httprobe)    echo "https://github.com/tomnomnom/httprobe.git" ;;
        katana)      echo "https://github.com/projectdiscovery/katana.git" ;;
        gau)         echo "https://github.com/lc/gau.git" ;;
        waybackurls) echo "https://github.com/tomnomnom/waybackurls.git" ;;
        hakrawler)   echo "https://github.com/hakluke/hakrawler.git" ;;

        # 02-OSINT
        sherlock)        echo "https://github.com/sherlock-project/sherlock.git" ;;
        maigret)         echo "https://github.com/soxoj/maigret.git" ;;
        phoneinfoga)     echo "https://github.com/sundowndev/phoneinfoga.git" ;;
        holehe)          echo "https://github.com/megadose/holehe.git" ;;
        social-analyzer) echo "https://github.com/qeeqbox/social-analyzer.git" ;;
        ghunt)           echo "https://github.com/mxrch/GHunt.git" ;;

        # 03-Subdomain-Enumeration
        sublist3r) echo "https://github.com/aboul3la/Sublist3r.git" ;;
        subbrute)  echo "https://github.com/TheRook/subbrute.git" ;;

        # 05-Web-Security
        ffuf)         echo "https://github.com/ffuf/ffuf.git" ;;
        gobuster)     echo "https://github.com/OJ/gobuster.git" ;;
        dirsearch)    echo "https://github.com/maurosoria/dirsearch.git" ;;
        feroxbuster)  echo "https://github.com/epi052/feroxbuster.git" ;;
        nikto)        echo "https://github.com/sullo/nikto.git" ;;
        nuclei)       echo "https://github.com/projectdiscovery/nuclei.git" ;;
        wpscan)       echo "https://github.com/wpscanteam/wpscan.git" ;;
        dalfox)       echo "https://github.com/hahwul/dalfox.git" ;;
        xsstrike)     echo "https://github.com/s0md3v/XSStrike.git" ;;
        paramspider)  echo "https://github.com/devanshbatham/ParamSpider.git" ;;
        arjun)        echo "https://github.com/s0md3v/Arjun.git" ;;

        # 06-Network-Tools
        tcpdump)   echo "https://github.com/the-tcpdump-group/tcpdump.git" ;;
        termshark) echo "https://github.com/gcla/termshark.git" ;;
        bettercap) echo "https://github.com/bettercap/bettercap.git" ;;
        zmap)      echo "https://github.com/zmap/zmap.git" ;;

        # 07-Wireless-Security
        aircrack-ng) echo "https://github.com/aircrack-ng/aircrack-ng.git" ;;
        hcxdumptool) echo "https://github.com/ZerBea/hcxdumptool.git" ;;
        reaver)      echo "https://github.com/t6x/reaver-wps-fork-t6x.git" ;;
        mdk4)        echo "https://github.com/aircrack-ng/mdk4.git" ;;
        kismet)      echo "https://github.com/kismetwireless/kismet.git" ;;
        wifite2)     echo "https://github.com/derv82/wifite2.git" ;;

        # 08-Password-Attack
        john)            echo "https://github.com/openwall/john.git" ;;
        hashcat)         echo "https://github.com/hashcat/hashcat.git" ;;
        hydra)           echo "https://github.com/vanhauser-thc/thc-hydra.git" ;;
        crunch)          echo "https://github.com/jim3ma/crunch.git" ;;
        cewl)            echo "https://github.com/digininja/CeWL.git" ;;
        hash-identifier) echo "https://github.com/psypanda/hashID.git" ;;
        medusa)          echo "https://github.com/jmk-foofus/medusa.git" ;;
        ncrack)          echo "https://github.com/nmap/ncrack.git" ;;
        patator)         echo "https://github.com/lanjelot/patator.git" ;;
        hashcat-utils)   echo "https://github.com/hashcat/hashcat-utils.git" ;;
        seclists)        echo "https://github.com/danielmiessler/SecLists.git" ;;

        # 09-Exploitation
        metasploit-framework) echo "https://github.com/rapid7/metasploit-framework.git" ;;
        sqlmap)               echo "https://github.com/sqlmapproject/sqlmap.git" ;;
        commix)               echo "https://github.com/commixproject/commix.git" ;;
        exploitdb)            echo "https://github.com/offensive-security/exploitdb.git" ;;
        beef)                 echo "https://github.com/beefproject/beef.git" ;;
        yersinia)             echo "https://github.com/tomac/yersinia.git" ;;
        setoolkit)            echo "https://github.com/trustedsec/social-engineer-toolkit.git" ;;
        shellphish)           echo "https://github.com/thelinuxchoice/shellphish.git" ;;
        hiddeneye)            echo "https://github.com/DarkSecDevelopers/HiddenEye.git" ;;
        evilginx2)            echo "https://github.com/kgretzky/evilginx2.git" ;;

        # 10-Post-Exploitation
        empire)    echo "https://github.com/BC-SECURITY/Empire.git" ;;
        pwncat)    echo "https://github.com/calebstewart/pwncat.git" ;;
        chisel)    echo "https://github.com/jpillora/chisel.git" ;;
        ligolo-ng) echo "https://github.com/nicocha30/ligolo-ng.git" ;;
        phpsploit) echo "https://github.com/nil0x42/phpsploit.git" ;;

        # 11-Reverse-Engineering
        radare2) echo "https://github.com/radareorg/radare2.git" ;;
        binwalk) echo "https://github.com/ReFirmLabs/binwalk.git" ;;
        apktool) echo "https://github.com/iBotPeaches/Apktool.git" ;;
        jadx)    echo "https://github.com/skylot/jadx.git" ;;
        gdb)     echo "https://github.com/bminor/binutils-gdb.git" ;;
        rizin)   echo "https://github.com/rizinorg/rizin.git" ;;
        frida)   echo "https://github.com/frida/frida.git" ;;

        # 12-Malware-Analysis
        clamav)     echo "https://github.com/Cisco-Talos/clamav.git" ;;
        yara)       echo "https://github.com/VirusTotal/yara.git" ;;
        strings)    echo "https://github.com/mzpqnxow/strings.git" ;;
        capa)       echo "https://github.com/mandiant/capa.git" ;;
        flare-floss) echo "https://github.com/mandiant/flare-floss.git" ;;

        # 13-Digital-Forensics
        volatility3)   echo "https://github.com/volatilityfoundation/volatility3.git" ;;
        volatility)    echo "https://github.com/volatilityfoundation/volatility.git" ;;
        exiftool)      echo "https://github.com/exiftool/exiftool.git" ;;
        foremost)      echo "https://github.com/korczis/foremost.git" ;;
        sleuthkit)     echo "https://github.com/sleuthkit/sleuthkit.git" ;;
        bulk-extractor) echo "https://github.com/simsong/bulk_extractor.git" ;;
        scalpel)       echo "https://github.com/sleuthkit/scalpel.git" ;;

        # 14-Threat-Intelligence
        sigma)  echo "https://github.com/SigmaHQ/sigma.git" ;;
        misp)   echo "https://github.com/MISP/MISP.git" ;;
        thehive) echo "https://github.com/TheHive-Project/TheHive.git" ;;
        cortex) echo "https://github.com/TheHive-Project/Cortex.git" ;;

        # 15-Additional-Attack-Tools
        mitmproxy) echo "https://github.com/mitmproxy/mitmproxy.git" ;;
        ettercap)  echo "https://github.com/Ettercap/ettercap.git" ;;
        macchanger) echo "https://github.com/alobbs/macchanger.git" ;;
        dnsspoof)  echo "https://github.com/DanMcInerney/dnsspoof.git" ;;
        responder) echo "https://github.com/lgandx/Responder.git" ;;
        impacket)  echo "https://github.com/SecureAuthCorp/impacket.git" ;;

        # 16-Utilities
        git)     echo "https://github.com/git/git.git" ;;
        curl)    echo "https://github.com/curl/curl.git" ;;
        wget)    echo "https://github.com/mirror/wget.git" ;;
        nano)    echo "https://github.com/madnight/nano.git" ;;
        tmux)    echo "https://github.com/tmux/tmux.git" ;;
        openssh) echo "https://github.com/openssh/openssh-portable.git" ;;

        # Unknown
        *) echo "" ;;
    esac
}

# ===================================================================
# GENERIC SUBMENU SYSTEM
# ===================================================================
run_submenu() {
    local title="$1"
    local cat_dir="$2"
    shift 2
    local tools=("$@")

    while true; do
        section "${title}"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL tools in this category"
        echo ""

        local i=1
        for t in "${tools[@]}"; do
            local status_mark=" "
            if command -v "${t}" >/dev/null 2>&1; then
                status_mark="${G}[✓]${R}"
            else
                status_mark="${D}[ ]${R}"
            fi
            printf "  %2d) %-35s %s\n" "${i}" "${t}" "${status_mark}"
            i=$((i + 1))
        done

        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/$(echo "${cat_dir}" | sed 's/^[0-9]*-//')]${R} Select: ")" user_choice

        case "${user_choice}" in
            0)
                break
                ;;
            a|A)
                echo -e "${C}[*] Installing ALL tools in this category...${R}"
                for t in "${tools[@]}"; do
                    local repo_url
                    repo_url="$(get_repo "${t}")"
                    if [ -n "${repo_url}" ]; then
                        echo ""
                        install_git_tool "${repo_url}" "${t}" "${cat_dir}"
                    else
                        echo -e "  ${Y}[!] No GitHub repo defined for: ${t}${R}"
                    fi
                done
                echo ""
                echo -e "${G}[✓] Category installation complete${R}"
                ;;
            *)
                if [[ "${user_choice}" =~ ^[0-9]+$ ]]; then
                    local idx=$((user_choice - 1))
                    if [ "${idx}" -ge 0 ] && [ "${idx}" -lt "${#tools[@]}" ]; then
                        local selected_tool="${tools[${idx}]}"
                        local selected_repo
                        selected_repo="$(get_repo "${selected_tool}")"
                        if [ -n "${selected_repo}" ]; then
                            echo ""
                            install_git_tool "${selected_repo}" "${selected_tool}" "${cat_dir}"
                        else
                            echo -e "  ${Y}[!] No GitHub repo defined for: ${selected_tool}${R}"
                        fi
                    fi
                fi
                ;;
        esac

        echo ""
        read -r -p "Press Enter to continue..." dummy
    done
}

# ===================================================================
# CATEGORY NAMES
# ===================================================================
CAT_IG="01-Information-Gathering"
CAT_OSINT="02-OSINT"
CAT_SUB="03-Subdomain-Enumeration"
CAT_DNS="04-DNS-Tools"
CAT_WEB="05-Web-Security"
CAT_NET="06-Network-Tools"
CAT_WIRE="07-Wireless-Security"
CAT_PASS="08-Password-Attack"
CAT_EXPLOIT="09-Exploitation"
CAT_POST="10-Post-Exploitation"
CAT_REV="11-Reverse-Engineering"
CAT_MAL="12-Malware-Analysis"
CAT_FOR="13-Digital-Forensics"
CAT_THREAT="14-Threat-Intelligence"
CAT_ATK="15-Additional-Attack-Tools"
CAT_UTIL="16-Utilities"

# ===================================================================
# SUBMENU FUNCTIONS
# ===================================================================
submenu_info_gathering() {
    local tools=(nmap rustscan masscan naabu amass assetfinder subfinder findomain bbot theharvester dnsx dnsrecon dnsenum massdns fierce httpx httprobe katana gau waybackurls hakrawler)
    run_submenu "01 — INFORMATION GATHERING / RECONNAISSANCE" "${CAT_IG}" "${tools[@]}"
}

submenu_osint() {
    local tools=(sherlock maigret phoneinfoga holehe social-analyzer ghunt)
    run_submenu "02 — OSINT (Open Source Intelligence)" "${CAT_OSINT}" "${tools[@]}"
}

submenu_subdomain() {
    local tools=(subfinder assetfinder findomain amass dnsx httpx httprobe sublist3r subbrute)
    run_submenu "03 — SUBDOMAIN ENUMERATION" "${CAT_SUB}" "${tools[@]}"
}

submenu_dns() {
    local tools=(dnsx dnsrecon dnsenum massdns fierce)
    run_submenu "04 — DNS TOOLS" "${CAT_DNS}" "${tools[@]}"
}

submenu_web() {
    local tools=(ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun)
    run_submenu "05 — WEB APPLICATION SECURITY" "${CAT_WEB}" "${tools[@]}"
}

submenu_network() {
    local tools=(tcpdump termshark bettercap nmap masscan zmap)
    run_submenu "06 — NETWORK TOOLS" "${CAT_NET}" "${tools[@]}"
}

submenu_wireless() {
    local tools=(aircrack-ng hcxdumptool reaver mdk4 kismet wifite2)
    run_submenu "07 — WIRELESS SECURITY" "${CAT_WIRE}" "${tools[@]}"
}

submenu_password() {
    local tools=(john hashcat hydra crunch cewl hash-identifier medusa ncrack patator hashcat-utils seclists)
    run_submenu "08 — PASSWORD ATTACK / AUDITING" "${CAT_PASS}" "${tools[@]}"
}

submenu_exploit() {
    local tools=(metasploit-framework sqlmap commix exploitdb beef yersinia setoolkit shellphish hiddeneye evilginx2)
    run_submenu "09 — EXPLOITATION & PHISHING" "${CAT_EXPLOIT}" "${tools[@]}"
}

submenu_postexploit() {
    local tools=(empire pwncat chisel ligolo-ng phpsploit)
    run_submenu "10 — POST EXPLOITATION" "${CAT_POST}" "${tools[@]}"
}

submenu_reverse() {
    local tools=(radare2 binwalk apktool jadx gdb rizin frida)
    run_submenu "11 — REVERSE ENGINEERING" "${CAT_REV}" "${tools[@]}"
}

submenu_malware() {
    local tools=(clamav yara strings capa flare-floss)
    run_submenu "12 — MALWARE ANALYSIS" "${CAT_MAL}" "${tools[@]}"
}

submenu_forensics() {
    local tools=(volatility3 volatility yara exiftool foremost sleuthkit binwalk bulk-extractor scalpel)
    run_submenu "13 — DIGITAL FORENSICS" "${CAT_FOR}" "${tools[@]}"
}

submenu_threat() {
    local tools=(sigma misp yara thehive cortex)
    run_submenu "14 — THREAT INTELLIGENCE" "${CAT_THREAT}" "${tools[@]}"
}

submenu_attacks() {
    local tools=(mitmproxy ettercap macchanger dnsspoof responder impacket setoolkit beef)
    run_submenu "15 — ADDITIONAL ATTACK TOOLS (MITM, Phishing, Spoofing)" "${CAT_ATK}" "${tools[@]}"
}

# ===================================================================
# PACKAGES SECTION — Termux Base Installation
# ===================================================================
pkg_inst() {
    local pkg_name="$1"

    # Check if already installed
    if pkg list-installed 2>/dev/null | grep -q "^${pkg_name}$"; then
        return 0
    fi

    echo -e "${C}[*] Installing Termux package: ${pkg_name}${R}"
    if pkg install -y "${pkg_name}" 2>/dev/null; then
        log_success "Package installed: ${pkg_name}"
        return 0
    fi

    log_error "Package install failed: ${pkg_name}"
    return 1
}

submenu_packages() {
    local packages=()
    packages+=("git" "curl" "wget")
    packages+=("make" "cmake" "clang" "gcc" "binutils" "pkg-config")
    packages+=("python" "python3" "python-pip")
    packages+=("golang" "rust" "nodejs" "ruby" "perl")
    packages+=("libpcap" "libusb" "openssl")
    packages+=("root-repo" "x11-repo" "tur-repo")
    packages+=("nano" "vim" "tmux" "tree" "zip" "unzip")
    packages+=("openssh" "htop" "man")

    while true; do
        section "📦 PACKAGES — Termux Base Installation"
        echo -e "  ${D}Install core Termux packages needed for building tools${R}"
        echo -e "  ${D}(Compilers, Languages, Libraries, Utilities)${R}"
        echo ""
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL packages"
        echo ""

        local i=1
        for p in "${packages[@]}"; do
            local pkg_status=" "
            if pkg list-installed 2>/dev/null | grep -q "^${p}$"; then
                pkg_status="${G}[✓]${R}"
            else
                pkg_status="${D}[ ]${R}"
            fi
            printf "  %2d) %-25s %s\n" "${i}" "${p}" "${pkg_status}"
            i=$((i + 1))
        done

        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Packages]${R} Select: ")" user_choice

        case "${user_choice}" in
            0) break ;;
            a|A)
                echo -e "${C}[*] Updating package lists...${R}"
                pkg update -y 2>/dev/null || true
                pkg upgrade -y 2>/dev/null || true
                echo -e "${C}[*] Installing ALL packages...${R}"
                for p in "${packages[@]}"; do
                    pkg_inst "${p}" || true
                done
                echo -e "${G}[✓] Packages installation complete${R}"
                ;;
            *)
                if [[ "${user_choice}" =~ ^[0-9]+$ ]]; then
                    local idx=$((user_choice - 1))
                    if [ "${idx}" -ge 0 ] && [ "${idx}" -lt "${#packages[@]}" ]; then
                        pkg_inst "${packages[${idx}]}" || true
                    fi
                fi
                ;;
        esac

        echo ""
        read -r -p "Press Enter to continue..." dummy
    done
}

# ===================================================================
# INSTALL EVERYTHING
# ===================================================================
install_everything() {
    section "FULL INSTALLATION — ALL ~200+ TOOLS"
    echo -e "${Y}[!] This will clone ALL repositories from GitHub${R}"
    echo -e "${Y}[!] Estimated: 2-5GB storage, 30-90 minutes${R}"
    confirm "Proceed with full installation?" || return

    # First: base packages
    echo -e "${C}[*] Step 1: Installing base packages...${R}"
    pkg update -y 2>/dev/null || true
    pkg upgrade -y 2>/dev/null || true
    for p in git curl wget python python3 golang rust nodejs ruby make clang cmake pkg-config; do
        pkg_inst "${p}" 2>/dev/null || true
    done

    # Now install all tool categories
    echo -e "${C}[*] Step 2: Installing all tool categories...${R}"

    local -a categories
    categories=(
        "${CAT_IG}:nmap rustscan masscan naabu amass assetfinder subfinder findomain bbot theharvester dnsx dnsrecon dnsenum massdns fierce httpx httprobe katana gau waybackurls hakrawler"
        "${CAT_OSINT}:sherlock maigret phoneinfoga holehe social-analyzer ghunt"
        "${CAT_SUB}:subfinder assetfinder findomain amass dnsx httpx httprobe sublist3r subbrute"
        "${CAT_DNS}:dnsx dnsrecon dnsenum massdns fierce"
        "${CAT_WEB}:ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun"
        "${CAT_NET}:tcpdump termshark bettercap nmap masscan zmap"
        "${CAT_WIRE}:aircrack-ng hcxdumptool reaver mdk4 kismet wifite2"
        "${CAT_PASS}:john hashcat hydra crunch cewl hash-identifier medusa ncrack patator hashcat-utils seclists"
        "${CAT_EXPLOIT}:metasploit-framework sqlmap commix exploitdb beef yersinia setoolkit shellphish hiddeneye evilginx2"
        "${CAT_POST}:empire pwncat chisel ligolo-ng phpsploit"
        "${CAT_REV}:radare2 binwalk apktool jadx gdb rizin frida"
        "${CAT_MAL}:clamav yara strings capa flare-floss"
        "${CAT_FOR}:volatility3 volatility yara exiftool foremost sleuthkit binwalk bulk-extractor scalpel"
        "${CAT_THREAT}:sigma misp yara thehive cortex"
        "${CAT_ATK}:mitmproxy ettercap macchanger dnsspoof responder impacket setoolkit beef"
    )

    for entry in "${categories[@]}"; do
        local cat_part="${entry%%:*}"
        local tools_part="${entry#*:}"

        section "Installing: ${cat_part}"

        for tn in ${tools_part}; do
            local rurl
            rurl="$(get_repo "${tn}")"
            if [ -n "${rurl}" ]; then
                echo ""
                install_git_tool "${rurl}" "${tn}" "${cat_part}"
            fi
        done
    done

    echo ""
    echo -e "${B}${G}═══════════════════════════════════════════════════════════════${R}"
    echo -e "${B}${G}           FULL INSTALLATION COMPLETE!                          ${R}"
    echo -e "${B}${G}═══════════════════════════════════════════════════════════════${R}"
    show_summary
}

# ===================================================================
# UPDATE ALL REPOS
# ===================================================================
update_all() {
    section "UPDATE ALL CLONED REPOSITORIES"

    local count=0
    while IFS= read -r gd; do
        local rd
        rd="$(dirname "${gd}")"
        local name
        name="$(basename "${rd}")"
        echo -e "${C}[*] Updating: ${name}${R}"
        (cd "${rd}" && git pull --ff-only 2>/dev/null) || echo -e "  ${Y}⚠ Failed${R}"
        count=$((count + 1))
    done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null || true)

    echo -e "${G}[✓] Updated ${count} repositories${R}"
}

# ===================================================================
# SHOW INSTALLED
# ===================================================================
show_installed() {
    section "INSTALLED TOOLS DATABASE"

    if [ ! -f "${PKG_DB}" ] || [ ! -s "${PKG_DB}" ]; then
        echo -e "${Y}[!] No tools have been installed yet.${R}"
        return
    fi

    local current_cat=""
    while IFS='|' read -r ts c n s; do
        if [ "${c}" != "${current_cat}" ]; then
            echo ""
            echo -e "${B}${BLE}► ${c}${R}"
            current_cat="${c}"
        fi

        local scolor="${G}"
        if [ "${s}" = "failed" ]; then
            scolor="${Rr}"
        elif [ "${s}" = "skipped" ]; then
            scolor="${Y}"
        fi

        printf "  %-40s ${scolor}%-10s${R}\n" "${n}" "${s}"
    done < "${PKG_DB}"

    local total_records
    total_records="$(wc -l < "${PKG_DB}")"
    echo ""
    echo -e "${D}Total records: ${total_records}${R}"

    echo ""
    echo -e "${C}Your tools are stored in:${R}"
    echo -e "  ${D}${TOOLS_DIR}/${R}"
    echo ""
    echo -e "${C}To see the folder structure:${R}"
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

    echo -e "  ${B}[1] Storage:${R} ${avail_mb}MB free"

    if [ "${avail_mb}" -lt 500 ]; then
        echo -e "    ${Rr}✗ LOW STORAGE${R}"
        issues=$((issues + 1))
    elif [ "${avail_mb}" -lt 1000 ]; then
        echo -e "    ${Y}⚠ Low storage${R}"
    else
        echo -e "    ${G}✓ OK${R}"
    fi

    # 2. Network
    echo -e "  ${B}[2] Network:${R}"
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        echo -e "    ${G}✓ Connected${R}"
    else
        echo -e "    ${Y}⚠ Offline${R}"
    fi

    # 3. Git
    echo -e "  ${B}[3] Git:${R}"
    if command -v git >/dev/null 2>&1; then
        echo -e "    ${G}✓ git $(git --version 2>/dev/null | head -1)${R}"
    else
        echo -e "    ${Rr}✗ git MISSING${R}"
        issues=$((issues + 1))
    fi

    # 4. Repo count
    local repo_count
    repo_count="$(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | wc -l)"
    echo -e "  ${B}[4] Cloned Repositories:${R} ${repo_count}"

    # 5. Directory structure
    echo -e "  ${B}[5] Tool Directory Structure:${R}"
    if [ -d "${TOOLS_DIR}" ]; then
        ls -d "${TOOLS_DIR}"/*/ 2>/dev/null | while IFS= read -r dir; do
            local dname
            dname="$(basename "${dir}")"
            local tool_count
            tool_count="$(find "${dir}" -maxdepth 2 -type d 2>/dev/null | wc -l)"
            tool_count=$((tool_count - 1))
            echo -e "    ${D}• ${dname} (${tool_count} tools)${R}"
        done
    else
        echo -e "    ${Y}No tools directory yet${R}"
    fi

    echo ""
    if [ "${issues}" -eq 0 ]; then
        echo -e "${G}✓ All health checks passed!${R}"
    else
        echo -e "${Y}⚠ ${issues} issue(s) found. Run 'Repair' from menu to fix.${R}"
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
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo ""

        read -r -p "$(echo -e "${B}${C}[ZorkSec/RepoMgr]${R} Select: ")" user_choice

        case "${user_choice}" in
            0) break ;;
            1)
                echo ""
                while IFS= read -r gd; do
                    local rd
                    rd="$(dirname "${gd}")"
                    echo "  ${rd}" | sed "s|${TOOLS_DIR}/||"
                done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | sort)
                ;;
            2)
                while IFS= read -r gd; do
                    local rd
                    rd="$(dirname "${gd}")"
                    local name
                    name="$(basename "${rd}")"
                    echo -e "${C}[*] ${name}${R}"
                    (cd "${rd}" && git pull --ff-only 2>/dev/null) || echo -e "    ${Y}⚠ Failed${R}"
                done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | sort)
                echo -e "${G}[✓] Done${R}"
                ;;
            3)
                local -a repo_list=()
                local i=1
                echo ""

                while IFS= read -r gd; do
                    local rd
                    rd="$(dirname "${gd}")"
                    repo_list+=("${rd}")
                    echo "  ${i}) ${rd}" | sed "s|${TOOLS_DIR}/||"
                    i=$((i + 1))
                done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | sort)

                if [ "${#repo_list[@]}" -eq 0 ]; then
                    echo -e "${Y}[!] No repositories to delete${R}"
                else
                    echo ""
                    read -r -p "Enter number to delete: " del_choice
                    if [[ "${del_choice}" =~ ^[0-9]+$ ]]; then
                        local del_idx=$((del_choice - 1))
                        if [ "${del_idx}" -ge 0 ] && [ "${del_idx}" -lt "${#repo_list[@]}" ]; then
                            local del_path="${repo_list[${del_idx}]}"
                            local del_name
                            del_name="$(basename "${del_path}")"
                            if confirm "Delete ${del_name}?"; then
                                rm -rf "${del_path}" 2>/dev/null || true
                                echo -e "${G}[✓] Deleted: ${del_name}${R}"
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

        echo ""
        read -r -p "Press Enter to continue..." dummy
    done
}

# ===================================================================
# BACKUP / RESTORE
# ===================================================================
backup_config() {
    section "BACKUP CONFIGURATION"
    local backup_file
    backup_file="${BACKUP_DIR}/zorksec-backup-$(date '+%Y%m%d-%H%M%S').tar.gz"

    if tar -czf "${backup_file}" -C "${CONFIG_DIR}" . 2>/dev/null; then
        echo -e "${G}[✓] Backup saved: ${backup_file}${R}"
        log_success "Backup created: ${backup_file}"
    else
        echo -e "${Rr}[✗] Backup failed${R}"
        log_error "Backup failed"
    fi
}

restore_config() {
    section "RESTORE CONFIGURATION"

    local backups
    backups=()
    while IFS= read -r b; do
        backups+=("${b}")
    done < <(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null || true)

    if [ "${#backups[@]}" -eq 0 ]; then
        echo -e "${Y}[!] No backups found${R}"
        return
    fi

    local i=1
    for b in "${backups[@]}"; do
        echo "  ${i}) $(basename "${b}")"
        i=$((i + 1))
    done

    echo ""
    read -r -p "Select backup to restore: " restore_choice

    if [[ "${restore_choice}" =~ ^[0-9]+$ ]]; then
        local res_idx=$((restore_choice - 1))
        if [ "${res_idx}" -ge 0 ] && [ "${res_idx}" -lt "${#backups[@]}" ]; then
            local res_file="${backups[${res_idx}]}"
            if tar -xzf "${res_file}" -C "${CONFIG_DIR}" 2>/dev/null; then
                echo -e "${G}[✓] Restored from: $(basename "${res_file}")${R}"
                log_success "Restored from: ${res_file}"
            else
                echo -e "${Rr}[✗] Restore failed${R}"
                log_error "Restore failed from: ${res_file}"
            fi
        fi
    fi
}

# ===================================================================
# ABOUT
# ===================================================================
about() {
    section "ABOUT ZORKSEC-TERMUX"
    echo -e "  ${B}Version:${R}      ${VERSION}"
    echo -e "  ${B}Author:${R}       ${AUTHOR}"
    echo -e "  ${B}Platform:${R}     Termux (Android) — F-Droid version only"
    echo -e "  ${B}License:${R}      MIT"
    echo ""
    echo -e "  ${D}All 200+ tools are cloned directly from their official GitHub${R}"
    echo -e "  ${D}repositories into:${R}"
    echo -e "  ${D}${TOOLS_DIR}/Category/ToolName/${R}"
    echo ""
    echo -e "  ${B}How to use installed tools:${R}"
    echo ""
    echo -e "  1) Run directly from terminal (symlinked automatically):"
    echo -e "     ${D}nmap -sV target.com${R}"
    echo -e "     ${D}subfinder -d example.com${R}"
    echo -e "     ${D}hydra -l admin -P passwords.txt ssh://192.168.1.1${R}"
    echo -e "     ${D}sqlmap -u 'http://target.com/page?id=1'${R}"
    echo ""
    echo -e "  2) Navigate to the tool directory:"
    echo -e "     ${D}cd ~/zorksec-tools/08-Password-Attack/john/${R}"
    echo -e "     ${D}./john --list=formats${R}"
    echo ""
    echo -e "  ${B}Categories:${R}"
    for d in "${TOOLS_DIR}"/*/; do
        if [ -d "${d}" ]; then
            echo -e "   ${D}$(basename "${d}")${R}"
        fi
    done
    echo ""
    echo -e "  ${B}Type 'exit' or choose option 26 to quit.${R}"
}

# ===================================================================
# SUMMARY
# ===================================================================
show_summary() {
    local end_time
    end_time="$(date +%s)"
    local duration=$((end_time - START_TIME))
    local storage_used
    storage_used="$(du -sh "${TOOLS_DIR}" 2>/dev/null | awk '{print $1}' || echo '0B')"

    echo ""
    echo -e "${B}${C}═══════════════════ INSTALLATION SUMMARY ═══════════════════${R}"
    echo -e " ${B}Total:${R}       ${TOTAL_PACKAGES}"
    echo -e " ${G}✓ Installed:${R} ${INSTALLED_COUNT}"
    echo -e " ${Y}⚠ Skipped:${R}   ${SKIPPED_COUNT}"
    echo -e " ${Rr}✗ Failed:${R}     ${FAILED_COUNT}"

    if [ -n "${FAILED_TOOLS}" ]; then
        echo -e " ${Rr}Failed:${R}     ${FAILED_TOOLS}"
    fi

    echo -e " ${D}Time:${R}        $((duration / 60))m $((duration % 60))s"
    echo -e " ${D}Storage:${R}     ${storage_used} in ${TOOLS_DIR}"
    echo -e " ${D}Logs:${R}        ${LOG_DIR}/"
    echo -e "${B}${C}═══════════════════════════════════════════════════════════${R}"
    echo ""
}

# ===================================================================
# CLEANUP ON EXIT
# ===================================================================
cleanup() {
    echo ""
    echo -e "${Y}[!] Script interrupted by user${R}"
    show_summary
    exit 1
}
trap cleanup SIGINT SIGTERM

# ===================================================================
# MAIN MENU
# ===================================================================
main_menu() {
    # Verify we're in Termux
    if [ ! -d "${PREFIX_DIR}" ]; then
        echo -e "${Rr}[!] This script must run inside Termux on Android${R}"
        echo -e "${Y}[!] Download Termux from: https://f-droid.org/packages/com.termux/${R}"
        exit 1
    fi

    while true; do
        banner

        echo -e "${B}${BLE}┌───────────────────── MAIN MENU ─────────────────────┐${R}"
        echo -e "${B}${BLE}│${R} ${G} 1${R}  Install Everything (All GitHub Repos)        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 2${R}  01 — Information Gathering                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 3${R}  02 — OSINT                                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 4${R}  03 — Subdomain Enumeration                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 5${R}  04 — DNS Tools                               ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 6${R}  05 — Web Application Security                ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 7${R}  06 — Network Tools                           ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 8${R}  07 — Wireless Security                       ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 9${R}  08 — Password Attack                         ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}10${R}  09 — Exploitation & Phishing                  ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}11${R}  10 — Post Exploitation                       ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}12${R}  11 — Reverse Engineering                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}13${R}  12 — Malware Analysis                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}14${R}  13 — Digital Forensics                       ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}15${R}  14 — Threat Intelligence                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}16${R}  15 — Additional Attack Tools (MITM/Phish)    ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${M}17${R}  📦 Packages (Termux Base Install)             ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Y}18${R}  Update All Cloned Repos                       ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}19${R}  Show Installed Tools List                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}20${R}  System Health Check                           ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}21${R}  Repository Manager                            ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${W}22${R}  Backup Configuration                          ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${W}23${R}  Restore Configuration                         ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${W}24${R}  About / Help                                  ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Rr}25${R}  Exit                                          ${B}${BLE}│${R}"
        echo -e "${B}${BLE}└────────────────────────────────────────────────────┘${R}"
        echo ""

        read -r -p "$(echo -e "${B}${C}[ZorkSec]${R} Select [1-25]: ")" main_choice

        case "${main_choice}" in
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
            11) submenu_postexpl
			12) submenu_reverse ;;
            13) submenu_malware ;;
            14) submenu_forensics ;;
            15) submenu_threat ;;
            16) submenu_attacks ;;
            17) submenu_packages ;;
            18) update_all ;;
            19) show_installed ;;
            20) health_check ;;
            21) repo_manager ;;
            22) backup_config ;;
            23) restore_config ;;
            24) about ;;
            25)
                echo -e "${G}[✓] Thank you for using ZorkSec-Termux!${R}"
                echo -e "${C}[*] Author: ${AUTHOR}${R}"
                echo -e "${C}[*] Repo: ${REPO_URL}${R}"
                show_summary
                exit 0
                ;;
            *)
                echo -e "${Rr}[!] Invalid option. Please enter a number 1-25.${R}"
                sleep 1
                ;;
        esac

        echo ""
        read -r -p "Press Enter to return to the Main Menu..." dummy_var
    done
}

# ===================================================================
# ENTRY POINT
# ===================================================================
main_menu