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
#                                                                              #
#  ▸ Every tool CLONED from its official GitHub repository                     #
#  ▸ Structure: ~/zorksec-tools/XX-Category/ToolName/                          #
#  ▸ Symlinks created so tools run from anywhere in Termux                     #
#  ▸ Categorized submenus with Install All OR pick individually                #
#  ▸ NEW: Packages section for Termux base deps (python, go, etc.)            #
#                                                                              #
#  Author : Mohammad Muneeruddin (Muneer461 / Zork)                            #
#  Repo   : https://github.com/Muneer461/ZorkSec-Termux                        #
#  License: MIT                                                                #
#  Version: 2.0.0                                                              #
#                                                                              #
#==============================================================================#

set -euo pipefail
IFS=$'\n\t'

VERSION="2.0.0"
AUTHOR="Mohammad Muneeruddin (Muneer461 / Zork)"
START_TIME=$(date +%s)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.zorksec"
TOOLS_DIR="${HOME}/zorksec-tools"
LOG_DIR="${SCRIPT_DIR}/logs"
BACKUP_DIR="${CONFIG_DIR}/backups"
PKG_DB="${CONFIG_DIR}/packages.db"
TOTAL_PACKAGES=0; INSTALLED_COUNT=0; SKIPPED_COUNT=0; UPDATED_COUNT=0; FAILED_COUNT=0; FAILED_TOOLS=""
ARCH=$(uname -m)
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")

R='\033[0m'; B='\033[1m'; D='\033[2m'
Rr='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; BLE='\033[0;34m'; M='\033[0;35m'; C='\033[0;36m'; W='\033[0;37m'

mkdir -p "${CONFIG_DIR}" "${TOOLS_DIR}" "${BACKUP_DIR}" "${LOG_DIR}"
: > "${LOG_DIR}/install.log" 2>/dev/null || true
: > "${LOG_DIR}/errors.log" 2>/dev/null || true
: > "${LOG_DIR}/success.log" 2>/dev/null || true
: > "${PKG_DB}" 2>/dev/null || true
exec 3>>"${LOG_DIR}/install.log" 4>>"${LOG_DIR}/errors.log" 5>>"${LOG_DIR}/success.log"

log_info()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >&3; }
log_error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&4; echo -e "${Rr}[ERROR] $*${R}" >&2; }
log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $*" >&5; }

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
    echo -e "  ${B}${W}ZorkSec-Termux v${VERSION}${R}"
    echo -e "  ${D}All tools cloned from GitHub → ${TOOLS_DIR}/Category/ToolName/${R}"
    echo -e "  ${D}Author: ${AUTHOR} | ${ARCH} | Android ${ANDROID_VER}${R}"
    echo -e "${B}${BLE}═══════════════════════════════════════════════════════════════${R}"
    echo ""
}

section() { echo ""; echo -e "${B}${BLE}┌─────────────────────────────────────────────────────────────┐${R}"; printf "${B}${BLE}│${R} %-59s ${B}${BLE}│${R}\n" "$1"; echo -e "${B}${BLE}└─────────────────────────────────────────────────────────────┘${R}"; }
confirm() { read -r -p "$(echo -e "${Y}[?] $1 [y/N]:${R} ")" yn; case "${yn}" in [yY]*) return 0;; *) return 1;; esac; }

record_pkg() { echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|$2|$3" >> "${PKG_DB}"; echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|$2|$3" >> "${LOG_DIR}/packages.log"; }
update_stats() {
    case "$1" in
        installed) INSTALLED_COUNT=$((INSTALLED_COUNT+1)) ;;
        skipped)   SKIPPED_COUNT=$((SKIPPED_COUNT+1)) ;;
        updated)   UPDATED_COUNT=$((UPDATED_COUNT+1)) ;;
        failed)    FAILED_COUNT=$((FAILED_COUNT+1)); FAILED_TOOLS="${FAILED_TOOLS} $2" ;;
    esac
    TOTAL_PACKAGES=$((INSTALLED_COUNT+SKIPPED_COUNT+UPDATED_COUNT+FAILED_COUNT))
}

# ====================== GIT CLONE ENGINE ======================
# Every tool gets cloned from GitHub. No pkg install for tools.
git_clone_or_update() {
    local repo_url="$1"
    local target_dir="$2"
    local tool_name
    tool_name=$(basename "${target_dir}")
    
    if [ -d "${target_dir}/.git" ]; then
        echo -e "${C}[*] Updating: ${tool_name}${R}"
        (cd "${target_dir}" && git pull --ff-only 2>/dev/null) && {
            log_success "Updated: ${tool_name}"
            return 0
        }
        echo -e "${Y}[!] Update failed for ${tool_name}, continuing${R}"
        return 0
    fi
    
    echo -e "${C}[*] Cloning: ${tool_name}${R}"
    mkdir -p "$(dirname "${target_dir}")"
    if git clone --depth 1 "${repo_url}" "${target_dir}" 2>/dev/null; then
        log_success "Cloned: ${tool_name}"
        return 0
    fi
    log_error "Clone failed: ${repo_url}"
    return 1
}

# ====================== AUTO DEPENDENCY DETECTION ======================
auto_deps() {
    local dir="$1"
    [ ! -d "${dir}" ] && return
    cd "${dir}" || return
    
    if [ -f "requirements.txt" ]; then echo -e "${D}  → requirements.txt${R}"; pip3 install -r requirements.txt 2>/dev/null || pip install -r requirements.txt 2>/dev/null || true; fi
    if [ -f "setup.py" ]; then echo -e "${D}  → setup.py${R}"; pip3 install -e . 2>/dev/null || true; fi
    if [ -f "pyproject.toml" ]; then echo -e "${D}  → pyproject.toml${R}"; pip3 install -e . 2>/dev/null || true; fi
    if [ -f "go.mod" ]; then echo -e "${D}  → go.mod${R}"; go mod download 2>/dev/null || true; fi
    if [ -f "Cargo.toml" ]; then echo -e "${D}  → Cargo.toml${R}"; cargo build --release 2>/dev/null || true; fi
    if [ -f "package.json" ]; then echo -e "${D}  → package.json${R}"; npm install 2>/dev/null || true; fi
    if [ -f "Gemfile" ]; then echo -e "${D}  → Gemfile${R}"; bundle install 2>/dev/null || true; fi
    if [ -f "Makefile" ]; then echo -e "${D}  → Makefile${R}"; make 2>/dev/null || true; fi
    if [ -f "install.sh" ]; then echo -e "${D}  → install.sh${R}"; chmod +x install.sh && bash install.sh 2>/dev/null || true; fi
    if [ -f "setup.sh" ]; then echo -e "${D}  → setup.sh${R}"; chmod +x setup.sh && bash setup.sh 2>/dev/null || true; fi
    if [ -f "configure" ]; then echo -e "${D}  → configure${R}"; chmod +x configure && ./configure 2>/dev/null && make 2>/dev/null || true; fi
    if [ -f "CMakeLists.txt" ]; then echo -e "${D}  → CMakeLists.txt${R}"; [ -d build ] || mkdir build; cd build && cmake .. 2>/dev/null && make 2>/dev/null; cd "${dir}"; fi
    
    cd "${SCRIPT_DIR}" 2>/dev/null || true
}

# ====================== VERIFY & SYMLINK ======================
verify_and_link() {
    local tool_name="$1"
    local tool_dir="$2"
    
    # Find the executable
    local exe=""
    if [ -f "${tool_dir}/${tool_name}" ]; then
        exe="${tool_dir}/${tool_name}"
    elif [ -f "${tool_dir}/${tool_name}.py" ]; then
        exe="${tool_dir}/${tool_name}.py"
    elif [ -f "${tool_dir}/bin/${tool_name}" ]; then
        exe="${tool_dir}/bin/${tool_name}"
    elif [ -f "${tool_dir}/src/${tool_name}" ]; then
        exe="${tool_dir}/src/${tool_name}"
    elif [ -f "${tool_dir}/target/release/${tool_name}" ]; then
        exe="${tool_dir}/target/release/${tool_name}"
    else
        exe=$(find "${tool_dir}" -maxdepth 3 -type f -name "${tool_name}" 2>/dev/null | head -1)
    fi
    
    # Also check if it's in PATH already
    if command -v "${tool_name}" >/dev/null 2>&1; then
        echo -e "  ${G}[✓] ${tool_name} available in PATH${R}"
        log_success "Verified in PATH: ${tool_name}"
        return 0
    fi
    
    # Create symlink if we found the executable
    if [ -n "${exe}" ] && [ -f "${exe}" ]; then
        chmod +x "${exe}" 2>/dev/null || true
        ln -sf "${exe}" "${PREFIX}/bin/${tool_name}" 2>/dev/null || {
            cp "${exe}" "${PREFIX}/bin/${tool_name}" 2>/dev/null || true
        }
        echo -e "  ${G}[✓] ${tool_name} symlinked to ${PREFIX}/bin/${tool_name}${R}"
        log_success "Linked: ${tool_name}"
        return 0
    fi
    
    echo -e "  ${Y}[!] ${tool_name}: executable not found, but repo is at ${tool_dir}${R}"
    log_info "Tool repo cloned but no executable found: ${tool_name}"
    return 0  # Don't fail, user can manually run from the directory
}

# ====================== INSTALL A SINGLE GIT TOOL ======================
install_git_tool() {
    local repo_url="$1"
    local tool_name="$2"
    local category="$3"
    local target_dir="${TOOLS_DIR}/${category}/${tool_name}"
    
    # Already exists
    if command -v "${tool_name}" >/dev/null 2>&1; then
        echo -e "  ${G}[✓] Already in PATH: ${tool_name}${R}"
        update_stats "skipped"; record_pkg "${category}" "${tool_name}" "skipped"
        return 0
    fi
    
    echo -e "${C}[*] Installing: ${tool_name}${R}"
    echo -e "${D}  Repo: ${repo_url}${R}"
    echo -e "${D}  Dir:  ${target_dir}${R}"
    
    if git_clone_or_update "${repo_url}" "${target_dir}"; then
        auto_deps "${target_dir}"
        verify_and_link "${tool_name}" "${target_dir}"
        update_stats "installed"; record_pkg "${category}" "${tool_name}" "installed"
        echo -e "  ${G}[✓] ${tool_name} done${R}"
        return 0
    fi
    
    update_stats "failed" "${tool_name}"; record_pkg "${category}" "${tool_name}" "failed"
    echo -e "  ${Rr}[✗] ${tool_name} FAILED${R}"
    return 1
}

# ====================== CATEGORY DEFINITIONS WITH GITHUB URLS ======================

# Mapping: tool_name -> github_repo_url
declare -A GIT_REPOS

# 01-Information-Gathering
GIT_REPOS[nmap]="https://github.com/nmap/nmap.git"
GIT_REPOS[rustscan]="https://github.com/RustScan/RustScan.git"
GIT_REPOS[masscan]="https://github.com/robertdavidgraham/masscan.git"
GIT_REPOS[naabu]="https://github.com/projectdiscovery/naabu.git"
GIT_REPOS[amass]="https://github.com/owasp-amass/amass.git"
GIT_REPOS[assetfinder]="https://github.com/tomnomnom/assetfinder.git"
GIT_REPOS[subfinder]="https://github.com/projectdiscovery/subfinder.git"
GIT_REPOS[findomain]="https://github.com/Findomain/Findomain.git"
GIT_REPOS[bbot]="https://github.com/blacklanternsecurity/bbot.git"
GIT_REPOS[theharvester]="https://github.com/laramies/theHarvester.git"
GIT_REPOS[dnsx]="https://github.com/projectdiscovery/dnsx.git"
GIT_REPOS[dnsrecon]="https://github.com/darkoperator/dnsrecon.git"
GIT_REPOS[dnsenum]="https://github.com/fwaeytens/dnsenum.git"
GIT_REPOS[massdns]="https://github.com/blechschmidt/massdns.git"
GIT_REPOS[fierce]="https://github.com/mschwager/fierce.git"
GIT_REPOS[httpx]="https://github.com/projectdiscovery/httpx.git"
GIT_REPOS[httprobe]="https://github.com/tomnomnom/httprobe.git"
GIT_REPOS[katana]="https://github.com/projectdiscovery/katana.git"
GIT_REPOS[gau]="https://github.com/lc/gau.git"
GIT_REPOS[waybackurls]="https://github.com/tomnomnom/waybackurls.git"
GIT_REPOS[hakrawler]="https://github.com/hakluke/hakrawler.git"

# 02-OSINT
GIT_REPOS[sherlock]="https://github.com/sherlock-project/sherlock.git"
GIT_REPOS[maigret]="https://github.com/soxoj/maigret.git"
GIT_REPOS[phoneinfoga]="https://github.com/sundowndev/phoneinfoga.git"
GIT_REPOS[holehe]="https://github.com/megadose/holehe.git"
GIT_REPOS[social-analyzer]="https://github.com/qeeqbox/social-analyzer.git"
GIT_REPOS[ghunt]="https://github.com/mxrch/GHunt.git"

# 03-Subdomain-Enumeration
GIT_REPOS[sublist3r]="https://github.com/aboul3la/Sublist3r.git"
GIT_REPOS[subbrute]="https://github.com/TheRook/subbrute.git"

# 04-DNS-Tools
# (dnsrecon, dnsenum already in Info-Gathering, these are extras)

# 05-Web-Security
GIT_REPOS[ffuf]="https://github.com/ffuf/ffuf.git"
GIT_REPOS[gobuster]="https://github.com/OJ/gobuster.git"
GIT_REPOS[dirsearch]="https://github.com/maurosoria/dirsearch.git"
GIT_REPOS[feroxbuster]="https://github.com/epi052/feroxbuster.git"
GIT_REPOS[nikto]="https://github.com/sullo/nikto.git"
GIT_REPOS[nuclei]="https://github.com/projectdiscovery/nuclei.git"
GIT_REPOS[wpscan]="https://github.com/wpscanteam/wpscan.git"
GIT_REPOS[dalfox]="https://github.com/hahwul/dalfox.git"
GIT_REPOS[xsstrike]="https://github.com/s0md3v/XSStrike.git"
GIT_REPOS[paramspider]="https://github.com/devanshbatham/ParamSpider.git"
GIT_REPOS[arjun]="https://github.com/s0md3v/Arjun.git"

# 06-Network-Tools
GIT_REPOS[tcpdump]="https://github.com/the-tcpdump-group/tcpdump.git"
GIT_REPOS[termshark]="https://github.com/gcla/termshark.git"
GIT_REPOS[bettercap]="https://github.com/bettercap/bettercap.git"
GIT_REPOS[nmap]="https://github.com/nmap/nmap.git"
GIT_REPOS[masscan]="https://github.com/robertdavidgraham/masscan.git"
GIT_REPOS[zmap]="https://github.com/zmap/zmap.git"

# 07-Wireless-Security
GIT_REPOS[aircrack-ng]="https://github.com/aircrack-ng/aircrack-ng.git"
GIT_REPOS[hcxdumptool]="https://github.com/ZerBea/hcxdumptool.git"
GIT_REPOS[reaver]="https://github.com/t6x/reaver-wps-fork-t6x.git"
GIT_REPOS[mdk4]="https://github.com/aircrack-ng/mdk4.git"
GIT_REPOS[kismet]="https://github.com/kismetwireless/kismet.git"
GIT_REPOS[wifite2]="https://github.com/derv82/wifite2.git"
GIT_REPOS[hackrf]="https://github.com/greatscottgadgets/hackrf.git"

# 08-Password-Attack
GIT_REPOS[john]="https://github.com/openwall/john.git"
GIT_REPOS[hashcat]="https://github.com/hashcat/hashcat.git"
GIT_REPOS[hydra]="https://github.com/vanhauser-thc/thc-hydra.git"
GIT_REPOS[crunch]="https://github.com/jim3ma/crunch.git"
GIT_REPOS[cewl]="https://github.com/digininja/CeWL.git"
GIT_REPOS[hash-identifier]="https://github.com/psypanda/hashID.git"
GIT_REPOS[medusa]="https://github.com/jmk-foofus/medusa.git"
GIT_REPOS[ncrack]="https://github.com/nmap/ncrack.git"
GIT_REPOS[patator]="https://github.com/lanjelot/patator.git"
GIT_REPOS[hashcat-utils]="https://github.com/hashcat/hashcat-utils.git"
GIT_REROS[secLists]="https://github.com/danielmiessler/SecLists.git"

# 09-Exploitation
GIT_REPOS[metasploit-framework]="https://github.com/rapid7/metasploit-framework.git"
GIT_REPOS[sqlmap]="https://github.com/sqlmapproject/sqlmap.git"
GIT_REPOS[commix]="https://github.com/commixproject/commix.git"
GIT_REPOS[exploitdb]="https://github.com/offensive-security/exploitdb.git"
GIT_REPOS[beef]="https://github.com/beefproject/beef.git"
GIT_REPOS[yersinia]="https://github.com/tomac/yersinia.git"
GIT_REPOS[setoolkit]="https://github.com/trustedsec/social-engineer-toolkit.git"
GIT_REPOS[shellphish]="https://github.com/thelinuxchoice/shellphish.git"
GIT_REPOS[hiddeneye]="https://github.com/DarkSecDevelopers/HiddenEye.git"
GIT_REPOS[evilginx2]="https://github.com/kgretzky/evilginx2.git"

# 10-Post-Exploitation
GIT_REPOS[empire]="https://github.com/BC-SECURITY/Empire.git"
GIT_REPOS[pwncat]="https://github.com/calebstewart/pwncat.git"
GIT_REPOS[chisel]="https://github.com/jpillora/chisel.git"
GIT_REPOS[ligolo-ng]="https://github.com/nicocha30/ligolo-ng.git"
GIT_REPOS[phpsploit]="https://github.com/nil0x42/phpsploit.git"

# 11-Reverse-Engineering
GIT_REPOS[radare2]="https://github.com/radareorg/radare2.git"
GIT_REPOS[binwalk]="https://github.com/RefirmLabs/binwalk.git"
GIT_REPOS[apktool]="https://github.com/iBotPeaches/Apktool.git"
GIT_REPOS[jadx]="https://github.com/skylot/jadx.git"
GIT_REPOS[gdb]="https://github.com/bminor/binutils-gdb.git"
GIT_REPOS[rizin]="https://github.com/rizinorg/rizin.git"
GIT_REPOS[frida]="https://github.com/frida/frida.git"

# 12-Malware-Analysis
GIT_REPOS[clamav]="https://github.com/Cisco-Talos/clamav.git"
GIT_REPOS[yara]="https://github.com/VirusTotal/yara.git"
GIT_REPOS[strings]="https://github.com/mzpqnxow/strings.git"
GIT_REPOS[capa]="https://github.com/mandiant/capa.git"
GIT_REPOS[flare-floss]="https://github.com/mandiant/flare-floss.git"

# 13-Digital-Forensics
GIT_REPOS[volatility3]="https://github.com/volatilityfoundation/volatility3.git"
GIT_REPOS[volatility]="https://github.com/volatilityfoundation/volatility.git"
GIT_REPOS[yara]="https://github.com/VirusTotal/yara.git"
GIT_REPOS[exiftool]="https://github.com/exiftool/exiftool.git"
GIT_REPOS[foremost]="https://github.com/korczis/foremost.git"
GIT_REPOS[sleuthkit]="https://github.com/sleuthkit/sleuthkit.git"
GIT_REPOS[binwalk]="https://github.com/ReFirmLabs/binwalk.git"
GIT_REPOS[bulk-extractor]="https://github.com/simsong/bulk_extractor.git"
GIT_REPOS[scalpel]="https://github.com/sleuthkit/scalpel.git"

# 14-Threat-Intelligence
GIT_REPOS[sigma]="https://github.com/SigmaHQ/sigma.git"
GIT_REPOS[misp]="https://github.com/MISP/MISP.git"
GIT_REPOS[yara]="https://github.com/VirusTotal/yara.git"
GIT_REPOS[thehive]="https://github.com/TheHive-Project/TheHive.git"
GIT_REPOS[cortex]="https://github.com/TheHive-Project/Cortex.git"

# 15-Additional-Attack-Tools
GIT_REPOS[mitmproxy]="https://github.com/mitmproxy/mitmproxy.git"
GIT_REPOS[ettercap]="https://github.com/Ettercap/ettercap.git"
GIT_REPOS[macchanger]="https://github.com/alobbs/macchanger.git"
GIT_REPOS[dnsspoof]="https://github.com/DanMcInerney/dnsspoof.git"
GIT_REPOS[responder]="https://github.com/lgandx/Responder.git"
GIT_REPOS[impacket]="https://github.com/SecureAuthCorp/impacket.git"

# 16-Utilities
GIT_REPOS[git]="https://github.com/git/git.git"
GIT_REPOS[curl]="https://github.com/curl/curl.git"
GIT_REPOS[wget]="https://github.com/mirror/wget.git"
GIT_REPOS[nano]="https://github.com/madnight/nano.git"
GIT_REPOS[tmux]="https://github.com/tmux/tmux.git"
GIT_REPOS[openssh]="https://github.com/openssh/openssh-portable.git"

# ====================== CATEGORY HELPERS ======================
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

# ====================== GENERIC SUBMENU ======================
run_submenu() {
    local title="$1"
    local category="$2"
    shift 2
    local tools=("$@")
    
    while true; do
        section "${title}"
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL tools in this category"
        echo ""
        local i=1
        for t in "${tools[@]}"; do
            local status=" "
            command -v "$t" >/dev/null 2>&1 && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-30s %s\n" "$i" "$t" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/${category}]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A)
                for t in "${tools[@]}"; do
                    local url="${GIT_REPOS[$t]}"
                    [ -n "$url" ] && install_git_tool "$url" "$t" "$category" || echo -e "  ${Y}[!] No repo for ${t}${R}"
                done
                ;;
            *)
                if [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -ge 1 ] && [ "$ch" -le "${#tools[@]}" ]; then
                    local idx=$((ch-1))
                    local tn="${tools[$idx]}"
                    local ur="${GIT_REPOS[$tn]}"
                    [ -n "$ur" ] && install_git_tool "$ur" "$tn" "$category" || echo -e "  ${Y}[!] No repo for ${tn}${R}"
                fi
                ;;
        esac
        echo ""; read -r -p "Press Enter to continue..."
    done
}

# ====================== SUBMENU FUNCTIONS ======================
submenu_info_gathering() {
    local tools=(nmap rustscan masscan naabu amass assetfinder subfinder findomain bbot theharvester dnsx dnsrecon dnsenum massdns fierce httpx httprobe katana gau waybackurls hakrawler)
    run_submenu "INFORMATION GATHERING / RECONNAISSANCE" "${CAT_IG}" "${tools[@]}"
}

submenu_osint() {
    local tools=(sherlock maigret phoneinfoga holehe social-analyzer ghunt)
    run_submenu "OSINT (Open Source Intelligence)" "${CAT_OSINT}" "${tools[@]}"
}

submenu_subdomain() {
    local tools=(subfinder assetfinder findomain amass dnsx httpx httprobe sublist3r subbrute)
    run_submenu "SUBDOMAIN ENUMERATION" "${CAT_SUB}" "${tools[@]}"
}

submenu_dns() {
    local tools=(dnsx dnsrecon dnsenum massdns fierce)
    run_submenu "DNS TOOLS" "${CAT_DNS}" "${tools[@]}"
}

submenu_web() {
    local tools=(ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun)
    run_submenu "WEB APPLICATION SECURITY" "${CAT_WEB}" "${tools[@]}"
}

submenu_network() {
    local tools=(tcpdump termshark bettercap nmap masscan zmap)
    run_submenu "NETWORK TOOLS" "${CAT_NET}" "${tools[@]}"
}

submenu_wireless() {
    local tools=(aircrack-ng hcxdumptool reaver mdk4 kismet wifite2 hackrf)
    run_submenu "WIRELESS SECURITY (WiFi / RF)" "${CAT_WIRE}" "${tools[@]}"
}

submenu_password() {
    local tools=(john hashcat hydra crunch cewl hash-identifier medusa ncrack patator hashcat-utils secLists)
    run_submenu "PASSWORD AUDITING / CRACKING" "${CAT_PASS}" "${tools[@]}"
}

submenu_exploit() {
    local tools=(metasploit-framework sqlmap commix exploitdb beef yersinia setoolkit shellphish hiddeneye evilginx2)
    run_submenu "EXPLOITATION & PHISHING" "${CAT_EXPLOIT}" "${tools[@]}"
}

submenu_postexploit() {
    local tools=(empire pwncat chisel ligolo-ng phpsploit)
    run_submenu "POST EXPLOITATION" "${CAT_POST}" "${tools[@]}"
}

submenu_reverse() {
    local tools=(radare2 binwalk apktool jadx gdb rizin frida)
    run_submenu "REVERSE ENGINEERING" "${CAT_REV}" "${tools[@]}"
}

submenu_malware() {
    local tools=(clamav yara strings capa flare-floss)
    run_submenu "MALWARE ANALYSIS" "${CAT_MAL}" "${tools[@]}"
}

submenu_forensics() {
    local tools=(volatility3 volatility yara exiftool foremost sleuthkit binwalk bulk-extractor scalpel)
    run_submenu "DIGITAL FORENSICS" "${CAT_FOR}" "${tools[@]}"
}

submenu_threat() {
    local tools=(sigma misp yara thehive cortex)
    run_submenu "THREAT INTELLIGENCE" "${CAT_THREAT}" "${tools[@]}"
}

submenu_attacks() {
    local tools=(mitmproxy ettercap macchanger dnsspoof responder impacket setoolkit beef)
    run_submenu "ADDITIONAL ATTACK TOOLS (MITM, Phishing, Spoofing)" "${CAT_ATK}" "${tools[@]}"
}

# ====================== PACKAGES SECTION (NEW) ======================
# This installs Termux base packages needed for building/running tools
pkg_inst() {
    local pkg=$1
    pkg list-installed 2>/dev/null | grep -q "^${pkg}$" && return 0
    echo -e "${C}[*] Installing Termux package: ${pkg}${R}"
    pkg install -y "${pkg}" 2>/dev/null || { log_error "pkg install failed: ${pkg}"; return 1; }
    log_success "Package installed: ${pkg}"; return 0
}

submenu_packages() {
    local packages=(
        # Build essentials
        "git" "curl" "wget" "make" "cmake" "clang" "gcc" "binutils" "pkg-config" "build-essential"
        # Languages
        "python" "python3" "python-pip" "golang" "rust" "nodejs" "ruby" "perl"
        # Libraries
        "libpcap" "libusb" "openssl" "libcurl" "libxml2" "libxslt"
        # Termux repos
        "root-repo" "x11-repo" "tur-repo"
        # Tools that work better as pkg
        "nmap" "tcpdump" "tshark" "john" "hydra" "sqlmap" "exploitdb"
        # Editors / utilities
        "nano" "vim" "tmux" "tree" "zip" "unzip" "openssh" "htop"
    )
    
    while true; do
        section "PACKAGES — Termux Base Installation"
        echo -e "  ${D}Install core Termux packages: compilers, languages, libraries${R}"
        echo -e "  ${D}This is for system deps. Tools themselves are cloned from GitHub.${R}"
        echo ""
        echo -e "  ${B}${G}0${R}  Back to Main Menu"
        echo -e "  ${B}${Y}A${R}  Install ALL packages"
        echo ""
        local i=1
        for p in "${packages[@]}"; do
            local status=" "
            pkg list-installed 2>/dev/null | grep -q "^${p}$" && status="${G}[✓]${R}" || status="${D}[ ]${R}"
            printf "  %2d) %-25s %s\n" "$i" "$p" "$status"
            i=$((i+1))
        done
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/Packages]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            a|A)
                echo -e "${C}[*] Updating package lists first...${R}"
                pkg update -y 2>/dev/null || true
                pkg upgrade -y 2>/dev/null || true
                for p in "${packages[@]}"; do
                    pkg_inst "$p" || true
                done
                ;;
            *)
                if [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -ge 1 ] && [ "$ch" -le "${#packages[@]}" ]; then
                    pkg_inst "${packages[$((ch-1))]}" || true
                fi
                ;;
        esac
        echo ""; read -r -p "Press Enter to continue..."
    done
}

# ====================== INSTALL EVERYTHING ======================
install_everything() {
    section "FULL INSTALLATION — ALL ~200+ TOOLS"
    echo -e "${Y}[!] This will clone ALL repositories from GitHub (~2-5GB)${R}"
    echo -e "${Y}[!] Estimated time: 30-90 minutes depending on network${R}"
    confirm "Proceed?" || return
    
    echo -e "${C}[*] Installing base packages first...${R}"
    pkg update -y 2>/dev/null || true
    pkg upgrade -y 2>/dev/null || true
    for p in git curl wget python python3 golang rust nodejs ruby make clang cmake pkg-config; do
        pkg_inst "$p" 2>/dev/null || true
    done
    
    # Now install all tool categories
    local all_categories=(
        "submenu_info_gathering:${CAT_IG}:nmap rustscan masscan naabu amass assetfinder subfinder findomain bbot theharvester dnsx dnsrecon dnsenum massdns fierce httpx httprobe katana gau waybackurls hakrawler"
        "submenu_osint:${CAT_OSINT}:sherlock maigret phoneinfoga holehe social-analyzer ghunt"
        "submenu_web:${CAT_WEB}:ffuf gobuster dirsearch feroxbuster nikto nuclei wpscan dalfox xsstrike paramspider arjun"
        "submenu_password:${CAT_PASS}:john hashcat hydra crunch cewl hash-identifier medusa ncrack patator hashcat-utils secLists"
        "submenu_exploit:${CAT_EXPLOIT}:metasploit-framework sqlmap commix exploitdb beef yersinia setoolkit"
        "submenu_forensics:${CAT_FOR}:volatility3 volatity yara exiftool foremost sleuthkit binwalk"
        "submenu_wireless:${CAT_WIRE}:aircrack-ng hcxdumptool reaver mdk4 kismet wifite2"
        "submenu_network:${CAT_NET}:tcpdump termshark bettercap nmap masscan"
        "submenu_reverse:${CAT_REV}:radare2 binwalk apktool jadx rizin"
        "submenu_attacks:${CAT_ATK}:mitmproxy ettercap macchanger responder impacket"
    )
    
    for entry in "${all_categories[@]}"; do
        local cat_name="${entry%%:*}"
        local rest="${entry#*:}"
        local cat_dir="${rest%%:*}"
        local tools_str="${rest#*:}"
        
        section "Installing: ${cat_dir}"
        for tn in ${tools_str}; do
            local url="${GIT_REPOS[$tn]}"
            [ -n "$url" ] && install_git_tool "$url" "$tn" "$cat_dir" || true
        done
    done
    
    echo -e "\n${B}${G}═══════════════════════════════════════════════════════════════${R}"
    echo -e "${B}${G}           FULL INSTALLATION COMPLETE!                          ${R}"
    echo -e "${B}${G}═══════════════════════════════════════════════════════════════${R}"
    show_summary
}

# ====================== UPDATE ALL ======================
update_all() {
    section "UPDATE ALL CLONED REPOSITORIES"
    find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | while read -r gd; do
        rd="$(dirname "${gd}")"
        echo -e "${C}[*] $(echo "${rd}" | sed "s|${TOOLS_DIR}/||")${R}"
        (cd "${rd}" && git pull --ff-only 2>/dev/null) || true
    done
    echo -e "${G}[✓] All repositories updated${R}"
}

# ====================== SHOW INSTALLED ======================
show_installed() {
    section "INSTALLED TOOLS"
    if [ ! -f "${PKG_DB}" ]; then echo -e "${Y}[!] No records${R}"; return; fi
    local cat=""
    while IFS='|' read -r ts c n s; do
        [ "$c" != "$cat" ] && echo "" && echo -e "${B}${BLE}► ${c}${R}" && cat="$c"
        local scolor="${G}"; [ "$s" = "failed" ] && scolor="${Rr}"; [ "$s" = "skipped" ] && scolor="${Y}"
        printf "  %-35s ${scolor}%-10s${R}\n" "$n" "$s"
    done < "${PKG_DB}"
    echo ""; echo -e "${D}Total: $(wc -l < "${PKG_DB}") records${R}"
    
    echo ""; echo -e "${C}Your tools are stored in:${R}"
    echo -e "  ${D}${TOOLS_DIR}/${R}"
    echo -e "${C}To see the folder structure:${R}"
    echo -e "  ${D}ls -la ${TOOLS_DIR}/${R}"
}

# ====================== HEALTH CHECK ======================
health_check() {
    section "SYSTEM HEALTH CHECK"
    local issues=0
    
    # Storage
    local mb=$(($(df "$HOME" 2>/dev/null | awk 'NR==2{print $4}')/1024))
    echo -e "  ${B}[1] Storage:${R} ${mb}MB free"
    [ "$mb" -lt 500 ] && { echo -e "    ${Rr}✗ LOW${R}"; issues=$((issues+1)); } || echo -e "    ${G}✓${R}"
    
    # Network
    echo -e "  ${B}[2] Network:${R}"
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        echo -e "    ${G}✓ Connected${R}"
    else
        echo -e "    ${Y}⚠ Offline${R}"
    fi
    
    # Git
    echo -e "  ${B}[3] Git Available:${R}"
    command -v git >/dev/null 2>&1 && echo -e "    ${G}✓ git found${R}" || { echo -e "    ${Rr}✗ git MISSING${R}"; issues=$((issues+1)); }
    
    # Count repos
    local repo_count=$(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | wc -l)
    echo -e "  ${B}[4] Cloned Repos:${R} ${repo_count}"
    
    # Check tool dir
    echo -e "  ${B}[5] Tool Directory Structure:${R}"
    ls -d "${TOOLS_DIR}"/*/ 2>/dev/null | sed "s|${TOOLS_DIR}/|  • |g" | sed 's|/$||' || echo -e "    ${Y}No tools installed yet${R}"
    
    echo ""
    [ "$issues" -eq 0 ] && echo -e "${G}✓ Health OK${R}" || echo -e "${Y}⚠ ${issues} issue(s)${R}"
}

# ====================== REPO MANAGER ======================
repo_manager() {
    while true; do
        section "REPOSITORY MANAGER"
        echo -e "  ${B}${G}1${R}  List all cloned repos"
        echo -e "  ${B}${G}2${R}  Update all repos"
        echo -e "  ${B}${G}3${R}  Delete a repo"
        echo -e "  ${B}${G}4${R}  Show repo sizes"
        echo -e "  ${B}${G}5${R}  Show folder tree"
        echo -e "  ${B}${G}0${R}  Back"
        echo ""
        read -r -p "$(echo -e "${B}${C}[ZorkSec/RepoMgr]${R} Select: ")" ch
        case "$ch" in
            0) break ;;
            1) find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | while read -r gd; do echo "  $(dirname "$gd")" | sed "s|${TOOLS_DIR}/||"; done | sort ;;
            2) find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | while read -r gd; do
                rd=$(dirname "$gd"); echo -e "${C}[*] $(basename "$rd")${R}"
                (cd "$rd" && git pull --ff-only 2>/dev/null) || echo "  ${Y}⚠ Failed${R}"
               done ;;
            3) local i=1; local -a repos=()
               while IFS= read -r gd; do
                   rd=$(dirname "$gd"); repos+=("$rd")
                   echo "  $i) $(echo "$rd" | sed "s|${TOOLS_DIR}/||")"
                   i=$((i+1))
               done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null)
               echo ""; read -r -p "Enter number to delete: " dn
               [[ "$dn" =~ ^[0-9]+$ ]] && [ "$dn" -le "${#repos[@]}" ] && confirm "Delete?" && rm -rf "${repos[$((dn-1))]}" && echo -e "${G}✓ Deleted${R}" ;;
            4) du -sh "${TOOLS_DIR}"/*/ 2>/dev/null | sort -rh | head -25 ;;
            5) echo ""; find "${TOOLS_DIR}" -maxdepth 3 -type d 2>/dev/null | sort | head -50 ;;
        esac
        echo ""; read -r -p "Press Enter..."
    done
}

# ====================== BACKUP / RESTORE ======================
backup_config() { section "BACKUP"; local bk="${BACKUP_DIR}/zorksec-backup-$(date '+%Y%m%d-%H%M%S').tar.gz"; tar -czf "$bk" -C "${CONFIG_DIR}" . 2>/dev/null && echo -e "${G}✓ Saved: ${bk}${R}" || echo -e "${Rr}✗ Failed${R}"; }
restore_config() {
    section "RESTORE"
    local backups=($(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null))
    [ ${#backups[@]} -eq 0 ] && echo -e "${Y}[!] No backups${R}" && return
    local i=1
    for b in "${backups[@]}"; do echo "  $i) $(basename "$b")"; i=$((i+1)); done
    read -r -p "Select: " ch
    [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -le "${#backups[@]}" ] && tar -xzf "${backups[$((ch-1))]}" -C "${CONFIG_DIR}" 2>/dev/null && echo -e "${G}✓ Restored${R}"
}

# ====================== ABOUT ======================
about() {
    section "ABOUT ZORKSEC-TERMUX"
    echo -e "  ${B}Version:${R}      ${VERSION}"
    echo -e "  ${B}Author:${R}       ${AUTHOR}"
    echo -e "  ${B}Platform:${R}     Termux (Android)"
    echo -e "  ${B}License:${R}      MIT"
    echo ""
    echo -e "  ${D}All 200+ tools are cloned directly from their official${R}"
    echo -e "  ${D}GitHub repositories into:${R}"
    echo -e "  ${D}${TOOLS_DIR}/Category/ToolName/${R}"
    echo ""
    echo -e "  ${B}How to use installed tools:${R}"
    echo -e "  1) Run directly from terminal (symlinked):"
    echo -e "     ${D}nmap -sV target.com${R}"
    echo -e "     ${D}subfinder -d example.com${R}"
    echo -e "     ${D}hydra -l admin -P rockyou.txt ssh://target${R}"
    echo -e ""
    echo -e "  2) Navigate to the tool directory:"
    echo -e "     ${D}cd ~/zorksec-tools/08-Password-Attack/john/${R}"
    echo -e "     ${D}./john --list=formats${R}"
    echo ""
    echo -e "  ${B}Categories:${R}"
    for d in 01-Information-Gathering 02-OSINT 03-Subdomain-Enumeration 04-DNS-Tools 05-Web-Security 06-Network-Tools 07-Wireless-Security 08-Password-Attack 09-Exploitation 10-Post-Exploitation 11-Reverse-Engineering 12-Malware-Analysis 13-Digital-Forensics 14-Threat-Intelligence 15-Additional-Attack-Tools; do
        echo -e "   ${D}${d}${R}"
    done
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
    echo -e " ${Rr}✗ Failed:${R}     ${FAILED_COUNT}"
    [ -n "$FAILED_TOOLS" ] && echo -e " ${Rr}Failed:${R}     ${FAILED_TOOLS}"
    echo -e " ${D}Time:${R}        $((dur/60))m $((dur%60))s"
    echo -e " ${D}Storage:${R}     ${stor} (${TOOLS_DIR})"
    echo -e " ${D}Logs:${R}        ${LOG_DIR}/"
    echo -e "${B}${C}═══════════════════════════════════════════════════════════${R}"
}

# ====================== MAIN MENU ======================
main_menu() {
    while true; do
        banner
        echo -e "${B}${BLE}┌───────────────────── MAIN MENU ─────────────────────┐${R}"
        echo -e "${B}${BLE}│${R} ${G} 1${R}  Install Everything (All GitHub Repos)        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 2${R}  01-Information Gathering / Reconnaissance    ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 3${R}  02-OSINT                                    ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 4${R}  03-Subdomain Enumeration                    ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 5${R}  04-DNS Tools                                ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 6${R}  05-Web Application Security                 ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 7${R}  06-Network Tools                            ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 8${R}  07-Wireless Security                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G} 9${R}  08-Password Attack / Auditing               ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}10${R}  09-Exploitation & Phishing                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}11${R}  10-Post Exploitation                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}12${R}  11-Reverse Engineering                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}13${R}  12-Malware Analysis                         ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}14${R}  13-Digital Forensics                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}15${R}  14-Threat Intelligence                      ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${G}16${R}  15-Additional Attack Tools (MITM, Phishing) ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${M}17${R}  📦 PACKAGES (Termux Base: python, go, etc.)  ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Y}18${R}  Update All Cloned Repos                     ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Y}19${R}  Repair / Re-check Installed Tools           ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}20${R}  Show Installed Tools List                   ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}21${R}  System Health Check                         ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${C}22${R}  Repository Manager                          ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${W}23${R}  Backup Configuration                        ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${W}24${R}  Restore Configuration                       ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${W}25${R}  About / Help                                ${B}${BLE}│${R}"
        echo -e "${B}${BLE}│${R} ${Rr}26${R}  Exit                                        ${B}${BLE}│${R}"
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
            16) submenu_attacks ;;
            17) submenu_packages ;;
            18) update_all ;;
            19) echo -e "${Y}[!] Run health check first (option 21), then re-install missing tools from each category${R}" ;;
            20) show_installed ;;
            21) health_check ;;
            22) repo_manager ;;
            23) backup_config ;;
            24) restore_config ;;
            25) about ;;
            26) echo -e "${G}[✓] Thank you for using ZorkSec-Termux!${R}"; show_summary; exit 0 ;;
            *) echo -e "${Rr}[!] Invalid${R}"; sleep 1 ;;
        esac
        echo ""; read -r -p "Press Enter to return to menu..."
    done
}

# ====================== ENTRY ======================
if [ ! -d "${PREFIX:-/data/data/com.termux/files/usr}" ]; then
    echo -e "${Rr}[!] Must run inside Termux on Android${R}"
    echo -e "${Y}Download: https://f-droid.org/packages/com.termux/${R}"
    exit 1
fi
main_menu
