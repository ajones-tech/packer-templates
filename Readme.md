# Packer: Automated Golden Image Provisioning

This repository contains the Packer build configurations and automated answer files used to generate the baseline machine images for my infrastructure environment. 

Packer perfectly complements orchestration workflows. I adopted it when I hit the limitations of manual image management: while downstream tools can provision infrastructure at scale, they cannot natively create the base OS images—complete with pre-configured SSH keys, network settings, and essential software—required for a true zero-touch deployment.

## Key Benefits
* **Idempotency:** Packer enforces a defined, reproducible state for machine images, ensuring that components not intended to change remain consistent across every deployment.
* **Scalability:** By leveraging providers like Proxmox, AWS, Azure, and Hyper-V, I can use a single baseline image configuration to deploy across multiple, heterogeneous platforms.
* **CI/CD Integration:** Enables a true "disposable infrastructure" model; allowing for the destruction and recreation of machine environments within a single automated pipeline run without manual intervention.

## Repository Structure
Configurations are separated by operating system to maintain a clean, modular image factory. Unattended installation files (`preseed.cfg`, `autounattend.xml`, `cloud-init`) are nested within their respective builds to ensure agnostic deployments.

```text
.
├── kali/
├── ubuntu_desktop/
├── ubuntu_server/
├── win11/
└── winserver_2k19/
```

## Updates & Roadmap
I am currently refining my baseline templates to ensure they are lean, secure, and ready for automated deployment across my bare-metal Proxmox environment running on my local hardware.

* **Future Implementations:** Golden templates will be used to provision baseline machines across various platforms, as well as to "perfect" my current templates for maximum deployment efficiency.
* **Ongoing Task:** Ironing out the kinks in `preseed.cfg` (Debian) and `autounattended.xml` (Windows) to ensure fully unattended, zero-touch installations without manual prompts.
* **Upcoming Milestone:** Expanding this image factory to support my preparation for the Microsoft AZ-104 and HashiCorp Terraform certifications.

## Skills Displayed
1. **Golden Image Creation:** HashiCorp Packer, State Management, Idempotency.
2. **Zero-Touch Provisioning:** Unattended OS configuration (`preseed.cfg`, `autounattend.xml`, `cloud-init`).
3. **Configuration Management:** CI/CD Methodologies, automated baseline deployments.
4. **Virtualization:** Integrating build pipelines directly with Proxmox VE.