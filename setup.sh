#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$ROOT_DIR/terraform"
ANSIBLE_DIR="$ROOT_DIR/ansible"

TF_VAR_FILE="${TF_VAR_FILE:-credentials.tfvars}"
ANSIBLE_PLAYBOOK="${ANSIBLE_PLAYBOOK:-playbooks/docker.yml}"
ANSIBLE_INVENTORY="${ANSIBLE_INVENTORY:-inventory/hosts.yml}"
ANSIBLE_VAULT_FILE="${ANSIBLE_VAULT_FILE:-$HOME/.ansible/vault_pass}"
TERRAFORM_LOCK_TIMEOUT="${TERRAFORM_LOCK_TIMEOUT:-5m}"
TERRAFORM_WAIT_TIMEOUT_SECONDS="${TERRAFORM_WAIT_TIMEOUT_SECONDS:-600}"

VM_TARGETS=(
	"proxmox_virtual_environment_vm.truenas"
	"proxmox_virtual_environment_vm.homeassistant"
	"null_resource.truenas_attach_sata"
)

LXC_TARGETS=(
	"proxmox_lxc.docker_media"
	"proxmox_lxc.docker_web"
	"proxmox_lxc.nginx"
	"proxmox_lxc.wireguard"
	"proxmox_lxc.pihole"
	"proxmox_lxc.pterodactyl_panel"
	"proxmox_lxc.pterodactyl_wings"
	"null_resource.docker_media_tun"
)

section() {
	printf '\n============================================================\n'
	printf '%s\n' "$1"
	printf '============================================================\n\n'
}

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Error: required command not found: $1"
		exit 1
	fi
}

require_file() {
	if [[ ! -f "$1" ]]; then
		echo "Error: required file not found: $1"
		exit 1
	fi
}

prompt_continue() {
	local prompt_text="$1"
	local answer=""

	while true; do
		read -r -p "$prompt_text [y/N]: " answer
		case "$answer" in
			[Yy]|[Yy][Ee][Ss])
				return 0
				;;
			[Nn]|[Nn][Oo]|"")
				echo "Stopping setup at user request."
				exit 1
				;;
			*)
				echo "Please answer yes or no."
				;;
		esac
	done
}

find_terraform_pids() {
	local pid=""
	local cwd=""

	for pid in $(pgrep -x terraform || true); do
		[[ "$pid" == "$$" ]] && continue
		cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"
		if [[ "$cwd" == "$TERRAFORM_DIR" ]]; then
			echo "$pid"
		fi
	done
}

wait_for_terraform_idle() {
	local elapsed=0
	local pids=""

	while true; do
		pids="$(find_terraform_pids | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
		if [[ -z "$pids" ]]; then
			return 0
		fi

		if (( elapsed == 0 )); then
			echo "Waiting for existing Terraform process in $TERRAFORM_DIR to finish: $pids"
		fi

		if (( elapsed >= TERRAFORM_WAIT_TIMEOUT_SECONDS )); then
			echo "Error: Terraform is still running in $TERRAFORM_DIR after ${TERRAFORM_WAIT_TIMEOUT_SECONDS}s."
			echo "Active Terraform PID(s): $pids"
			echo "Wait for that run to finish, or stop it before retrying this script."
			exit 1
		fi

		sleep 2
		elapsed=$((elapsed + 2))
	fi
}

terraform_apply_targets() {
	local phase_name="$1"
	shift
	local targets=("$@")
	local target_args=()

	section "Terraform: ${phase_name}"

	for target in "${targets[@]}"; do
		target_args+=("-target=${target}")
	done

	(
		cd "$TERRAFORM_DIR"
		wait_for_terraform_idle

		if [[ ! -d .terraform ]]; then
			echo "Initializing Terraform..."
			terraform init
		fi

		echo "Applying Terraform targets for ${phase_name}..."
		terraform apply -lock-timeout="$TERRAFORM_LOCK_TIMEOUT" -var-file="$TF_VAR_FILE" "${target_args[@]}"
	)
}

run_ansible() {
	local ansible_cmd=(
		ansible-playbook
		-i "$ANSIBLE_INVENTORY"
		"$ANSIBLE_PLAYBOOK"
	)

	section "Ansible: Apply configuration"

	if [[ -f "$ANSIBLE_VAULT_FILE" ]]; then
		ansible_cmd+=(--vault-password-file "$ANSIBLE_VAULT_FILE")
		echo "Using vault password file: $ANSIBLE_VAULT_FILE"
	else
		echo "Vault password file not found at $ANSIBLE_VAULT_FILE"
		echo "Ansible will prompt for vault password if encrypted vars are used."
	fi

	(
		cd "$ANSIBLE_DIR"
		"${ansible_cmd[@]}"
	)
}

manual_truenas_install_steps() {
	section "Manual Step: Install TrueNAS ISO"
	cat <<'EOF'
In Proxmox, complete the TrueNAS installer for VMID 201 (truenas):
1) Open Proxmox web UI and start VM 201.
2) Open Console and boot from attached TrueNAS ISO.
3) Select the following options:
    - 1. Install/Upgrade
    - Select 'sda QEMU HARDDISK 32 GiB' as the destination media.
    - Select 'Yes' to proceed with installation.
    - 1. Administrative User (truenas_admin)
    - Set a strong password for the admin user.
    - Enable EFI boot mode when prompted.
4) Wait for installation to complete and shutdown the VM.
5) Detach the ISO from the VM in Proxmox after install.
EOF
	prompt_continue "Continue after TrueNAS OS installation is complete?"
}

manual_truenas_ip_steps() {
	section "Manual Step: Configure TrueNAS IP"
	cat <<'EOF'
In the TrueNAS console:
1) Select "1) Configure Network Interfaces".
2) Click 'Enter' to edit the default interface.
3) Add the static IP address: 192.168.1.201/24 and gateway 192.168.1.1
4) Save, press 'a' to apply, 'p' to persist, then 'q' to quit back to the main menu.
EOF
	prompt_continue "Continue after TrueNAS pool setup is complete?"
}

manual_truenas_pool_steps() {
	section "Manual Step: Configure TrueNAS Pool"
	cat <<'EOF'
In the TrueNAS web interface (New IP):
1) Verify the SATA-passthrough disks are visible.
2) Create your storage pool with RAID layout.
3) Create two datasets: media and cloud.
4) Configure NFS shares:
    - Edit Dataset Permissions, click Set ACL, and choose "POSIX_OPEN"
    - Create NFS share and set to start automatically.
5) Confirm pool health is online.
EOF
	prompt_continue "Continue after TrueNAS pool setup is complete?"
}

manual_homeassistant_install_steps() {
	section "Manual Step: Install Home Assistant ISO"
	cat <<'EOF'
In Proxmox, complete the Home Assistant installer for VMID 211 (homeassistant):
1) Start VM 211 and open Console.
2) Boot from the currently attached installer media.
3) Complete the Home Assistant installation process.
4) Wait for first boot to finish and note the assigned/static IP.
5) Detach installer media if required.
EOF
	prompt_continue "Continue after Home Assistant installation is complete?"
}

main() {
	section "Homelab Installation Orchestrator"

	require_cmd terraform
	require_cmd ansible-playbook
	require_file "$TERRAFORM_DIR/$TF_VAR_FILE"
	require_file "$ANSIBLE_DIR/$ANSIBLE_INVENTORY"
	require_file "$ANSIBLE_DIR/$ANSIBLE_PLAYBOOK"

	echo "Root directory: $ROOT_DIR"
	echo "Terraform var file: $TERRAFORM_DIR/$TF_VAR_FILE"
	echo "Ansible playbook: $ANSIBLE_DIR/$ANSIBLE_PLAYBOOK"
	echo "Ansible inventory: $ANSIBLE_DIR/$ANSIBLE_INVENTORY"

	prompt_continue "Start installation now?"

	terraform_apply_targets "Provision Home Assistant + TrueNAS VMs" "${VM_TARGETS[@]}"
	manual_truenas_install_steps
	manual_truenas_ip_steps
	manual_truenas_pool_steps
	manual_homeassistant_install_steps

	terraform_apply_targets "Provision LXC containers" "${LXC_TARGETS[@]}"
	run_ansible

	section "Setup Complete"
	echo "All requested steps have completed."
}

main "$@"
