resource "proxmox_lxc" "media" {
  depends_on = [
    proxmox_virtual_environment_download_file.template_debian_13,
  ]
  ssh_public_keys = file(var.ssh_key_public)

  hostname    = "media"
  vmid        = 101
  target_node = var.pve_host_node
  ostemplate  = "${var.image_template_prefix}${var.image_lxc_debian_13_file}"
  tags        = "lxc;docker;media"
  password    = var.user_password

  start        = var.vm_boot_start
  onboot       = var.vm_boot_start_onboot
  unprivileged = var.lxc_unprivileged

  cores  = 4
  memory = 8192
  swap   = var.hw_memory_swap

  features {
    fuse    = true
    nesting = true
    keyctl  = true
    mount   = "ext4;nfs;cifs"
  }

  rootfs {
    storage = var.storage_container
    size    = "16G"
  }

  network {
    name   = var.network_name
    bridge = var.network_bridge
    ip     = "${var.network_ip_prefix}101/${var.network_cidr}"
    gw     = var.network_gateway
    ip6    = var.network_ipv6_type
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      ostemplate,
      password,
      ssh_public_keys,
      rootfs,
      swap,
      tags,
    ]
  }
}

resource "null_resource" "enable_dri" {
  depends_on = [
    proxmox_lxc.media,
  ]

  triggers = {
    lxc_id         = "101"
    config_version = "1"
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no \
        root@${var.pve_host_ip} bash <<'ENDSSH'

      grep -qxF 'lxc.cgroup2.devices.allow: c 226:* rwm' /etc/pve/lxc/101.conf || \
        echo 'lxc.cgroup2.devices.allow: c 226:* rwm' >> /etc/pve/lxc/101.conf

      grep -qxF 'lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir' /etc/pve/lxc/101.conf || \
        echo 'lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir' >> /etc/pve/lxc/101.conf

      pct reboot 101 || pct start 101
ENDSSH
    EOT
  }
}
