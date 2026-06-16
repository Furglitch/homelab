resource "proxmox_lxc" "pihole" {
	depends_on = [ proxmox_virtual_environment_download_file.template_debian_13 ]
	ssh_public_keys     = file(var.ssh_key_public)

	hostname	 		= "pihole"
	vmid         		= 233
	target_node  		= var.pve_host_node
	ostemplate   		= "${var.image_template_prefix}${var.image_lxc_debian_13_file}"
	tags	   			= "lxc;pihole;network;dns"
	password            = var.user_password

	start	   			= var.vm_boot_start
	onboot	   			= var.vm_boot_start_onboot
	unprivileged 		= var.lxc_unprivileged

	features {
		fuse            = true
		nesting         = true
	}

	cores       		= 1
	memory      		= var.hw_memory
	swap				= var.hw_memory_swap

	rootfs {
		storage 		= var.storage_container
		size 			= "4G"
	}

	network {
		name   			= var.network_name
		bridge 			= var.network_bridge
		ip     		    = "${var.network_ip_prefix}233/${var.network_cidr}"
		gw		 		= var.network_gateway
		ip6 			= var.network_ipv6_type
	}

	lifecycle {
		ignore_changes = [
			ostemplate,
		]
	}
}