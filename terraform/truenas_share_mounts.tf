resource "null_resource" "truenas_share_mounts" {
	triggers = {
		proxmox_host = var.pve_host_ip
		media_share  = "192.168.1.201:/mnt/tank/media"
		cloud_share  = "192.168.1.201:/mnt/tank/cloud"
	}

	provisioner "local-exec" {
		command = <<-EOT
			echo "[[[PASSWORD ENTRY NEEDED]]]"

			ssh -o StrictHostKeyChecking=no \
				root@${var.pve_host_ip} bash << 'ENDSSH'

			apt-get update
			apt-get install -y nfs-common

			mkdir -p /mnt/share/truenas-media
		grep -qxF '192.168.1.201:/mnt/tank/media /mnt/share/truenas-media nfs defaults,_netdev,noatime 0 0' /etc/fstab || \
			echo '192.168.1.201:/mnt/tank/media /mnt/share/truenas-media nfs defaults,_netdev,noatime 0 0' >> /etc/fstab
		timeout 30 mount /mnt/share/truenas-media || echo "WARNING: Failed to mount media share (TrueNAS may be offline)"

		mkdir -p /mnt/share/truenas-cloud
		grep -qxF '192.168.1.201:/mnt/tank/cloud /mnt/share/truenas-cloud nfs defaults,_netdev,noatime 0 0' /etc/fstab || \
			echo '192.168.1.201:/mnt/tank/cloud /mnt/share/truenas-cloud nfs defaults,_netdev,noatime 0 0' >> /etc/fstab
		timeout 30 mount /mnt/share/truenas-cloud || echo "WARNING: Failed to mount cloud share (TrueNAS may be offline)"

		echo "fstab entries are in place. Mounts will be available once TrueNAS is reachable."
ENDSSH
		EOT
	}
}