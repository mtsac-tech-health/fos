##############################
# OVERRIDE FUNCTIONS
##############################

export mtsackernelrevision="0" # Don't move or delete this. Using these lines with GitHub Actions.
export mtsacinitrevision="0"   # Don't move or delete this. Using these lines with GitHub Actions.

displayBanner() {
    version=$(curl -Lks ${web}service/getversion.php 2>/dev/null)
    echo "   =================================="
    echo "   ===        ====    =====      ===="
    echo "   ===  =========  ==  ===   ==   ==="
    echo "   ===  ========  ====  ==  ====  ==="
    echo "   ===  ========  ====  ==  ========="
    echo "   ===      ====  ====  ==  ========="
    echo "   ===  ========  ====  ==  ===   ==="
    echo "   ===  ========  ====  ==  ====  ==="
    echo "   ===  =========  ==  ===   ==   ==="
    echo "   ===  ==========    =====      ===="
    echo "   =================================="
    echo "   ===== Free Opensource Ghost ======"
    echo "   =================================="
    echo "   ============ Credits ============="
    echo "   = https://fogproject.org/Credits ="
    echo "   =================================="
    echo "   == Released under GPL Version 3 =="
    echo "   =================================="
    echo "   FOG Version: $version"
    echo "   Kernel Version: $(uname -r)"
    echo "   Init Version: $initversion"
    echo "   Mt.SAC Kernel Revision: $mtsacversion"
    echo "   Mt.SAC Init Revision: $mtsacversion"
}

getMACAddresses() {
    # Determine if to use system MAC from BIOS/UEFI, if using an HP machine, or the MAC that FOS picks up.
    system_mac_address=$(. /bin/getCorrectMACAddress.sh)
    if [[ $system_mac_address ]]; then
        mac=$system_mac_address
    else
        read ifaces <<< $(/sbin/ip -4 -o addr | awk -F'([ /])+' '/global/ {print $2}' | tr '[:space:]' '|' | sed -e 's/^[|]//g' -e 's/[|]$//g')
        read mac_addresses <<< $(/sbin/ip -0 addr | awk 'ORS=NR%2?FS:RS' | awk "/$ifaces/ {print \$11}" | tr '[:space:]' '|' | sed -e 's/^[|]//g' -e 's/[|]$//g')
        mac=$mac_addresses
    fi

    echo $mac
}
