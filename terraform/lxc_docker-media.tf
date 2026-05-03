resource "proxmox_lxc" "docker_media" {
    depends_on = [
        proxmox_virtual_environment_download_file.template_debian_13,
        proxmox_virtual_environment_vm.truenas,
    ]
	ssh_public_keys     = file(var.ssh_key_public)

	hostname	 		= "docker-media"
	vmid         		= 221
	target_node  		= var.pve_host_node
	ostemplate   		= "${var.image_template_prefix}${var.image_lxc_debian_13_file}"
	tags	   			= "lxc;docker;media"
	password            = var.user_password

	start	   			= var.vm_boot_start
	onboot	   			= var.vm_boot_start_onboot
	unprivileged 		= var.lxc_unprivileged

	cores 				= 4
	memory      		= 4096
	swap        		= var.hw_memory_swap

	features {
		fuse            = true
		nesting         = true
		keyctl          = true
		mount           = "ext4;nfs;cifs"
	}

	rootfs {
		storage 		= var.storage_container
		size 			= var.storage_size
	}

	# mountpoint {
	# 	key 			= "mp0"
	# 	slot			= 0
	# 	storage 		= var.share_mp_media
	# 	mp				= var.share_mp_media
	# 	size 			= "1G"
	# 	backup 			= false
	# }

	network {
		name   			= var.network_name
		bridge 			= var.network_bridge
		ip     		    = "${var.network_ip_prefix}221/${var.network_cidr}"
		gw		 		= var.network_gateway
		ip6 			= var.network_ipv6_type
	}

	lifecycle {
		ignore_changes = [
			ostemplate,
		]
	}
}

resource "null_resource" "docker_media_tun" {
	depends_on = [proxmox_lxc.docker_media]

	provisioner "local-exec" {
		command = <<-EOT
			echo "[[[PASSWORD ENTRY NEEDED]]]"

			ssh -o StrictHostKeyChecking=no \
				root@${var.pve_host_ip} bash << 'ENDSSH'

			grep -qxF 'lxc.cgroup2.devices.allow: c 10:200 rwm' /etc/pve/lxc/221.conf || \
				echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/221.conf

			grep -qxF 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' /etc/pve/lxc/221.conf || \
				echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/221.conf

			grep -qxF 'lxc.cgroup2.devices.allow: c 226:* rwm' /etc/pve/lxc/221.conf || \
				echo 'lxc.cgroup2.devices.allow: c 226:* rwm' >> /etc/pve/lxc/221.conf

			grep -qxF 'lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir' /etc/pve/lxc/221.conf || \
				echo 'lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir' >> /etc/pve/lxc/221.conf

			pct reboot 221 || pct start 221
ENDSSH
		EOT
	}
}