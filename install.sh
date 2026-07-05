#!/data/data/com.termux/files/usr/bin/bash
#==============================================================================#
#  ZorkSec-Termux v2.0                                                         #
#  Professional Cybersecurity Toolkit for Android Termux                       #
#  Author : Mohammad Muneeruddin (Muneer461)                                   #
#  GitHub : https://github.com/Muneer461/ZorkSec-Termux                        #
#==============================================================================#

set +o errexit
set +o nounset

VERSION="2.0"
AUTHOR="Mohammad Muneeruddin"
HOME_DIR="${HOME:-/data/data/com.termux/files/home}"
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
TOOLS_DIR="${HOME_DIR}/zorksec-tools"
CONFIG_DIR="${HOME_DIR}/.zorksec"
LOG_DIR="${CONFIG_DIR}/logs"
PKG_DB="${CONFIG_DIR}/packages.db"
BACKUP_DIR="${CONFIG_DIR}/backups"
START_TIME=$(date +%s)
FAILED_COUNT=0; INSTALLED_COUNT=0; SKIPPED_COUNT=0; TOTAL_PACKAGES=0; FAILED_TOOLS=""

# Colors
R='\033[0m'; B='\033[1m'; D='\033[2m'
Rr='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'
C='\033[0;36m'; W='\033[0;37m'; BLE='\033[0;34m'

mkdir -p "${CONFIG_DIR}" "${TOOLS_DIR}" "${LOG_DIR}" "${BACKUP_DIR}" 2>/dev/null || true
touch "${PKG_DB}" "${LOG_DIR}/install.log" "${LOG_DIR}/errors.log" 2>/dev/null || true

log_info()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "${LOG_DIR}/install.log" 2>/dev/null || true; }
log_error()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "${LOG_DIR}/errors.log" 2>/dev/null || true; }

info()  { echo -e "  ${C}*${R} $*"; }
ok()    { echo -e "  ${G}*${R} $*"; }
warn()  { echo -e "  ${Y}*${R} $*"; }
fail()  { echo -e "  ${Rr}*${R} $*"; }
title() { echo ""; echo "  ===== $1 ====="; }

confirm() {
    echo ""; read -r -p "  [?] $1 [y/N]: " ans
    case "${ans}" in [yY]|[yY][eE][sS]) return 0;; *) return 1;; esac
}

press() {
    echo ""; read -r -p "  Press Enter to continue..." dummy
}

clear_stdin() {
    dd bs=1 count=1 of=/dev/null 2>/dev/null || true
}

record_db() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$1|$2|$3" >> "${PKG_DB}"
}

is_done() {
    grep -q "|$1|$2|success" "${PKG_DB}" 2>/dev/null && return 0 || return 1
}

# ===================================================================
# GIT REPOS DATABASE
# ===================================================================
declare -A R
R[nmap]="https://github.com/nmap/nmap.git"
R[rustscan]="https://github.com/RustScan/RustScan.git"
R[masscan]="https://github.com/robertdavidgraham/masscan.git"
R[naabu]="https://github.com/projectdiscovery/naabu.git"
R[amass]="https://github.com/owasp-amass/amass.git"
R[assetfinder]="https://github.com/tomnomnom/assetfinder.git"
R[subfinder]="https://github.com/projectdiscovery/subfinder.git"
R[findomain]="https://github.com/Findomain/Findomain.git"
R[theharvester]="https://github.com/laramies/theHarvester.git"
R[httpx]="https://github.com/projectdiscovery/httpx.git"
R[httprobe]="https://github.com/tomnomnom/httprobe.git"
R[gau]="https://github.com/lc/gau.git"
R[waybackurls]="https://github.com/tomnomnom/waybackurls.git"
R[hakrawler]="https://github.com/hakluke/hakrawler.git"
R[dnsx]="https://github.com/projectdiscovery/dnsx.git"
R[dnsrecon]="https://github.com/darkoperator/dnsrecon.git"
R[dnsenum]="https://github.com/fwaeytens/dnsenum.git"
R[massdns]="https://github.com/blechschmidt/massdns.git"
R[fierce]="https://github.com/mschwager/fierce.git"
R[sublist3r]="https://github.com/aboul3la/Sublist3r.git"
R[subbrute]="https://github.com/TheRook/subbrute.git"
R[gobuster]="https://github.com/OJ/gobuster.git"
R[ffuf]="https://github.com/ffuf/ffuf.git"
R[dirsearch]="https://github.com/maurosoria/dirsearch.git"
R[feroxbuster]="https://github.com/epi052/feroxbuster.git"
R[nikto]="https://github.com/sullo/nikto.git"
R[nuclei]="https://github.com/projectdiscovery/nuclei.git"
R[wpscan]="https://github.com/wpscanteam/wpscan.git"
R[dalfox]="https://github.com/hahwul/dalfox.git"
R[xsstrike]="https://github.com/s0md3v/XSStrike.git"
R[paramspider]="https://github.com/devanshbatham/ParamSpider.git"
R[arjun]="https://github.com/s0md3v/Arjun.git"
R[sherlock]="https://github.com/sherlock-project/sherlock.git"
R[maigret]="https://github.com/soxoj/maigret.git"
R[phoneinfoga]="https://github.com/sundowndev/phoneinfoga.git"
R[holehe]="https://github.com/megadose/holehe.git"
R[social-analyzer]="https://github.com/qeeqbox/social-analyzer.git"
R[ghunt]="https://github.com/mxrch/GHunt.git"
R[tcpdump]="https://github.com/the-tcpdump-group/tcpdump.git"
R[bettercap]="https://github.com/bettercap/bettercap.git"
R[zmap]="https://github.com/zmap/zmap.git"
R[responder]="https://github.com/lgandx/Responder.git"
R[impacket]="https://github.com/fortra/impacket.git"
R[aircrack-ng]="https://github.com/aircrack-ng/aircrack-ng.git"
R[hcxdumptool]="https://github.com/ZerBea/hcxdumptool.git"
R[reaver]="https://github.com/t6x/reaver-wps-fork-t6x.git"
R[mdk4]="https://github.com/aircrack-ng/mdk4.git"
R[kismet]="https://github.com/kismetwireless/kismet.git"
R[wifite2]="https://github.com/derv82/wifite2.git"
R[john]="https://github.com/openwall/john.git"
R[hashcat]="https://github.com/hashcat/hashcat.git"
R[hydra]="https://github.com/vanhauser-thc/thc-hydra.git"
R[crunch]="https://github.com/crunchsec/crunch.git"
R[cewl]="https://github.com/digininja/CeWL.git"
R[hash-identifier]="https://github.com/psypanda/hashID.git"
R[medusa]="https://github.com/jmk-foofus/medusa.git"
R[ncrack]="https://github.com/nmap/ncrack.git"
R[patator]="https://github.com/lanjelot/patator.git"
R[hashcat-utils]="https://github.com/hashcat/hashcat-utils.git"
R[seclists]="https://github.com/danielmiessler/SecLists.git"
R[metasploit-framework]="https://github.com/rapid7/metasploit-framework.git"
R[sqlmap]="https://github.com/sqlmapproject/sqlmap.git"
R[commix]="https://github.com/commixproject/commix.git"
R[exploitdb]="https://github.com/offensive-security/exploitdb.git"
R[beef]="https://github.com/beefproject/beef.git"
R[yersinia]="https://github.com/tomac/yersinia.git"
R[setoolkit]="https://github.com/trustedsec/social-engineer-toolkit.git"
R[shellphish]="https://github.com/thelinuxchoice/shellphish.git"
R[evilginx2]="https://github.com/kgretzky/evilginx2.git"
R[hiddeneye]="https://github.com/DarkSecDevelopers/HiddenEye.git"
R[empire]="https://github.com/BC-SECURITY/Empire.git"
R[pwncat]="https://github.com/cytopia/pwncat.git"
R[chisel]="https://github.com/jpillora/chisel.git"
R[ligolo-ng]="https://github.com/nicocha30/ligolo-ng.git"
R[phpsploit]="https://github.com/nil0x42/phpsploit.git"
R[radare2]="https://github.com/radareorg/radare2.git"
R[binwalk]="https://github.com/ReFirmLabs/binwalk.git"
R[apktool]="https://github.com/iBotPeaches/Apktool.git"
R[jadx]="https://github.com/skylot/jadx.git"
R[gdb]="https://github.com/bminor/binutils-gdb.git"
R[rizin]="https://github.com/rizinorg/rizin.git"
R[frida]="https://github.com/frida/frida.git"
R[clamav]="https://github.com/Cisco-Talos/clamav.git"
R[yara]="https://github.com/VirusTotal/yara.git"
R[capa]="https://github.com/mandiant/capa.git"
R[flare-floss]="https://github.com/mandiant/flare-floss.git"
R[volatility3]="https://github.com/volatilityfoundation/volatility3.git"
R[volatility]="https://github.com/volatilityfoundation/volatility.git"
R[exiftool]="https://github.com/exiftool/exiftool.git"
R[foremost]="https://github.com/korczis/foremost.git"
R[sleuthkit]="https://github.com/sleuthkit/sleuthkit.git"
R[bulk-extractor]="https://github.com/simsong/bulk_extractor.git"
R[scalpel]="https://github.com/sleuthkit/scalpel.git"
R[sigma]="https://github.com/SigmaHQ/sigma.git"
R[misp]="https://github.com/MISP/MISP.git"
R[thehive]="https://github.com/TheHive-Project/TheHive.git"
R[cortex]="https://github.com/TheHive-Project/Cortex.git"
R[mitmproxy]="https://github.com/mitmproxy/mitmproxy.git"
R[ettercap]="https://github.com/Ettercap/ettercap.git"
R[macchanger]="https://github.com/alobbs/macchanger.git"
R[dnsspoof]="https://github.com/DanMcInerney/dnsspoof.git"
R[mitm6]="https://github.com/dirkjanm/mitm6.git"

# ===================================================================
# SINGLE TOOL INSTALL
# ===================================================================
install_tool() {
    local repo="$1"
    local name="$2"
    local cat_path="$3"

    if is_done "${name}" "${cat_path}"; then
        info "${name} already installed"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        return
    fi

    TOTAL_PACKAGES=$((TOTAL_PACKAGES + 1))
    local dir="${TOOLS_DIR}/${cat_path}/${name}"

    if [ -d "${dir}/.git" ]; then
        (cd "${dir}" && git pull >> "${LOG_DIR}/install.log" 2>&1) || true
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        record_db "${name}" "${cat_path}" "success"
        ok "${name} updated"
        return
    fi

    mkdir -p "${TOOLS_DIR}/${cat_path}" 2>/dev/null || true
    info "Cloning ${name}..."
    if git clone --depth 1 "${repo}" "${dir}" >> "${LOG_DIR}/install.log" 2>&1; then
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        record_db "${name}" "${cat_path}" "success"
        ok "${name} installed"
        chmod +x "${dir}/${name}" 2>/dev/null || true
        chmod +x "${dir}/"*.py 2>/dev/null || true
        for f in "${dir}/${name}" "${dir}/${name}.py" "${dir}/bin/${name}" "${dir}/main.py" "${dir}/run.py"; do
            [ -f "${f}" ] && { ln -sf "${f}" "${PREFIX_DIR}/bin/${name}" 2>/dev/null || true; break; }
        done
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TOOLS="${FAILED_TOOLS} ${name}"
        record_db "${name}" "${cat_path}" "failed"
        fail "${name} failed"
    fi
}

# ===================================================================
# CATEGORY INSTALL — SHOW ONCE, NO INFINITE LOOP
# ===================================================================
install_group() {
    local cat_num="$1"
    local cat_name="$2"
    shift 2
    local tools=("$@")

    title "${cat_num}. ${cat_name}"

    echo ""
    echo "  0) Back to Main Menu"
    echo "  A) Install ALL tools in this category"
    echo ""

    local i=0
    while [ "${i}" -lt "${#tools[@]}" ]; do
        local mark=""
        is_done "${tools[${i}]}" "${cat_num}-${cat_name}" && mark="[OK]" || mark="[--]"
        printf "  %2d) %-30s %s\n" $((i + 1)) "${tools[${i}]}" "${mark}"
        i=$((i + 1))
    done

    echo ""
    read -r -p "  Select [A=all, #=tool, 0=back]: " choice

    case "${choice}" in
        0) return ;;
        [aA])
            local t
            for t in "${tools[@]}"; do
                local url="${R[${t}]:-}"
                [ -n "${url}" ] && install_tool "${url}" "${t}" "${cat_num}-${cat_name}"
            done
            ;;
        *)
            if [[ "${choice}" =~ ^[0-9]+$ ]] && [ "${choice}" -ge 1 ] && [ "${choice}" -le "${#tools[@]}" ]; then
                local idx=$((choice - 1))
                local tn="${tools[${idx}]}"
                local tu="${R[${tn}]:-}"
                [ -n "${tu}" ] && install_tool "${tu}" "${tn}" "${cat_num}-${cat_name}"
            fi
            ;;
    esac
}

# ===================================================================
# PACKAGES
# ===================================================================
install_packages() {
    title "1. TERMUX BASE PACKAGES"

    if ! confirm "Install ALL base packages?"; then
        return
    fi

    info "Updating package lists..."
    pkg update -y >> "${LOG_DIR}/install.log" 2>&1 || true

    info "Installing languages and tools..."
    pkg install -y python python3 python-pip golang rust cargo ruby perl nodejs php >> "${LOG_DIR}/install.log" 2>&1 || true
    pkg install -y clang gcc g++ make cmake pkg-config >> "${LOG_DIR}/install.log" 2>&1 || true
    pkg install -y git curl wget openssh tmux vim nano htop tree jq zip unzip >> "${LOG_DIR}/install.log" 2>&1 || true
    pkg install -y net-tools dnsutils whois traceroute openjdk-17 >> "${LOG_DIR}/install.log" 2>&1 || true
    pkg install -y autoconf automake libtool bison flex root-repo x11-repo tsu >> "${LOG_DIR}/install.log" 2>&1 || true

    info "Installing Python packages..."
    for p in requests beautifulsoup4 lxml selenium scapy cryptography paramiko colorama rich dnspython pandas numpy psutil; do
        pip install "${p}" >> "${LOG_DIR}/install.log" 2>&1 || true
    done

    ok "PACKAGES INSTALLATION COMPLETE!"
}

# ===================================================================
# INSTALL ALL
# ===================================================================
install_all() {
    title "2. INSTALL ALL TOOLS"

    if ! confirm "Download 100+ tools from GitHub? (30-60 min)"; then
        return
    fi

    TOTAL_PACKAGES=0; INSTALLED_COUNT=0; SKIPPED_COUNT=0; FAILED_COUNT=0; FAILED_TOOLS=""

    local cats=(
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

    for entry in "${cats[@]}"; do
        local num="${entry%%|*}"
        local rest="${entry#*|}"
        local label="${rest%%|*}"
        local toolstr="${rest#*|}"
        local tools=(${toolstr})

        info "Category ${num} - ${label}"
        for tn in "${tools[@]}"; do
            local tu="${R[${tn}]:-}"
            [ -n "${tu}" ] && install_tool "${tu}" "${tn}" "${num}-${label}"
        done
    done

    ok "ALL TOOLS INSTALLED!"
    summary
}

# ===================================================================
# UPDATE ALL
# ===================================================================
update_repos() {
    title "UPDATE ALL"
    local count=0
    local total=$(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | wc -l)
    [ "${total}" -eq 0 ] && { warn "No repos found"; return; }

    while IFS= read -r gd; do
        count=$((count + 1))
        local rd="$(dirname "${gd}")"
        printf "\r  [%3d/%3d] %-30s" "${count}" "${total}" "$(basename "${rd}")"
        (cd "${rd}" && git pull >> "${LOG_DIR}/install.log" 2>&1) || true
    done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null)

    echo ""; ok "Updated ${count} repos"
}

# ===================================================================
# SHOW INSTALLED
# ===================================================================
show_installed() {
    title "INSTALLED TOOLS"
    [ ! -s "${PKG_DB}" ] && { warn "No tools installed yet"; return; }

    local cat=""; local o=0; local f=0
    while IFS='|' read -r _ c n s; do
        [ "${c}" != "${cat}" ] && echo "" && echo "  >> ${c}" && cat="${c}"
        [ "${s}" = "success" ] && echo "     * ${n}" && o=$((o + 1))
        [ "${s}" = "failed" ] && echo "     X ${n}" && f=$((f + 1))
    done < "${PKG_DB}"
    echo ""; ok "OK: ${o} | Failed: ${f}"
}

# ===================================================================
# HEALTH CHECK
# ===================================================================
health() {
    title "SYSTEM HEALTH CHECK"

    local av=$(df "${HOME_DIR}" 2>/dev/null | awk 'NR==2{print $4}')
    [ -z "${av}" ] && av=0
    local mb=$((av / 1024))
    echo "  [1] Storage: ${mb}MB free"
    [ "${mb}" -lt 500 ] && warn "LOW STORAGE"

    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && ok "[2] Network" || warn "[2] Offline"
    command -v git >/dev/null 2>&1 && ok "[3] Git: $(git --version 2>/dev/null | head -1)" || fail "[3] Git missing"
    echo "  [4] Languages:"
    for cmd in "python3" "go" "rustc" "ruby" "perl" "node"; do
        command -v "${cmd}" >/dev/null 2>&1 && ok "     ${cmd}" || warn "     ${cmd}"
    done

    local rc=$(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | wc -l)
    echo "  [5] Cloned repos: ${rc}"
}

# ===================================================================
# REPO MANAGER
# ===================================================================
repo_mgr() {
    while true; do
        title "REPOSITORY MANAGER"
        echo "  1) List repos"
        echo "  2) Update all"
        echo "  3) Delete a repo"
        echo "  4) Show sizes"
        echo "  0) Back"
        echo ""
        read -r -p "  Select: " mc

        case "${mc}" in
            0) break ;;
            1) while IFS= read -r gd; do echo "  * $(dirname "${gd}" | sed "s|${TOOLS_DIR}/||")"; done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | sort) ;;
            2) update_repos ;;
            3)
                local paths=(); local i=1
                while IFS= read -r gd; do paths+=("$(dirname "${gd}")"); echo "  ${i}) $(basename "$(dirname "${gd}")")"; i=$((i + 1)); done < <(find "${TOOLS_DIR}" -name ".git" -type d 2>/dev/null | sort)
                [ "${#paths[@]}" -eq 0 ] && { warn "No repos"; continue; }
                echo ""; read -r -p "  Number to delete: " dn
                if [[ "${dn}" =~ ^[0-9]+$ ]] && [ "${dn}" -ge 1 ] && [ "${dn}" -le "${#paths[@]}" ]; then
                    local dp="${paths[$((dn - 1))]}"
                    confirm "Delete $(basename "${dp}")?" && rm -rf "${dp}" && ok "Deleted"
                fi
                ;;
            4) echo ""; du -sh "${TOOLS_DIR}"/*/ 2>/dev/null | sort -rh | head -20 ;;
        esac
        press
    done
}

# ===================================================================
# BACKUP / RESTORE
# ===================================================================
backup() {
    title "BACKUP"
    local bf="${BACKUP_DIR}/zorksec-$(date '+%Y%m%d-%H%M%S').tar.gz"
    tar -czf "${bf}" -C "${CONFIG_DIR}" . 2>/dev/null && ok "Saved: $(basename "${bf}")" || fail "Backup failed"
}

restore() {
    title "RESTORE"
    local bk=()
    while IFS= read -r f; do bk+=("${f}"); done < <(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null)
    [ "${#bk[@]}" -eq 0 ] && { warn "No backups"; return; }
    local i=1
    for f in "${bk[@]}"; do echo "  ${i}) $(basename "${f}")"; i=$((i + 1)); done
    echo ""; read -r -p "  Select: " rn
    [[ "${rn}" =~ ^[0-9]+$ ]] && [ "${rn}" -ge 1 ] && [ "${rn}" -le "${#bk[@]}" ] && tar -xzf "${bk[$((rn - 1))]}" -C "${CONFIG_DIR}" && ok "Restored" || fail "Failed"
}

# ===================================================================
# ABOUT
# ===================================================================
about() {
    title "ABOUT ZORKSEC-TERMUX"
    echo "  Version: ${VERSION}"
    echo "  Author:  ${AUTHOR}"
    echo "  Platform: Termux (Android) - F-Droid"
    echo "  License: MIT"
    echo ""
    echo "  200+ security tools cloned from GitHub."
    echo "  Structure: ~/zorksec-tools/Category/Tool/"
    echo ""
    echo "  Workflow:"
    echo "  1) Install Packages (Option 1)"
    echo "  2) Install Tools (Options 2-17)"
    echo "  3) Health Check (Option 20)"
    echo "  4) Start!"
    echo ""
    echo "  GitHub: https://github.com/Muneer461/ZorkSec-Termux"
}

# ===================================================================
# SUMMARY
# ===================================================================
summary() {
    local end=$(date +%s)
    local dur=$((end - START_TIME))
    local stor=$(du -sh "${TOOLS_DIR}" 2>/dev/null | awk '{print $1}')
    [ -z "${stor}" ] && stor="0B"

    echo ""
    echo "  ========================================"
    echo "  SUMMARY"
    echo "  Total:     ${TOTAL_PACKAGES}"
    echo "  Installed: ${INSTALLED_COUNT}"
    echo "  Failed:    ${FAILED_COUNT}"
    echo "  Time:      $((dur / 60))m $((dur % 60))s"
    echo "  Storage:   ${stor}"
    [ -n "${FAILED_TOOLS}" ] && echo "  Failed:   ${FAILED_TOOLS}"
    echo "  ========================================"
}

# ===================================================================
# CLEANUP
# ===================================================================
cleanup() { echo ""; summary; exit 0; }
trap cleanup SIGINT SIGTERM

# ===================================================================
# MAIN
# ===================================================================
main() {
    [ ! -d "${PREFIX_DIR}" ] && { fail "Termux only"; exit 1; }

    while true; do
        clear_stdin
        clear 2>/dev/null || true

        echo ""
        echo "  ========================================"
        echo "       ZORK SEC - TERMUX v${VERSION}"
        echo "       ${AUTHOR}"
        echo "  ========================================"
        echo ""
        echo "   1)  Install Termux Base Packages"
        echo "   2)  Install ALL Security Tools"
        echo "  ----------------------------------------"
        echo "   3)  01 - Information Gathering"
        echo "   4)  02 - OSINT"
        echo "   5)  03 - Subdomain Enumeration"
        echo "   6)  04 - DNS Tools"
        echo "   7)  05 - Web Security"
        echo "   8)  06 - Network Tools"
        echo "   9)  07 - Wireless Security"
        echo "  10)  08 - Password Attack"
        echo "  11)  09 - Exploitation & Phishing"
        echo "  12)  10 - Post Exploitation"
        echo "  13)  11 - Reverse Engineering"
        echo "  14)  12 - Malware Analysis"
        echo "  15)  13 - Digital Forensics"
        echo "  16)  14 - Threat Intelligence"
        echo "  17)  15 - Attack Tools (MITM/Phish)"
        echo "  ----------------------------------------"
        echo "  18)  Update All Repos"
        echo "  19)  Show Installed Tools"
        echo "  20)  System Health Check"
        echo "  21)  Repository Manager"
        echo "  22)  Backup Configuration"
        echo "  23)  Restore Configuration"
        echo "  24)  About / Help"
        echo "  25)  Exit"
        echo ""
        read -r -p "  Enter choice [1-25]: " ch

        case "${ch}" in
            1)  install_packages ;;
            2)  install_all ;;
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
            18) update_repos ;;
            19) show_installed ;;
            20) health ;;
            21) repo_mgr ;;
            22) backup ;;
            23) restore ;;
            24) about ;;
            25) echo ""; ok "Thank you!"; summary; exit 0 ;;
            *) fail "Invalid (1-25)"; sleep 1 ;;
        esac

        press
    done
}

main