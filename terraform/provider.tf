terraform {
    required_providers {
        proxmox = {
            source  = "Telmate/proxmox"
            version = "3.0.2-rc07"
        }
        proxmox-bpg = {
            source  = "bpg/proxmox"
            version = "0.101.1"
        }
    }
}

provider "proxmox" {
    pm_user                     = var.user_root
    pm_password                 = var.user_root_password
    pm_api_url                  = var.pve_api_url
    pm_tls_insecure             = var.pve_api_tls_insecure
}

provider "proxmox-bpg" {
    alias                      = "bpg"
    endpoint                   = var.pve_api_url
    api_token                  = "${var.pve_api_token_id}=${var.pve_api_token_secret}"
    insecure                   = var.pve_api_tls_insecure

    ssh {
        agent       = true
        username    = "root"
        private_key = file(pathexpand(var.ssh_key_private))
        password    = var.user_root_password
    }
}