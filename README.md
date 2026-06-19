# Homelab

## VMs

| No. | Purpose             | Name              |
| --- | ------------------- | ----------------- |
| 201 | TrueNAS Scale       | truenas           |
| 211 | Home Assistant      | homeassistant     |
| 221 | Docker Media Server | docker-media      |
| 222 | Docker Web Server   | docker-web        |
| 231 | NGINX Proxy Manager | nginx             |
| 232 | WireGuard VPN       | wireguard         |
| 233 | Pi-Hole DNS         | pihole            |
| 240 | Pterodactyl Panel   | pterodactyl       |
| 241 | Pterodactyl Wings   | pterodactyl-wings |
| 250 | Proxmox Backup      | proxmox-backup    |

## Repo Structure

## Installation
1. Enable VT-d and IOMMU in the BIOS (PCI passthrough support, specifically for SATA controller)
2. Install Proxmox VE on the host machine
3. Run `ssh-copy-id -i ~/.ssh/id_rsa root@<proxmox_host_ip>` on your local machine to copy your SSH key to the Proxmox host for passwordless authentication
4. Install Terraform and Ansible locally
5. Adjust credentials files
   - `terraform/credentials.tfvars` - Update Proxmox host IP, root password, and other variables as needed
6. Run Terraform to provision VMs and LXCs
   ```bash
   cd terraform
   terraform init
   terraform apply -var-file=credentials.tfvars
   ```
   - VMs: [REQUIRES MANUAL INTERACTION] ISO is automatically downloaded, but installer needs manual intervention for initial setup.