resource "proxmox_virtual_environment_download_file" "image_debian_13" {
    provider            = proxmox-bpg.bpg
    content_type        = "iso"
    datastore_id        = "local"
    node_name           = var.pve_host_node
    url                 = "https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/${var.image_vm_debian_13_file}"
    file_name           = var.image_vm_debian_13_file
    checksum            = var.image_vm_debian_13_sha256
    checksum_algorithm  = "sha256"
    overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_download_file" "image_truenas" {
    provider            = proxmox-bpg.bpg
    content_type        = "iso"
    datastore_id        = "local" 
    node_name           = var.pve_host_node
    url                 = "https://download.sys.truenas.net/TrueNAS-SCALE-${var.image_lxc_truenas_version[0]}/${var.image_lxc_truenas_version[1]}/TrueNAS-SCALE-${var.image_lxc_truenas_version[1]}.iso"
    file_name           = "TrueNAS-SCALE-${var.image_lxc_truenas_version[1]}.iso"
    checksum            = var.image_lxc_truenas_sha256
    checksum_algorithm  = "sha256"
    overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_download_file" "image_homeassistant" {
    provider                  = proxmox-bpg.bpg
    content_type              = "iso"
    datastore_id              = var.storage_iso
    node_name                 = var.pve_host_node
    url                       = "https://github.com/home-assistant/operating-system/releases/download/${var.image_homeassistant_version}/haos_ova-${var.image_homeassistant_version}.qcow2.xz"
    decompression_algorithm   = "zst"
    file_name                 = "haos_ova-${var.image_homeassistant_version}.img"
    checksum                  = var.image_homeassistant_sha256
    checksum_algorithm        = "sha256"
    overwrite_unmanaged       = true
}

resource "proxmox_virtual_environment_download_file" "template_debian_13" {
    provider            = proxmox-bpg.bpg
    content_type        = "vztmpl"
    datastore_id        = "local"
    node_name           = var.pve_host_node
    url                 = "http://download.proxmox.com/images/system/${var.image_lxc_debian_13_file}"
    file_name           = var.image_lxc_debian_13_file
    checksum            = var.image_lxc_debian_13_md5
    checksum_algorithm  = "md5"
    overwrite_unmanaged = true
}