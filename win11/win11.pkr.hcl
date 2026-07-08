packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type      = string
  sensitive = true
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

# Secure variable for SSH
variable "ssh_password" {
  type      = string
  sensitive = true
}

source "proxmox-iso" "windows-11" {
  proxmox_url              = var.pm_api_url
  username                 = var.pm_api_token_id
  token                    = var.pm_api_token_secret
  insecure_skip_tls_verify = true
  
  node                     = "pve" 
  vm_id                    = 902

  vm_name              = "tmpl-win-11-pro-v1"
  template_description = "Windows 11 Pro Template"
  os                   = "win11"
  cores                = 4
  sockets              = 1
  cpu_type             = "host"
  memory               = 8192 
  machine              = "q35"
  bios                 = "ovmf"

  efi_config {
    efi_storage_pool  = "local-lvm"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  tpm_config {
    tpm_storage_pool = "local-lvm"
    tpm_version      = "v2.0"
  }

  qemu_agent = true

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  scsi_controller = "virtio-scsi-single"
  
  disks {
    type         = "scsi"
    disk_size    = "64G"
    storage_pool = "local-lvm"
    format       = "raw"
    discard      = true
    ssd          = true
  }

  boot_iso {
    type     = "ide"
    iso_file = "local:iso/win11.iso" 
    unmount  = true
  }

  additional_iso_files {
    type     = "sata"
    index    = "1"
    iso_file = "local:iso/unattend 1.iso"
    unmount  = true
  }

  additional_iso_files {
    type     = "sata"
    index    = "2"
    iso_file = "local:iso/virtio-win.iso" 
    unmount  = true
  }

  boot = "order=ide0;scsi0"

  boot_wait         = "2s"
  boot_key_interval = "100ms"
  
  boot_command = [
    "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar>"
  ]

  communicator   = "ssh"
  ssh_username   = "sysadmin"
  ssh_password   = var.ssh_password
  ssh_timeout    = "12h"
  ssh_agent_auth = false
}

build {
  sources = ["source.proxmox-iso.windows-11"]

  # Install lightweight applications over SSH via Winget
  provisioner "powershell" {
    inline = [
      "Write-Host '>>> Installing Notepad++...'",
      "winget install --id Notepad++.Notepad++ --exact --silent --accept-package-agreements --accept-source-agreements",
      
      "Write-Host '>>> Installing Windows Terminal...'",
      "winget install --id Microsoft.WindowsTerminal --exact --silent --accept-package-agreements --accept-source-agreements",
      
      "Write-Host '>>> Installing PowerShell 7...'",
      "winget install --id Microsoft.PowerShell --exact --silent --accept-package-agreements --accept-source-agreements"
    ]
  }

  # Generalize the image for templating
  provisioner "powershell" {
    inline = [
      "Write-Host '>>> Running Sysprep to finalize template...'",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit"
    ]
  }
}