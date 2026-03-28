# NixOS minimal image qcow2-Format - for use in Contabo and other hyperscalers supporting qcow2 Format

Nix flake that builds a minimal NixOS 25.11 qcow2 image ready to upload to [Contabo](https://contabo.com) via their Custom Images feature.

**!Attention!**
If you didn't setup the password in the UI - the system is delivered with a default account (admin) and Password (look into [modules/user.nix](https://github.com/JoeRu/NixOS-qcow2-Image/blob/master/modules/user.nix))! SET Password or DELETE the User immidiatly! 

## Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
- [gh CLI](https://cli.github.com) authenticated (`gh auth login`) — for releases

Enable flakes if not already:
```
experimental-features = nix-command flakes
```
in `~/.config/nix/nix.conf`.

## Customizing the Image

Add packages, users, or services in `modules/user.nix`:

```nix
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    htop
  ];
}
```

Do not edit `modules/contabo.nix` — it contains settings required for the image to boot on Contabo.

## Building Locally

```bash
nix build .#nixosConfigurations.contabo.config.system.build.image
# Output: result/nixos.qcow2
```

## Releasing

### Via GitHub Actions (CI)

Trigger manually from the Actions tab, or:

```bash
gh workflow run build.yml --field version=v1.0
```

### Via local script

```bash
./scripts/release.sh v1.0
```

Both produce the release asset URL:
```
https://github.com/JoeRu/contabo_qcow2/releases/download/<version>/nixos.qcow2
```

## Uploading to Contabo

1. Log in to the Contabo customer portal
2. Navigate to your VPS → Custom Images (add-on required)
3. **Add your SSH public key** in the portal — cloud-init injects it at first boot
4. Upload via URL: `https://github.com/JoeRu/contabo_qcow2/releases/download/<version>/nixos.qcow2`
5. OS type: **Linux** / version: **NixOS 25.11**
6. Enable the **Cloud-Init toggle**
7. Reinstall the VPS
8. SSH in: `ssh admin@<vps-ip>`

## Managing the Installed System

At first boot the system automatically clones this repository to `/etc/nixos`.
You do **not** need to rebuild and reinstall the image for routine changes.

### Day-to-day changes (non-destructive)

1. Edit `modules/user.nix` locally (packages, users, services, MOTD)
2. Commit and push:
   ```bash
   git add modules/user.nix
   git commit -m "..."
   git push
   ```
3. On the VPS, pull and apply:
   ```bash
   cd /etc/nixos && git pull && nixos-update
   ```
   `nixos-update` is a wrapper for `nixos-rebuild switch --flake /etc/nixos#contabo`.
   It is provided by the system — no need to remember the `--flake` flag.

Builds are fast because the CI populates the cachix binary cache — the VPS pulls pre-built closures instead of compiling.

### When to rebuild and reinstall the image

Rebuild the image (GitHub Actions → new release → Contabo reinstall) only for changes that affect boot or hardware configuration:

- `modules/contabo.nix` (kernel modules, boot loader, disk layout)
- Disk size (`virtualisation.diskSize`)
- Cloud-init network config

**Note:** Reinstalling via Contabo wipes the disk. Back up any data first.

### Fork this repository

If you fork this repo, update the clone URL in `modules/user.nix`:

```nix
systemd.services.setup-nixos-config = {
  ...
  ExecStart = pkgs.writeShellScript "setup-nixos-config" ''
    git clone https://github.com/YOUR_USER/YOUR_REPO.git /etc/nixos
  '';
};
```

## Repository Setup (one-time)

Add `CACHIX_AUTH_TOKEN` as a GitHub repo secret (Settings → Secrets → Actions) using a token from [app.cachix.org](https://app.cachix.org) for the `qcow2` cache.
