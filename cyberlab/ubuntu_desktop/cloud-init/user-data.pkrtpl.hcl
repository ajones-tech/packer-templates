#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  
  identity:
    hostname: ubuntu-desktop-tmpl
    username: sysadmin
    password: "$6$gAz3aFy6hOguvcx/$/ll2siSThqUb6nzWrQ6rGap/kPGfpiRZ5wtIlPW7zxqgNlGQUh14KBfYfCpmEkAdt8i44ETrojsV1cTpFvdG4."
  
  ssh:
    install-server: true # Desktop does NOT include SSH by default. This forces it.
    allow-pw: true
    disable_root: true
    allow_public_ssh_keys: true
  
  packages:
    - openssh-server
    - cloud-init
    - qemu-guest-agent

  # Disable automatic updates during the template phase to prevent apt-lock errors
  updates: security

  user-data:
    timezone: America/Chicago
    users:
      - name: sysadmin
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - "${ansible_public_key}"
  
  late-commands:
    # 1. Enable Proxmox communication
    - curtin in-target -- systemctl enable qemu-guest-agent
    
    # 2. Kill the GNOME Welcome Wizard permanently
    - curtin in-target -- apt-get remove -y gnome-initial-setup
    
    # 3. Prevent the GUI update manager from popping up on first boot
    - curtin in-target -- apt-get remove -y update-notifier update-manager