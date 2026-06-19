resource "proxmox_virtual_environment_vm" "proxmox_backup" {
    provider   = proxmox-bpg.bpg
    depends_on = [proxmox_virtual_environment_download_file.image_proxmox_backup]

    name      = "proxmox-backup"
    vm_id     = 250
    node_name = var.pve_host_node
    tags      = ["vm", "backup", "proxmox-backup"]

    started = var.vm_boot_start
    on_boot = var.vm_boot_start_onboot

    bios    = "ovmf"
    machine = "q35"

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
        size         = 128
        iothread     = true
        discard      = "on"
    }

    cdrom {
        file_id   = proxmox_virtual_environment_download_file.image_proxmox_backup.id
        interface = "ide2"
    }

    network_device {
        bridge = var.network_bridge
        model  = "virtio"
    }

    boot_order = ["scsi0", "ide2"]

    lifecycle {
        ignore_changes = [
            started,
            cdrom,
        ]
    }
}
