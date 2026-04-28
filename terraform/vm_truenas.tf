resource "proxmox_virtual_environment_vm" "truenas" {
    provider   = proxmox-bpg.bpg
    depends_on = [proxmox_virtual_environment_download_file.image_truenas]
    
    name        = "truenas"
    vm_id       = 201
    node_name   = var.pve_host_node
    tags        = ["vm", "storage", "truenas"]
    
    started     = var.vm_boot_start
    on_boot     = var.vm_boot_start_onboot
    
    # bios        = "ovmf"
    machine     = "q35"
    
    cpu {
        type    = "host"
        cores   = 4
        sockets = 1
    }
    
    memory {
        dedicated = 8192
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
        file_id   = proxmox_virtual_environment_download_file.image_truenas.id
        interface = "ide2"
    }
    
    network_device {
        bridge = var.network_bridge
        model  = "virtio"
    }
    
    initialization {
        ip_config {
            ipv4 {
                address = "${var.network_ip_prefix}201/${var.network_cidr}"
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

resource "null_resource" "truenas_attach_sata" {
    depends_on = [proxmox_virtual_environment_vm.truenas]
    
    triggers = {
        pci_id = var.hw_disk_sata_controller
    }
    
    provisioner "local-exec" {
        command = <<-EOT
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                root@${var.pve_host_ip} bash << 'ENDSSH'
            
            VMID=201
            PCI_ID="${var.hw_disk_sata_controller}"
            
            echo "Attaching SATA controller $PCI_ID to VM $VMID..."
            
            qm set $VMID -delete hostpci0 || true
            qm set $VMID -hostpci0 $PCI_ID,pcie=1
            
            echo "SATA controller attached successfully"
ENDSSH
        EOT
    }
}