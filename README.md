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
To be able to push the box to Vagrant Cloud a "service principal" user have to be added to the Vagrant Cloud account. This service principal will give a "client_id" og "client_secret" that can be used when pushing to Vagrant Cloud.

## Repository layout
- `variables.pkr.hcl` contains common variables and plugin definitions
- `build.pkr.hcl` contains the VM build and packaging workflow
- `publish.pkr.hcl` contains the Vagrant Cloud publish workflow
- `boxes/*.pkrvars.hcl` selects which Ubuntu version to build
- `common/scripts` and `common/templates` contain shared provisioning and box assets

## Build box
Run all commands from the repository root.

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
packer build --var-file .\boxes\ubuntu2404.pkrvars.hcl --var "hcp_client_id=CLIENT_ID" --var "hcp_client_secret=CLIENT_SECRET" --force -only="publish.null.core" .
```

Optional overrides for the build workflow:

```
packer build --var-file .\boxes\ubuntu2404.pkrvars.hcl --var "switch_name=Default switch" --var "network_interface=eth0" --var "hyperv_configuration_version=11.0" --force -only="build.hyperv-iso.efi" .
```

Available box definitions:

```
.\boxes\ubuntu2204.pkrvars.hcl
.\boxes\ubuntu2404.pkrvars.hcl
```