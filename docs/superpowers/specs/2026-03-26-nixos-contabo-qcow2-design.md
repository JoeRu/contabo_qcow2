# NixOS Contabo qcow2 Image — Design Spec

**Date:** 2026-03-26
**Status:** Approved

---

## Goal

Build a minimal, bootable NixOS 25.05 qcow2 image suitable for upload to Contabo's Custom Images feature, using a single `flake.nix` that produces a reproducible image via `nix build`.

---

## Repository Structure

```
/root/contabo_qcow2/
├── flake.nix           # entry point — nixosConfigurations.contabo
├── flake.lock          # pinned nixpkgs 25.05
└── modules/
    ├── contabo.nix     # Contabo-specific NixOS configuration (do not edit)
    └── user.nix        # user customizations: packages, accounts, extra services
```

The single flake output is `nixosConfigurations.contabo`. The image is produced by building:

```
.#nixosConfigurations.contabo.config.system.build.image
```

`flake.nix` imports `"${nixpkgs}/nixos/modules/virtualisation/disk-image.nix"` via the NixOS module system so that `system.build.image` is available as an output.

---

## NixOS Configuration (`modules/contabo.nix`)

### Image Format
- `image.format = "qcow2"` (default for `disk-image.nix`, stated explicitly for clarity)
- `image.efiSupport = false` — **required**; Contabo VPS uses SeaBIOS (BIOS/MBR), not UEFI. Without this, the image builder defaults to EFI + GPT, which will not boot on Contabo.
- Setting `image.efiSupport = false` causes the builder to install GRUB in MBR mode automatically (`boot.loader.grub.devices = [ "/dev/vda" ]`).
- `image.baseName = "nixos"` — sets a fixed output filename (`nixos.qcow2`) rather than the default versioned name (e.g. `nixos-image-qcow2-25.05.XXXXXXX-x86_64-linux.qcow2`).

### VirtIO Drivers (required by Contabo)
- `boot.initrd.availableKernelModules`: `virtio_scsi`, `virtio_net`, `virtio_pci`, `virtio_blk`

### Disk Layout
- Single root partition, ext4
- No swap (can be added post-deploy)
- `virtualisation.diskSize = 8192` (8 GB in MiB — qcow2 is sparse; actual VPS disk is larger)

### Networking
- `networking.useDHCP = true` — VirtIO NIC picks up DHCP from Contabo's hypervisor
- `services.cloud-init.network.enable = false` — disables cloud-init network management to avoid conflict with dhcpcd

### SSH
- `services.openssh.enable = true`
- `services.openssh.settings.PermitRootLogin = "yes"` (bare minimal image; harden post-deploy)

### Cloud-Init
- `services.cloud-init.enable = true`
- `services.cloud-init.network.enable = false` (see Networking above)
- Allows Contabo portal to inject SSH keys and hostname at first boot

---

## Build Process

**Prerequisites:**
- Nix with flakes enabled (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`)

**Build command:**
```bash
nix build .#nixosConfigurations.contabo.config.system.build.image
# Output: ./result/nixos.qcow2
```

---

## Upload & Deploy to Contabo

1. Ensure the "Custom Images" add-on is active on the VPS in the Contabo customer portal
2. Upload `result/nixos.qcow2` via the portal (direct upload or URL-based)
3. Set OS type: **Linux**, version: **NixOS 25.05**
4. Enable the **Cloud-Init toggle** in the portal
5. Reinstall the VPS with the custom image

---

## First Boot

- Cloud-init injects SSH keys (configured in the Contabo portal) into `/root/.ssh/authorized_keys`
- SSH in as root: `ssh root@<vps-ip>`
- The image is now fully operational. Further NixOS configuration (e.g. `nixos-rebuild switch`) requires copying the flake to the VPS first (`git clone` or `scp`). This is a post-deploy concern and out of scope for the initial image build.

---

## Contabo Technical Requirements (Reference)

| Requirement | Value |
|---|---|
| Architecture | x86-64 (amd64) |
| Disk driver | `virtio_scsi` |
| Network driver | `virtio_net` |
| Image format | QCOW2 (internal compression ok; `.qcow2.gz` archives not supported) |
| Windows | Not permitted |

---

## User Customization (`modules/user.nix`)

A separate module imported alongside `contabo.nix` in `flake.nix`. Ships empty by default. Users edit only this file — `contabo.nix` is never touched.

Intended for:
- `environment.systemPackages` — extra packages to bake into the image
- `users.users` — additional user accounts
- Any extra NixOS options or services beyond the minimal base

Example content:
```nix
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    htop
  ];
}
```

---

## Out of Scope

- CI/CD automated builds (can be added later)
- Non-root user setup / hardening (post-deploy concern)
- Copying the flake to the VPS for post-deploy `nixos-rebuild`
