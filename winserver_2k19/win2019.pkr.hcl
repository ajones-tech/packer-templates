packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "pm_api_url" { type = string }
variable "pm_api_token_id" { type = string }
variable "pm_api_token_secret" { type = string }

source "proxmox-iso" "windows-server-2019" {
  proxmox_url = var.pm_api_url
  username    = var.pm_api_token_id
  token       = var.pm_api_token_secret
  insecure_skip_tls_verify = true

  node                 = "pve"
  vm_name              = "srv19-golden-template"
  os                   = "win10" 
  qemu_agent           = true
  cores                = 4
  memory               = 4096
  scsi_controller      = "virtio-scsi-single"
  
  disks {
    disk_size    = "100G"
    format       = "raw"
    storage_pool = "local-lvm"
    type         = "scsi"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  boot_iso {
    type     = "ide"
    iso_file = "local:iso/win_server2019.iso"
    unmount  = true
  }

  # Bypass the "Press Any Key to boot from CD" prompt
  boot_wait    = "3s"
  boot_command = ["<enter><wait><enter><wait><enter><wait><enter>"]
  
  # 1st Extra CD: VirtIO Virtual Hardware Drivers
  additional_iso_files {
    iso_file = "local:iso/virtio-win.iso"
    unmount  = true
  }

  # 2nd Extra CD: Your manually wrapped static Answer File ISO
  additional_iso_files {
    iso_file = "local:iso/unattend.iso"
    unmount  = true
  }

  communicator   = "ssh"
  ssh_username   = "Administrator"
  ssh_password   = "CyberLab!2026"
  ssh_timeout    = "2h"
}

build {
  sources = ["source.proxmox-iso.windows-server-2019"]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Windows Server 2019 Core build complete!'",
      "Write-Host 'Golden Template successfully sealed.'"
    ]
  }
}