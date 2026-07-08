#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  identity:
    hostname: ubuntu-tmpl
    username: sysadmin
    password: "$6$gAz3aFy6hOguvcx/$/ll2siSThqUb6nzWrQ6rGap/kPGfpiRZ5wtIlPW7zxqgNlGQUh14KBfYfCpmEkAdt8i44ETrojsV1cTpFvdG4."
  ssh:
    install-server: true
    allow-pw: true
    disable_root: true
    allow_public_ssh_keys: true
  packages:
    - openssh-server
    - cloud-init
    - qemu-guest-agent
  user-data:
    timezone: America/Chicago
    users:
      - name: sysadmin
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - "${ansible_public_key}"
  late-commands:
    - curtin in-target -- systemctl enable qemu-guest-agent