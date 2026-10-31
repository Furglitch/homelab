resource "proxmox_virtual_environment_vm" "home-assistant" {
  provider   = proxmox-bpg.bpg
  depends_on = [proxmox_virtual_environment_download_file.image_homeassistant]

  name      = "home-assistant"
  vm_id     = 112
  node_name = var.pve_host_node
  tags      = ["vm", "home-assistant", "smarthome"]

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
    file_id      = proxmox_virtual_environment_download_file.image_homeassistant.id
    interface    = "scsi0"
    size         = 16
    iothread     = true
    discard      = "on"
  }

  scsi_hardware = "virtio-scsi-pci"

  serial_device {
    device = "socket"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["scsi0"]

  lifecycle {
    ignore_changes = [
      started,
      hostpci,
      usb,
    ]
  }
}
