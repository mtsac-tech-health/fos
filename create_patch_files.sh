#!/bin/bash

LINUX_KERNEL_VER=$(cat build.sh | sed -n -e 's/^.*KERNEL_VERSION=//p' | cut -d\' -f 2)


function download_hp_utility() {
    # Create all the necessary directories
    mkdir hp_extract
    mkdir hp_kernel
    mkdir hp_init

    # Download the hp driver and extract it
    wget https://ftp.hp.com/pub/softpaq/sp150501-151000/sp150953.tgz
    tar -xvzf sp150953.tgz -C hp_extract

    # Extract the kernel module
    cd hp_extract/non-rpms
    module_tar=$(ls hpuefi*)
    tar -xvzf $module_tar -C ../../hp_kernel --strip-components=2

    # Extract the scripts for the inits
    flash_tar=$(ls *flash*)
    tar -xvzf $flash_tar -C ../../hp_init --strip-components=2

    # Return to the root directory
    cd ../../
}

function configs_patch() {
    # Add the hpuefi config to the kernel .config
    echo "CONFIG_HPUEFI=y" >> configs/kernelx64.config

    # Git add changes for diff
    git add ./configs

    # Create the patch file
    git diff --staged > mtsac_configs.patch

    # Undo git add for other patches
    git reset configs/kernelx64.config
}

function kernel_patch() {
    # Download the kernel source code
    git clone --depth 1 --branch v$LINUX_KERNEL_VER https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git

    cd linux

    # Create hpuefi driver directory in the kernel source
    mkdir drivers/hpuefi

    # Copy the hpuefi driver code to the kernel source
    cp ../hp_kernel/hpuefi.c drivers/hpuefi
    cp ../hp_kernel/hpuefi.h drivers/hpuefi
    cp ../hp_kernel/mkdevhpuefi drivers/hpuefi

    # Create the Makefile for the hpuefi driver
    touch drivers/hpuefi/Makefile
    echo "obj-\$(CONFIG_HPUEFI) += hpuefi.o" > drivers/hpuefi/Makefile

    # Create the Kconfig file for the hpuefi driver
    touch drivers/hpuefi/Kconfig
    echo "config HPUEFI" > drivers/hpuefi/Kconfig
    echo "tristate \"HP UEFI Support\"" >> drivers/hpuefi/Kconfig

    # Add the hpuefi driver to the kernel Makefile
    echo "obj-\$(CONFIG_HPUEFI) += hpuefi/" >> drivers/Makefile

    # Add the hpuefi driver to the kernel Kconfig before the endmenu
    sed -i '/endmenu/i source "drivers/hpuefi/Kconfig"' drivers/Kconfig

    # Git add changes for diff
    git add .

    # Create the patch file
    git diff --staged > ../mtsac_linux.patch

    # Return to the root directory
    cd ..
}

function __override_files() {
    # Add new custom files to the Buildroot filesystems
    cp overrides/getCorrectMACAddress.sh ./Buildroot/board/FOG/FOS/rootfs_overlay/bin

    # Add overriden functions to scripts
    cat overrides/override_funcs.sh >> ./Buildroot/board/FOG/FOS/rootfs_overlay/usr/share/fog/lib/funcs.sh

    # Replace files in the Buildroot filesystems
    rm ./Buildroot/board/FOG/FOS/rootfs_overlay/bin/fog.man.reg
    cp overrides/replace_fog.man.reg ./Buildroot/board/FOG/FOS/rootfs_overlay/bin/fog.man.reg
}

function init_patch() {
    local hp_scripts_dir="./Buildroot/board/FOG/FOS/rootfs_overlay/opt/hp/hp-flash"
    local hp_compiled_scripts_dir="./Buildroot/board/FOG/FOS/rootfs_overlay/opt/hp/hp-flash/bin"
    local kernel_driver_dir="./Buildroot/board/FOG/FOS/rootfs_overlay/lib/modules/$LINUX_KERNEL_VER/kernel/drivers/hpuefi"

    # Create directories for the hp-flash and hp-repsetup scripts and compiled files
    mkdir -p $hp_compiled_scripts_dir

    # Create the kernel driver directory
    mkdir -p $kernel_driver_dir

    # Modify hp-flash & hp-repsetup to comment out the modprobe & rmmod line since the kernel module is built-in
    # hp-flash
    sed -i 's/\/sbin\/modprobe ${MODPROBEARGS} hpuefi/#\/sbin\/modprobe ${MODPROBEARGS} hpuefi/g' hp_init/hp-flash
    sed -i 's/\/sbin\/rmmod hpuefi/#\/sbin\/rmmod hpuefi/g' hp_init/hp-flash
    # hp-repsetup
    sed -i 's/\/sbin\/modprobe ${MODPROBEARGS} hpuefi/#\/sbin\/modprobe ${MODPROBEARGS} hpuefi/g' hp_init/hp-repsetup
    sed -i 's/\/sbin\/rmmod hpuefi/#\/sbin\/rmmod hpuefi/g' hp_init/hp-repsetup

    # Move the hp-flash and hp-repsetup scripts to the Buildroom filesystems
    mv hp_init/hp-flash hp_init/hp-repsetup $hp_scripts_dir

    # Move the compiled hp-flash and hp-repsetup and rename them to the Buildroom filesystems
    mv hp_init/builds/hp-flash.u2204 $hp_compiled_scripts_dir/hp-flash
    mv hp_init/builds/hp-repsetup.u2204 $hp_compiled_scripts_dir/hp-repsetup

    # Move and chmod the 'mkdevhpuefi' file in the kernel source to the Buildroom filesystems
    mv hp_kernel/mkdevhpuefi $kernel_driver_dir
    chmod 755 $kernel_driver_dir/mkdevhpuefi

    __override_files

    # Git add changes for diff
    git add ./Buildroot

    # Create the patch file
    git diff --staged --text > ./mtsac_init.patch
}

function cleanup() {
    # Remove the unnecessary directories and files
    rm -rf linux
    rm -rf hp_init
    rm -rf hp_kernel
    rm -rf hp_extract
    rm sp150953.tgz
}

function setup_artifacts() {
    # Create the artifacts directory
    mkdir mtsac_patches

    # Move the patch files to the artifacts directory
    mv mtsac_linux.patch mtsac_patches
    mv mtsac_init.patch mtsac_patches
    mv mtsac_configs.patch mtsac_patches
}


download_hp_utility
configs_patch
kernel_patch
init_patch
cleanup
setup_artifacts
