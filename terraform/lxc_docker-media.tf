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