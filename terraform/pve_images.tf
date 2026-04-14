resource "proxmox_virtual_environment_download_file" "template_debian_12" {
    provider            = proxmox-bpg.bpg
    content_type        = "vztmpl"
    datastore_id        = "local"
    node_name           = var.pve_host_node
    url                 = "http://download.proxmox.com/images/system/${var.image_debian_12_file}"
    file_name           = var.image_debian_12_file
    checksum            = var.image_debian_12_md5
    checksum_algorithm  = "md5"
    overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_download_file" "template_debian_13" {
    provider            = proxmox-bpg.bpg
    content_type        = "vztmpl"
    datastore_id        = "local"
    node_name           = var.pve_host_node
    url                 = "http://download.proxmox.com/images/system/${var.image_debian_13_file}"
    file_name           = var.image_debian_13_file
    checksum            = var.image_debian_13_md5
    checksum_algorithm  = "md5"
    overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_download_file" "iso_truenas" {
    provider            = proxmox-bpg.bpg
    content_type        = "iso"
    datastore_id        = "local" 
    node_name           = var.pve_host_node
    url                 = "https://download.sys.truenas.net/TrueNAS-SCALE-${var.image_truenas_version[0]}/${var.image_truenas_version[1]}/TrueNAS-SCALE-${var.image_truenas_version[1]}.iso"
    file_name           = "TrueNAS-SCALE-${var.image_truenas_version[1]}.iso"
    checksum            = var.image_truenas_sha256
    checksum_algorithm  = "sha256"
    upload_timeout      = 2400
    overwrite_unmanaged = true
}