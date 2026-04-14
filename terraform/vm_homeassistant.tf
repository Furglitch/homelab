resource "proxmox_virtual_environment_vm" "homeassistant" {
    provider   = proxmox-bpg.bpg
    depends_on = [proxmox_virtual_environment_download_file.image_debian_13]
    
    name        = "homeassistant"
    vm_id       = 211
    node_name   = var.pve_host_node
    tags        = ["vm", "homeassistant", "automation"]
    
    started     = var.vm_boot_start
    on_boot     = var.vm_boot_start_onboot
    
    # bios        = "ovmf"
    machine     = "q35"
    
    cpu {
        type    = var.hw_cpu
        cores   = 2
        sockets = 1
    }
    
    memory {
        dedicated = 4096
    }
    
    efi_disk {
        datastore_id = var.storage_container
        file_format  = "raw"
        type         = "4m"
    }
    
    disk {
        datastore_id = var.storage_container
        file_format  = "raw"
        interface    = "scsi0"
        size         = 32
        iothread     = true
        discard      = "on"
    }
    
    cdrom {
        file_id   = proxmox_virtual_environment_download_file.image_debian_13.id
        interface = "ide2"
    }
    
    network_device {
        bridge = var.network_bridge
        model  = "virtio"
    }
    
    initialization {
        user_account {
            username = var.user
            password = var.user_password
            keys     = [trimspace(file(var.ssh_key_public))]
        }
        
        ip_config {
            ipv4 {
                address = "${var.network_ip_prefix}234/${var.network_cidr}"
                gateway = var.network_gateway
            }
        }
    }
    
    boot_order = ["scsi0", "ide2"]
    
    lifecycle {
        ignore_changes = [
            started,
            cdrom,
            hostpci,
        ]
    }
}
