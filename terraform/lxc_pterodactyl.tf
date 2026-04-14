resource "proxmox_lxc" "pterodactyl_panel" {
	depends_on = [ proxmox_virtual_environment_download_file.template_debian_13 ]
	ssh_public_keys     = file(var.ssh_key_public)

	hostname	 		= "pterodactyl-panel"
	vmid         		= 241
	target_node  		= var.pve_host_node
	ostemplate   		= "${var.image_template_prefix}${var.image_lxc_debian_13_file}"
	tags	   			= "lxc;pterodactyl;game"
	password            = var.user_password

	start	   			= var.vm_boot_start
	onboot	   			= var.vm_boot_start_onboot
	unprivileged 		= var.lxc_unprivileged

	cores       		= var.hw_cpu_cores
	memory      		= 4192

	rootfs {
		storage 		= var.storage_container
		size 			= var.storage_size
	}

	network {
		name   			= var.network_name
		bridge 			= var.network_bridge
		ip     		    = "${var.network_ip_prefix}241/${var.network_cidr}"
		gw		 		= var.network_gateway
		ip6 			= var.network_ipv6_type
	}

	lifecycle {
		ignore_changes = [
			ostemplate,
		]
	}
}

resource "proxmox_lxc" "pterodactyl_wings" {
	depends_on = [ proxmox_virtual_environment_download_file.template_debian_13 ]
	ssh_public_keys     = file(var.ssh_key_public)

	hostname	 		= "pterodactyl-wings"
	vmid         		= 242
	target_node  		= var.pve_host_node
	ostemplate   		= "${var.image_template_prefix}${var.image_lxc_debian_13_file}"
	tags	   			= "lxc;pterodactyl;docker;game"
	password            = var.user_password

	start	   			= var.vm_boot_start
	onboot	   			= var.vm_boot_start_onboot
	unprivileged 		= var.lxc_unprivileged

	cores       		= 24
	memory      		= 49152
    swap        		= 8192

	rootfs {
		storage 		= var.storage_container
		size 			= "128G"
	}

	features {
		fuse            = true
		nesting         = true
		keyctl          = true
		mount           = "ext4;nfs;cifs"
	}

	network {
		name   			= var.network_name
		bridge 			= var.network_bridge
		ip     		    = "${var.network_ip_prefix}242/${var.network_cidr}"
		gw		 		= var.network_gateway
		ip6 			= var.network_ipv6_type
	}

	lifecycle {
		ignore_changes = [
			ostemplate,
		]
	}
}