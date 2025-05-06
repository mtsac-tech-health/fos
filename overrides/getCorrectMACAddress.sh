#!/bin/bash

if [[ ! -f /opt/hp/hp-flash/hp-repsetup ]]; then
    echo ""
    exit 1
fi

current_mac=""
system_mac=""

_default_ip_adapter_name=$(ip route | grep default | cut -d ' ' -f5)
_machine_has_ethernet=$(lspci | grep -i "ethernet")

getCurrentMAC() {
    _current_mac=$(cat /sys/class/net/$_default_ip_adapter_name/address)
    echo $_current_mac
}

getSystemMAC() {
    _system_mac_from_bios_with_dash=$(/opt/hp/hp-flash/hp-repsetup -g | grep -A1 "System MAC Address" | tail -n 1 | tr -d [:space:])
    _system_mac_from_bios="${_system_mac_from_bios_with_dash//-/:}"
    echo $_system_mac_from_bios
}


current_mac=$(getCurrentMAC)
system_mac=$(getSystemMAC)

if [[ $current_mac == $system_mac ]]; then
    echo ""
    exit 1
fi

if [[ $_machine_has_ethernet ]]; then
    _network_adapter_pci_address_with_slashes=$(/usr/sbin/lshw -short -class network | grep $_default_ip_adapter_name | cut -d ' ' -f1)

    # Check if the length of the variable is greater than 4 characters.
    # Reason: The output of the above command could be `/#` if using a usb-to-ethernet adapter 
    #         instead of `/0/100/#.#` if connected directly to an ethernet.
    if [[ $(echo "$_network_adapter_pci_address_with_slashes" | wc -c) -gt 4 ]]; then
        # Removes `/0/1` from variable. This is to match the lspci address of the network adapter
        _network_adapter_pci_address_removing_beginning="${_network_adapter_pci_address_with_slashes:4:20}"

        # Done to look the same as the lspci network adapter
        _network_adapter_pci_address="${_network_adapter_pci_address_removing_beginning////:}"

        # Check if network adapter address from lshw is the same as the start of the lspci network address
        if [[ $(echo "$_machine_has_ethernet" | grep "$_network_adapter_pci_address") ]]; then
            echo ""
            exit 1
        fi
    fi
fi

echo $system_mac