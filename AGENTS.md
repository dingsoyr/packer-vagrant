# AGENTS.md

## Purpose
This repository builds Ubuntu Vagrant boxes for Hyper-V using Packer.
It is intentionally focused on Hyper-V, not a generic multi-provider workflow.

## Source Of Truth
- `boxes/*.pkrvars.hcl` define per-box build inputs such as ISO, checksum, CPU, memory, and disk size for the Packer build VM.
- `common/templates/vagrantfile.rb` defines the default runtime CPU and memory used when consumers run the built box with Vagrant.
- `build.pkr.hcl` contains the Hyper-V build and packaging flow.
- `publish.pkr.hcl` contains the Vagrant Cloud publish flow.
- `build.ps1` is the preferred entry point for local preflight, validate, build, and optional publish operations.

## Build And Publish Notes
- Build-time CPU and memory in `boxes/*.pkrvars.hcl` are separate from runtime defaults in `common/templates/vagrantfile.rb`.
- Local publish settings are loaded from `.env` using `hcp_client_id`, `hcp_client_secret`, and `vagrant_cloud_user`.
- Box tags are built as `<vagrant_cloud_user>/<box name>`.
- `vagrant_cloud_version` may be passed explicitly; otherwise publish falls back to a timestamp-based version.
- Do not log secrets in clear text.

## Workflow Expectations
- Keep manual `packer` commands working; do not make `build.ps1` the only supported workflow.
- Keep `README.md` in sync when script parameters, workflow, or Packer variables change.
- Preserve the Hyper-V-specific design unless a change explicitly broadens scope.
- Avoid unrelated refactors.

## Change Approval
- Do not modify files when the user is asking for discussion, evaluation, or design input.
- For non-trivial code, script, or documentation changes, propose the intended change first and wait for explicit confirmation before editing files.
- Read-only inspection and validation are fine before approval.

## Validation
- `./build.ps1 -PreflightOnly`
- `./build.ps1 -ValidateOnly`
- `packer validate -var-file ./boxes/ubuntu2404.pkrvars.hcl .`