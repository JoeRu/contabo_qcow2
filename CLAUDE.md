# CLAUDE.md — contabo_qcow2

## Project Overview

Nix flake that builds a minimal, bootable NixOS 25.05 qcow2 image for upload to Contabo VPS via their Custom Images feature. The image is published as a GitHub release asset and downloaded by Contabo via URL.

## Key Files

| File | Purpose |
|---|---|
| `flake.nix` | Entry point — defines `nixosConfigurations.contabo` |
| `flake.lock` | Pinned nixpkgs 25.05 — do not edit manually, use `nix flake update` |
| `modules/contabo.nix` | Contabo-specific config (VirtIO drivers, BIOS boot, cloud-init). **Do not edit.** |
| `modules/user.nix` | User customizations — add packages, users, services here |
| `scripts/release.sh` | Local release helper: build → compress → upload to GitHub |
| `.github/workflows/build.yml` | CI workflow: `workflow_dispatch` → build → compress → GitHub release |

## Build Commands

```bash
# Build the image
nix build .#nixosConfigurations.contabo.config.system.build.image
# Output: result/nixos.qcow2

# Verify flake evaluates correctly
nix eval .#nixosConfigurations.contabo.config.image.format      # "qcow2"
nix eval .#nixosConfigurations.contabo.config.image.efiSupport  # false
nix eval .#nixosConfigurations.contabo.config.image.baseName    # "nixos"

# Compress for upload (Contabo requires internal qcow2 compression)
nix shell nixpkgs#qemu -c qemu-img convert -c -O qcow2 result/nixos.qcow2 nixos.qcow2
```

## Release Commands

```bash
# Local release (requires gh auth login)
./scripts/release.sh v1.0

# CI release — trigger from GitHub Actions UI or:
gh workflow run build.yml --field version=v1.0
```

## Important Constraints

- **Contabo image format:** Must be internally compressed qcow2. Archive formats (`.qcow2.gz`) are not supported.
- **GitHub release limit:** 2 GB per asset — always compress with `qemu-img convert -c` before uploading.
- **Boot:** Contabo uses SeaBIOS (BIOS/MBR). `image.efiSupport = false` is required — do not change this.
- **VirtIO:** `virtio_scsi` and `virtio_net` are required by Contabo's hypervisor. Do not remove them from `contabo.nix`.
- **Cloud-init:** Contabo injects SSH keys at first boot. The Cloud-Init toggle must be enabled in the Contabo portal before reinstalling.

## Customizing the Image

Edit `modules/user.nix` only:

```nix
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    htop
  ];
}
```

Never edit `modules/contabo.nix` — it contains settings required for the image to boot on Contabo.

## Updating nixpkgs

```bash
nix flake update
git add flake.lock
git commit -m "chore: update nixpkgs"
```

## GitHub Secrets Required

| Secret | Purpose |
|---|---|
| `CACHIX_AUTH_TOKEN` | Cachix cache (`qcow2`) authentication for CI builds |
