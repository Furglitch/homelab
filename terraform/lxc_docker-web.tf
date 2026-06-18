resource "proxmox_lxc" "docker_web" {
	depends_on = [ 
		proxmox_virtual_environment_download_file.template_debian_13
	]
	ssh_public_keys     = file(var.ssh_key_public)

	hostname	 		= "docker-web"
	vmid         		= 222
	target_node  		= var.pve_host_node
	ostemplate   		= "${var.image_template_prefix}${var.image_lxc_debian_13_file}"
	tags	   			= "lxc;docker;web"
	password            = var.user_password

	start	   			= var.vm_boot_start
	onboot	   			= var.vm_boot_start_onboot
	unprivileged 		= var.lxc_unprivileged

	cores       		= var.hw_cpu_cores
	memory      		= var.hw_memory
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

	network {
		name   			= var.network_name
		bridge 			= var.network_bridge
		ip     		    = "${var.network_ip_prefix}222/${var.network_cidr}"
		gw		 		= var.network_gateway
		ip6 			= var.network_ipv6_type
	}

	lifecycle {
		ignore_changes = [
			ostemplate,
		]
	}
}

resource "null_resource" "docker_web_tun" {
	depends_on = [
		proxmox_lxc.docker_web,
		null_resource.truenas_share_mounts,
	]

	triggers = {
		lxc_id = proxmox_lxc.docker_web.id
	}

	provisioner "local-exec" {
		command = <<-EOT
			echo "[[[PASSWORD ENTRY NEEDED]]]"

			ssh -o StrictHostKeyChecking=no \
				root@${var.pve_host_ip} bash << 'ENDSSH'

			grep -qxF 'lxc.mount.entry: /mnt/share/truenas-cloud nfs/cloud none bind,optional,create=dir' /etc/pve/lxc/222.conf || \
				echo 'lxc.mount.entry: /mnt/share/truenas-cloud nfs/cloud none bind,optional,create=dir' >> /etc/pve/lxc/222.conf

			pct reboot 222 || pct start 222
ENDSSH
		EOT
	}
}