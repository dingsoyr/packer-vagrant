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

## Build box
To initialize packer and download all plugins run:

```
packer init .\box-config.pkr.hcl
```

The packer template is split into two sections. One to build the box and one to push it to Vagrant Cloud.

```
packer build --var "hcp_client_id=CLIENT_ID" --var "hcp_client_secret=CLIENT_SECRET" --force -only="build.hyperv-iso.efi" .\box-config.pkr.hcl
packer build --var "hcp_client_id=CLIENT_ID" --var "hcp_client_secret=CLIENT_SECRET" --force -only="publish.null.core" .\box-config.pkr.hcl
```