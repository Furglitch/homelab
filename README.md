# Proxmox VE

Infrastructure-as-code for my homelab Proxmox VE host. Everything is declared in Terraform: LXC containers for Docker workloads, full VMs for appliances that need their own kernel (TrueNAS, Home Assistant OS), and the images they boot from.

- **Host:** Proxmox VE, node `pve`
- **Network:** `10.0.XXX.XXX/24`, bridge `vmbr0`, gateway `10.0.XXX.XXX`
- **Storage:** `local` (ISOs / LXC templates), `local-lvm` (VM & container disks)
- **Providers:** [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox) for VMs and image downloads, [`Telmate/proxmox`](https://registry.terraform.io/providers/Telmate/proxmox) for LXC containers

See [`STACK.md`](STACK.md) for the service inventory and per-container resource allocations.

---

## Layout

```
proxmox/
├── STACK.md                    # Service inventory + resource allocations
├── README.md                   # This file
└── terraform/
    ├── provider.tf             # Provider config (bpg + Telmate)
    ├── variables.tf            # All input variables and defaults
    ├── pve_images.tf           # ISO / LXC template downloads
    ├── credentials.tfvars.example
    ├── lxc_101_media.tf        # Media stack (Plex, *arr, ...)
    ├── lxc_102_games.tf        # Games (Calagopus, RomM)
    ├── lxc_103_web.tf          # Web / reverse proxy / SaaS
    ├── lxc_105_download.tf     # VPN + download clients
    ├── lxc_120_monitor.tf      # Monitoring
    ├── vm_111_truenas.tf       # TrueNAS SCALE (SATA passthrough)
    └── vm_112_homeassistant.tf # Home Assistant OS
```

---

## Inventory

| ID  | Name           | Type | vCPU | RAM   | Disk  | Purpose |
|-----|----------------|------|------|-------|-------|---------|
| 101 | `media`        | LXC  | 4    | 8 GB  | 16 GB | Plex, Navidrome, Seerr, Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Recyclarr, Kometa, Tautulli |
| 102 | `gaming`       | LXC  | 12   | 32 GB | 64 GB | Calagopus, RomM |
| 103 | `web`          | LXC  | 2    | 4 GB  | 8 GB  | Nginx Proxy Manager, VaultWarden, ProtonMail Bridge |
| 105 | `download`     | LXC  | 4    | 4 GB  | 16 GB | QBitTorrent, SABnzbd, Gluetun, Deunhealth |
| 111 | `truenas`      | VM   | 4    | 8 GB  | 32 GB | TrueNAS SCALE — Nextcloud, Immich |
| 112 | `home-assistant` | VM | 2    | 4 GB  | 16 GB | Home Assistant OS |
| 120 | `monitor`      | LXC  | 2    | 2 GB  | 8 GB  | Glance, WhatsUpDocker, Dozzle, Homelable, Apprise |

All LXC containers are **unprivileged** and run Docker (`nesting`, `keyctl`, `fuse`, and `ext4;nfs;cifs` mounts enabled).

---

## Prerequisites

1. **Proxmox VE host** reachable over SSH as `root` from the machine running Terraform.
2. **API token** with `PVEAdmin` (or `root@pam`) privileges:
   ```bash
   pveum user token add root@pam terraform --privsep 0
   ```
   Copy the returned secret into your tfvars.
3. **SSH key pair** for container/VM access. The public key is injected into every LXC; the private key is used by the bpg provider's SSH block.
4. **Terraform** >= 1.5 and **OpenSSH client** on the workstation.
5. **Storage** `local` and `local-lvm` present on the node (Proxmox defaults).

---

## Usage

```bash
cd proxmox/terraform

# 1. Configure credentials
cp credentials.tfvars.example credentials.tfvars
$EDITOR credentials.tfvars

# 2. Initialise providers
terraform init

# 3. Review the plan
terraform plan -var-file=credentials.tfvars

# 4. Apply
terraform apply -var-file=credentials.tfvars
```

### Required tfvars

At minimum, override these in `credentials.tfvars`:

| Variable | Description |
|----------|-------------|
| `pve_host_ip` | Proxmox host IP (used for SSH provisioning) |
| `pve_api_url` | API endpoint, e.g. `https://10.0.XXX.XXX:8006/api2/json` |
| `pve_api_token_id` | Token ID, e.g. `root@pam!terraform` |
| `pve_api_token_secret` | Token secret |
| `user_password` | Password for the LXC/VM user accounts |
| `user_root_password` | Proxmox root password (Telmate provider) |
| `ssh_key_public` | Path to the public key injected into containers |
| `ssh_key_private` | Path to the private key used by the bpg provider |
| `hw_disk_sata_controller` | PCI ID of the SATA controller passed to TrueNAS |

> `ssh_key_public` / `ssh_key_private` default to `~/.ssh/id_rsa[.pub]`. If you use
> `id_ed25519`, set both explicitly — `file()` does not expand `~` on its own.

---

## What gets created

### Images (`pve_images.tf`)

| Resource | Content | Datastore | Notes |
|----------|---------|-----------|-------|
| `image_debian_13` | ISO | `local` | Debian 13 DVD ISO (for future VMs) |
| `image_truenas` | ISO | `local` | TrueNAS SCALE, version from `image_lxc_truenas_version` |
| `image_homeassistant` | ISO | `local` | HAOS qcow2, decompressed on download |
| `template_debian_13` | `vztmpl` | `local` | Debian 13 LXC template used by all containers |

All downloads are checksum-verified (`sha256`, except the LXC template which uses `md5` as published by Proxmox).

### Containers

Each `lxc_*.tf` file creates one `proxmox_lxc` resource with:

- Static IPv4 from `network_ip_prefix` + the VMID
- IPv6 via `network_ipv6_type` (default `auto`)
- SSH public key injection
- `onboot` controlled by `vm_boot_start_onboot`
- `ostemplate` in `ignore_changes` so template updates don't force recreation

### VMs

- **`vm_111_truenas.tf`** — TrueNAS SCALE with a dedicated SATA controller passed through via `qm set -hostpci0` (a `null_resource` runs after the VM is created). The installer ISO is attached as `ide2`; eject it after installation.
- **`vm_112_homeassistant.tf`** — HAOS imported from the downloaded qcow2, UEFI
  (`ovmf`) + `q35`, serial console on a socket (`qm terminal 112`).

---

## Special handling: `media` (101)

The media container needs more than the provider can express, so a `null_resource` appends raw LXC config to `/etc/pve/lxc/101.conf` on the host:

- **TUN device** for Gluetun/WireGuard (`/dev/net/tun`, cgroup `10:200`)
- **DRM devices** for hardware transcoding (`/dev/dri`, cgroup `226:*`)
- **NFS bind mount** of the TrueNAS media share at `/nfs/media`
- **Custom idmap** so container UID/GID `1000` maps to host `1000` (for NFS
  permissions), with the remaining range shifted to `101001+`

The block is idempotent (`grep -qxF` guards) and keyed on `config_version` — bump it to re-run. It requires `root:1000:1` in `/etc/subuid` and `/etc/subgid` on the host, which the script adds automatically.

> ⚠️ This resource depends on `null_resource.truenas_share_mounts`, which mounts the
> TrueNAS NFS exports on the Proxmox host. That resource must exist before applying.

---

## Operations

```bash
# Format
terraform fmt -recursive

# Validate without credentials
terraform validate

# Target a single container
terraform apply -var-file=credentials.tfvars -target=proxmox_lxc.web

# Inspect state
terraform state list
terraform state show proxmox_lxc.media
```

### Updating images

Bump the relevant `image_*` variable in `variables.tf` (or override in tfvars) and re-apply. The `download_file` resources re-download when the URL or checksum changes.
Existing containers keep their original template because `ostemplate` is in `ignore_changes` — rebuild them explicitly if you want the new template.

### Destroying

`proxmox_lxc.media` has `prevent_destroy = true`. Remove that line first if you genuinely need to destroy it.

---

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| Apply hangs on a password prompt | `local-exec` SSH calls rely on the agent; load your key or add `-o BatchMode=yes` |
| TrueNAS ISO 404 | Verify the URL built from `image_lxc_truenas_version` resolves |
| Docker won't start in an LXC | Check `nesting`/`keyctl`/`fuse` are enabled and the idmap covers the container's subuid range |
| `hostpci0` attach fails | `hw_disk_sata_controller` must be a valid PCI ID on the host (`lspci`) |

---

## Notes

- State is **local** by default. For anything beyond a single workstation, configure a remote backend so state isn't lost.
- The Telmate provider is pinned to a release candidate (`3.0.2-rc10`). Migrating the LXC resources to `bpg/proxmox` would let you drop the root password and use the API token exclusively.
- `vm_boot_start` defaults to `false` — containers and VMs are created stopped. Set it to `true` (or start them manually) after the first apply.