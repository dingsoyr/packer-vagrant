# Packer, Vagrant and Hyper-V
Had the need to build an Ubuntu vagrant box for Hyper-V. This repo contains some simple scripts to build an Ubuntu Vagrant Box for Hyper-V. You can find the boxes on Vagrant Cloud https://portal.cloud.hashicorp.com/vagrant/discover/sture

## Setup on Windows
- Hyper-V needs to be installed and set up
- Vagrant needs to be installed and set up
- Packer needs to be installed and set up. Download from https://developer.hashicorp.com/packer/install and extract exe file. Add file to PATH.

## Firewall
Packer will need to access localhost on a spesific port to be able to perform cloud setup. An exception in the Hyper-V Default switch will be needed.

Have a look at: https://github.com/marcinbojko/hv-packer or add in elevated Powershell.

```
Remove-NetFirewallRule -DisplayName "Packer_http_server" -Verbose
New-NetFirewallRule -DisplayName "Packer_http_server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort
8000-9000
```

## Vagrant Cloud
To be able to push the box to Vagrant Cloud a "service principal" user have to be added to the Vagrant Cloud account. This service principal will give a `hcp_client_id` og `hcp_client_secret` that can be used when pushing to Vagrant Cloud. The Vagrant Cloud owner or namespace is configured with `vagrant_cloud_user`.

## Repository layout
- `variables.pkr.hcl` contains common variables and plugin definitions
- `build.pkr.hcl` contains the VM build and packaging workflow
- `publish.pkr.hcl` contains the Vagrant Cloud publish workflow
- `boxes/*.pkrvars.hcl` selects which Ubuntu version to build
- `common/scripts` and `common/templates` contain shared provisioning and box assets

## Hyper-V design choices
This repository intentionally builds an Ubuntu Vagrant box for Hyper-V, not a generic multi-provider box.

- Generation 2 is used with dynamic memory disabled and secure boot explicitly turned off for more predictable Ubuntu boots on Hyper-V.
- The guest network is standardized around `eth0`. The build config and guest boot settings are aligned to keep interface naming predictable.
- The guest installs the `linux-azure` kernel track to better match Hyper-V as the target platform.
- The packaged box resets its machine identity before packaging so cloned VMs generate a fresh identity on first boot.
- The included Vagrantfile keeps runtime CPU and memory lower than the build settings on purpose.
- `/vagrant` is disabled by default because shared folder behavior with Hyper-V is not as reliable as on some other Vagrant providers.

## Build box
Run all commands from the repository root.

You can either run the Packer commands manually or use the included PowerShell helper script.

To use the helper script for optional publish, create a local `.env` file first:

```
Copy-Item .env.example .env
```

Then edit `.env` and add your Vagrant Cloud credentials:

```
hcp_client_id=your-vagrant-cloud-client-id
hcp_client_secret=your-vagrant-cloud-client-secret
vagrant_cloud_user=your-vagrant-cloud-user
```

The `.env` file is ignored by git and is only needed if you choose to publish.

Run the helper script:

```
.\build.ps1
```

You can also skip the interactive prompts by providing parameters:

```
.\build.ps1 -Box ubuntu2404 -DeleteCache $true -Publish $true
```

To run only the prerequisite checks without starting a build:

```
.\build.ps1 -PreflightOnly
```

The script will:
- run preflight checks for Packer, Vagrant, Hyper-V, and the `Packer_http_server` firewall rule
- let you choose which box definition to build
- ask whether `packer_cache` should be deleted first to force fresh downloads
- run `packer validate` for the selected box before build
- run the build
- ask whether the completed box should be published to Vagrant Cloud
- print the direct HashiCorp Vagrant Cloud URL after a successful publish

Supported script parameters:
- `-Box ubuntu2404` selects a box definition by name or file name without prompting
- `-DeleteCache $true` or `-DeleteCache $false` answers the cache question without prompting
- `-Publish $true` or `-Publish $false` answers the publish question without prompting
- `-PreflightOnly` runs only the prerequisite checks and exits

To initialize packer and download all plugins run:

```
packer init .
```

Validate the build configuration for a specific box:

```
packer validate -var-file .\boxes\ubuntu2404.pkrvars.hcl .
```

Build the box artifact:

```
packer build --var-file .\boxes\ubuntu2404.pkrvars.hcl --force -only="build.hyperv-iso.efi" .
```

Publish an already-built box to Vagrant Cloud:

```
packer build --var-file .\boxes\ubuntu2404.pkrvars.hcl --var "hcp_client_id=your-vagrant-cloud-client-id" --var "hcp_client_secret=your-vagrant-cloud-client-secret" --var "vagrant_cloud_user=your-vagrant-cloud-user" --force -only="publish.null.core" .
```

The publish workflow generates a timestamp-based Vagrant Cloud version with second-level precision so repeated publishes do not reuse the same version within the same hour.

Optional overrides for the build workflow:

```
packer build --var-file .\boxes\ubuntu2404.pkrvars.hcl --var "switch_name=Default switch" --var "hyperv_configuration_version=11.0" --force -only="build.hyperv-iso.efi" .
```

Available box definitions:

```
.\boxes\ubuntu2204.pkrvars.hcl
.\boxes\ubuntu2404.pkrvars.hcl
```