# API
variable "pve_host_ip" {
    description = "IP address of the Proxmox host"
    type        = string
    default     = "192.168.1.XXX"
}
variable "pve_host_node" {
    description = "Name of the Proxmox node to manage"
    type        = string
    default     = "pve"
}
variable "pve_api_url" {
    description = "URL of the Proxmox API endpoint"
    type = string
    default = "https://192.168.1.XXX:8006/api2/json"
}
variable "pve_api_token_id" {
    description = "Proxmox API token ID for authentication"
    type = string
    sensitive = true
}
variable "pve_api_token_secret" {
    description = "Proxmox API token secret for authentication"
    type = string
    sensitive = true
}
variable "pve_api_tls_insecure" {
    description = "Whether to skip TLS verification for Proxmox API"
    type        = bool
    default     = true
}


# Account
variable "user" {
    description = "Username for the VM/LXC user accounts (e.g., 'user@pve')"
    type        = string
    default     = "user@pve"
}
variable "user_password" {
    description = "Password for the VM/LXC user accounts"
    type        = string
    sensitive   = true
}
variable "user_root" {
    description = "Proxmox root user account (e.g., 'root@pam')"
    type        = string
    default     = "root@pam"
}
variable "user_root_password" {
    description = "Password for the Proxmox root user account"
    type        = string
    sensitive   = true
}


# Storage
variable "storage_iso" {
    description = "ID of the Proxmox storage to use for ISO images (e.g., 'local')"
    type        = string
    default     = "local"
}
variable "storage_lxc" {
    description = "ID of the Proxmox storage to use for LXC templates (e.g., 'local')"
    type        = string
    default     = "local"
}
variable "storage_container" {
    description = "ID of the Proxmox storage to use for VM disks (e.g., 'local-lvm')"
    type        = string
    default     = "local-lvm"
}
variable "storage_size" {
    description = "Default disk size (in GB) for VMs"
    type        = string
    default     = "16G"
}
variable "share_mp_cloud" {
    description = "Mount point for the 'cloud' NFS share on TrueNAS"
    type        = string
    default     = "/mnt/share/truenas-cloud"
}
variable "share_mp_media" {
    description = "Mount point for the 'media' NFS share on TrueNAS"
    type        = string
    default     = "/mnt/share/truenas-media"
}


# Hardware
variable "hw_cpu" {
    description = "CPU type to use for VMs (e.g., 'host' for passthrough)"
    type        = string
    default     = "host"
}
variable "hw_cpu_cores" {
    description = "Number of CPU cores to allocate to VMs"
    type        = number
    default     = 2
}
variable "hw_cpu_sockets" {
    description = "Number of CPU sockets to allocate to VMs"
    type        = number
    default     = 1
}
variable "hw_memory" {
    description = "Amount of memory (in MB) to allocate to VMs"
    type        = number
    default     = 2048
}
variable "hw_memory_swap" {
    description = "Amount of swap memory (in MB) to allocate to VMs"
    type        = number
    default     = 512
}
variable "hw_disk_sata_controller" {
    description = "PCI ID of the SATA controller to attach additional disks to (e.g., '0000:00:1f.2')"
    type        = string
    default     = "0000:00:XX.X"
}


# Network
variable "network_name" {
    description = "Name of the Proxmox network interface"
    type        = string
    default     = "eth0"
}
variable "network_bridge" {
    description = "Name of the Proxmox network bridge to connect VMs to"
    type        = string
    default     = "vmbr0"
}
variable "network_model" {
    description = "Network model to use for VM network devices (e.g., 'virtio', 'e1000')"
    type        = string
    default     = "virtio"
}
variable "network_ip_prefix" {
    description = "IP address prefix for VMs (e.g., 192.168.1.)"
    type        = string
    default     = "192.168.1."
}
variable "network_cidr" {
    description = "CIDR notation for the network (e.g., 24 for 255.255.255.0)"
    type        = number
    default     = 24
}
variable "network_gateway" {
    description = "Gateway IP address for the network"
    type        = string
    default     = "192.168.1.1"
}
variable "network_ipv6_type" {
    description = "IPv6 configuration type (e.g., 'auto', 'dhcp', or 'static')"
    type        = string
    default     = "auto"
}


# Images
variable "image_template_prefix" {
    description = "Prefix for Proxmox template paths (e.g., 'local:vztmpl/')"
    type        = string
    default     = "local:vztmpl/"
}
variable "image_iso_prefix" {
    description = "Prefix for Proxmox ISO paths (e.g., 'local:iso/')"
    type        = string
    default     = "local:iso/"
}
variable "image_debian_12_file" {
    description = "Filename of the Debian 12 template in Proxmox storage"
    type        = string
    default     = "debian-12-standard_12.12-1_amd64.tar.zst"
}
variable "image_debian_12_md5" {
    description = "Expected MD5 checksum for the Debian 12 template"
    type        = string
    default     = "4e5a0a7183b6c8ca6867489820961e88"
}
variable "image_debian_13_file" {
    description = "Filename of the Debian 13 template in Proxmox storage"
    type        = string
    default     = "debian-13-standard_13.1-2_amd64.tar.zst"
}
variable "image_debian_13_md5" {
    description = "MD5 checksum for the Debian 13 template file"
    type        = string
    default     = "5ee736fbc37d2068ca6695d7686b7d62"
}
variable "image_truenas_version" {
    description = "Version of the TrueNAS ISO to download (e.g., ['Goldeye', '25.10.1'])"
    type        = list(string)
    default     = ["Fangtooth", "25.04.2.6"]
}
variable "image_truenas_sha256" {
    description = "Expected SHA256 checksum for the TrueNAS ISO"
    type        = string
    default     = "c766aed47ec6cd872a7c9159929280245c4f5a26a0358f5522e3245f04be54cc"
}
variable "image_homeassistant_version" {
    description = "Version of the Home Assistant image to download (e.g., '17.2')"
    type        = string
    default     = "17.2"
}
variable "image_homeassistant_sha256" {
    description = "Expected SHA256 checksum for the Home Assistant ISO"
    type        = string
    default     = "474b8f2e657f697c7a226acd5b6d0b8f74b2dfd19f71487a18238d8b36a3604f"
}

# VM Options
variable "vm_boot_start" {
    description = "Whether to start VMs immediately after creation"
    type        = bool
    default     = true
}
variable "vm_boot_start_onboot" {
    description = "Whether to set VMs to start on Proxmox host boot"
    type        = bool
    default     = true
}


# LXC Options
variable "lxc_unprivileged" {
    description = "Whether to create unprivileged LXC containers (recommended for production use)"
    type = bool
    default = true
}


# Local SSH Keys
variable "ssh_key_public" {
    description = "Path to the public SSH key to be used for authentication"
    type        = string
    default     = "~/.ssh/id_rsa.pub"
}
variable "ssh_key_private" {
    description = "Path to the private SSH key to be used for authentication"
    type        = string
    default     = "~/.ssh/id_rsa"
}