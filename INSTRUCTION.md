# Usage Instructions

## LXCs

## VMs

### TrueNAS

Download of the TrueNAS CE ISO and initial creation of the VM is automated by Terraform, but the installation process requires manual interaction. Follow the steps below to complete the installation of TrueNAS on VMID 201 (truenas):

#### Initial Installation

1) Open Proxmox web UI and start VM 201
2) Open Console and boot from attached TrueNAS ISO
3) Select the following options:
    - `1. Install/Upgrade`
    - Select the destination media (32GB)
    - Select `Yes` to proceed with installation
    - `1. Administrative User (truenas_admin)`
    - Set a strong password for the admin user
    - Enable EFI boot mode when prompted
4) Wait for installation to complete and shutdown the VM
5) Detach the ISO from the VM in Proxmox after install

#### IP Address

Previously, the IP was set post-install using the VM's console, but this is no longer used. Instead, the IP address now must be configured via settings on your router or DHCP server.

#### Pool and Dataset Creation

1) Verify the SATA-passthrough disks are visible.
2) Import the existing pool found on the disks
3) Confirm pool health is online.

OR

2) Create your storage pool with RAID layout.
3) Create two datasets: media and cloud.
4) Configure NFS shares:
    - Edit Dataset Permissions, click Set ACL, and choose "POSIX_OPEN"
    - Create NFS share and set to start automatically.
5) Confirm pool health is online.

### Home Assistant

Download of the Home Assistant installer and initial creation of the VM is automated by Terraform, but the installation process requires manual interaction. Follow the steps below to complete the installation of Home Assistant on VMID 211 (home_assistant):

#### Initial Installation

1) Start VM 211 and open Console.
2) Boot from the currently attached installer media.
3) Complete the Home Assistant installation process.
4) Wait for first boot to finish and note the assigned/static IP.
5) Detach installer media if required.

#### IP Address

1) Navigate to Supervisor > System.
2) Under 'Configure network interfaces', change IPv4 to 'Static' and set the following:
	- IP address: 192.168.1.211
	- Netmask: 255.255.255.0
	- Gateway address: 192.168.1.1
3) Save and apply the network configuration.
4) Restart Home Assistant to ensure the new IP is active.