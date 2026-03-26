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
    └── contabo.nix     # NixOS configuration module
```

The single flake output is `nixosConfigurations.contabo`. The image is produced by building:

```
.#nixosConfigurations.contabo.config.system.build.qcow2
```

---

## NixOS Configuration (`modules/contabo.nix`)

### Bootloader
- GRUB legacy (MBR/BIOS) — Contabo VPS uses SeaBIOS

### VirtIO Drivers (required by Contabo)
- `boot.initrd.availableKernelModules`: `virtio_scsi`, `virtio_net`, `virtio_pci`, `virtio_blk`

### Disk Layout
- Single root partition, ext4
- No swap (can be added post-deploy)
- `diskSize`: 8 GB (qcow2 sparse; grows on VPS disk)

### Networking
- `networking.useDHCP = true` — picks up DHCP from Contabo's hypervisor via the VirtIO NIC

### SSH
- `services.openssh.enable = true`
- `PermitRootLogin = "yes"` (bare minimal image; harden post-deploy)

### Cloud-Init
- `services.cloud-init.enable = true`
- Allows Contabo portal to inject SSH keys and hostname at first boot

---

## Build Process

**Prerequisites:**
- Nix with flakes enabled (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`)

**Build command:**
```bash
nix build .#nixosConfigurations.contabo.config.system.build.qcow2
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

- Cloud-init injects SSH keys from Contabo portal into `/root/.ssh/authorized_keys`
- SSH in as root
- Run `nixos-rebuild switch --flake .#contabo` to apply further configuration changes

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

## Out of Scope

- CI/CD automated builds (can be added later)
- Non-root user setup / hardening (post-deploy concern)
- Additional services baked into the image
