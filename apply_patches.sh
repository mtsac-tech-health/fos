#!/bin/bash

function apply_configs_patch() {
    patch -p1 < mtsac_patches/mtsac_configs.patch
}

function apply_kernel_patch() {
    # This one is simple, just copy the mtsac_kernel.patch to the patch/kernel directory as linux.patch
    # This may need to change in the future if upstream adds a linux patch
    cp mtsac_patches/mtsac_linux.patch patch/kernel/linux.patch
}

function apply_filesystem_patch() {
    patch -p1 < mtsac_patches/mtsac_init.patch
}

apply_configs_patch
apply_kernel_patch
apply_filesystem_patch
