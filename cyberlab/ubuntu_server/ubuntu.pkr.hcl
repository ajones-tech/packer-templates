packer {
  required_plugins {
    proxmox = {
      version = "1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# ------------------------------------------------------------------
# Variables (Values dynamically injected via your local .env file)
# ------------------------------------------------------------------
variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "ansible_public_key" {
  type      = string
  sensitive = true
}
variable "ssh_password" {
  type = string
  sensitive = true
}
# ------------------------------------------------------------------
# Locals (Hardware Specifications & Standardized Naming)
# ------------------------------------------------------------------
locals {
  vm_name   = "tmpl-ubuntu-2510-v1"
  node_name = "pve"
  vm_id     = 905 # Update to your preferred template ID

  # Hardware Specs
  cores     = 2
  memory    = 2048
  disk_size = "30G"
}

source "proxmox-iso" "ubuntu" {
  # ------------------------------------------------------------------
  # Connection Info
  # ------------------------------------------------------------------
  proxmox_url              = var.pm_api_url
  username                 = var.pm_api_token_id
  token                    = var.pm_api_token_secret
  insecure_skip_tls_verify = true

  node                 = local.node_name
  vm_id                = local.vm_id
  vm_name              = local.vm_name
  template_description = "Ubuntu 25.10 Golden Image"

  # ------------------------------------------------------------------
  # VM Hardware Configuration
  # ------------------------------------------------------------------
  cores   = local.cores
  memory  = local.memory
  sockets = 1
  os      = "l26"
  qemu_agent = true
  
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = local.disk_size
    format       = "raw"
    storage_pool = "local-lvm"
    type         = "scsi"
    discard      = true
    ssd          = true
  }

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # ------------------------------------------------------------------
  # Installation Media
  # ------------------------------------------------------------------
  boot_iso {
    type         = "ide"
    iso_file     = "local:iso/ubuntu-25.10-live-server-amd64.iso"
    unmount      = true
    iso_checksum = "sha256:dc54870e5261c0abad19f74b8146659d10e625971792bd42d7ecde820b60a1d0"
  }

  # [PLACEHOLDER: The cidata block for the user-data.yaml will go here]
# Dynamically generate the cidata ISO in memory and attach it
  # Mounts the locally compiled and manually uploaded cloud-init disk
  additional_iso_files {
    type     = "sata"
    index    = "1"
    iso_file = "local:iso/ubuntu-cidata.iso"
    unmount  = true
  }
  # ------------------------------------------------------------------
  # Boot & Provisioning
  # ------------------------------------------------------------------
  boot_wait         = "5s"
  boot_key_interval = "100ms"
  
  # Removes the default --- and appends the autoinstall command
  boot_command = [
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs>", 
    " autoinstall ---",
    "<wait5s>",
    "<f10>"
  ]

  communicator = "ssh"
  ssh_username = "sysadmin"
  ssh_password = var.ssh_password
  ssh_timeout  = "2h"
  # We will rely on cloud-init to inject the password/key so Packer can connect
}

build {
  sources = ["source.proxmox-iso.ubuntu"]

  # Final cleanup to ensure a pristine template
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to finish...'",
      "cloud-init status --wait",
      "echo 'Cleaning up cloud-init cache and machine-id...'",
      "sudo cloud-init clean --logs",
      "sudo rm -f /etc/machine-id",
      "sudo touch /etc/machine-id"
    ]
  }
}