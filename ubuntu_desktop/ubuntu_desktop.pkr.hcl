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

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "ansible_public_key" {
  type      = string
  sensitive = true
}

# ------------------------------------------------------------------
# Locals (Hardware Specifications & Standardized Naming)
# ------------------------------------------------------------------
locals {
  vm_name   = "tmpl-ubuntu-desktop-2604"
  node_name = "pve"
  vm_id     = 910 

  cores     = 4
  memory    = 4096
  disk_size = "40G"
}

source "proxmox-iso" "ubuntu_desktop" {
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
  template_description = "Ubuntu 26.04 Desktop Golden Image"

  # ------------------------------------------------------------------
  # VM Hardware Configuration
  # ------------------------------------------------------------------
  cores      = local.cores
  memory     = local.memory
  sockets    = 1
  os         = "l26"
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
    iso_file     = "local:iso/ubuntu-26.04-desktop-amd64.iso"
    unmount      = true
  }

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
}

build {
  sources = ["source.proxmox-iso.ubuntu_desktop"]

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