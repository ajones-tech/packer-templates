packer {
  required_plugins {
    proxmox = {
      version = "1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# ------------------------------------------------------------------
# Variables
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
# Locals
# ------------------------------------------------------------------
locals {
  vm_name   = "tmpl-kali-linux"
  node_name = "pve"
  vm_id     = 920

  cores     = 4
  memory    = 4096
  disk_size = "50G"
}

source "proxmox-iso" "kali" {
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
  template_description = "Kali Linux Automated Golden Image"

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
    type     = "ide"
    iso_file = "local:iso/kali-linux-2026.1-installer-amd64.iso" 
    unmount  = true
  }

  http_directory    = "http"
  http_bind_address = "10.0.0.6"
  http_port_min     = 8100
  http_port_max     = 8150

  # ------------------------------------------------------------------
  # Boot & Provisioning
  # ------------------------------------------------------------------
  boot_wait = "10s"
  
  boot_command = [
    "<wait5s>",
    "<down>",      
    "<tab><wait>", 
    " auto=true",
    " priority=critical",
    " url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " locale=en_US.UTF-8",
    " keymap=us",
    "<enter>"
  ]

  communicator = "ssh"
  ssh_username = "sysadmin"
  ssh_password = var.ssh_password
  ssh_timeout  = "1h" 
}

build {
  sources = ["source.proxmox-iso.kali"]

  provisioner "shell" {
    inline = [
      "echo 'Cleaning up machine-id...'",
      "sudo rm -f /etc/machine-id",
      "sudo touch /etc/machine-id",
      "sudo apt-get clean"
    ]
  }
}