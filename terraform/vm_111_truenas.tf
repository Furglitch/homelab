resource "proxmox_virtual_environment_vm" "truenas" {
  provider   = proxmox-bpg.bpg
  depends_on = [proxmox_virtual_environment_download_file.image_truenas]

  name      = "truenas"
  vm_id     = 111
  node_name = var.pve_host_node
  tags      = ["vm", "truenas", "storage"]

  started = var.vm_boot_start
  on_boot = var.vm_boot_start_onboot

  bios    = "seabios"
  machine = "q35"

  cpu {
    type    = var.hw_cpu
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

  # initialization {
  #     ip_config {
  #         ipv4 {
  #             address = "${var.network_ip_prefix}111/${var.network_cidr}"
  #             gateway = var.network_gateway
  #         }
  #     }
  # }

  boot_order = ["scsi0", "ide2"]

  lifecycle {
    ignore_changes = [
      started,
      cdrom,
      hostpci,
      initialization,
    ]
  }
}

resource "null_resource" "truenas_attach_sata" {
  depends_on = [proxmox_virtual_environment_vm.truenas]

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.truenas]
  }

  triggers = {
    pci_id = var.hw_disk_sata_controller
  }

  provisioner "local-exec" {
    command = <<-EOT
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                root@${var.pve_host_ip} bash << 'ENDSSH'
            
            VMID=111
            PCI_ID="${var.hw_disk_sata_controller}"
            
            echo "Attaching SATA controller $PCI_ID to VM $VMID..."
            
            qm set $VMID -delete hostpci0 || true
            qm set $VMID -hostpci0 $PCI_ID,pcie=1,rombar=0
            
            echo "SATA controller attached successfully"
ENDSSH
        EOT
  }
}

resource "null_resource" "truenas_share_mounts" {
	triggers = {
		proxmox_host = var.pve_host_ip
		media_share  = "${network_ip_prefix}201:${var.share_mp_media}"
		cloud_share  = "${network_ip_prefix}201:${var.share_mp_cloud}"
	}

	provisioner "local-exec" {
		command = <<-EOT
			echo "[[[PASSWORD ENTRY NEEDED]]]"

			ssh -o StrictHostKeyChecking=no \
				root@${var.pve_host_ip} bash << 'ENDSSH'

			apt-get update
			apt-get install -y nfs-common

			mkdir -p ${var.share_mp_media}
		grep -qxF '${network_ip_prefix}201:/mnt/tank/media ${var.share_mp_media} nfs defaults,_netdev,noatime 0 0' /etc/fstab || \
			echo '${network_ip_prefix}201:/mnt/tank/media ${var.share_mp_media} nfs defaults,_netdev,noatime 0 0' >> /etc/fstab
		timeout 30 mount ${var.share_mp_media} || echo "WARNING: Failed to mount media share (TrueNAS may be offline)"

		mkdir -p ${var.share_mp_cloud}
		grep -qxF '${network_ip_prefix}201:/mnt/tank/cloud ${var.share_mp_cloud} nfs defaults,_netdev,noatime 0 0' /etc/fstab || \
			echo '${network_ip_prefix}201:/mnt/tank/cloud ${var.share_mp_cloud} nfs defaults,_netdev,noatime 0 0' >> /etc/fstab
		timeout 30 mount ${var.share_mp_cloud} || echo "WARNING: Failed to mount cloud share (TrueNAS may be offline)"

		echo "fstab entries are in place. Mounts will be available once TrueNAS is reachable."
ENDSSH
		EOT
	}
}