# contabo_qcow2

Nix flake that builds a minimal NixOS 25.05 qcow2 image ready to upload to [Contabo](https://contabo.com) via their Custom Images feature.

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
5. OS type: **Linux** / version: **NixOS 25.05**
6. Enable the **Cloud-Init toggle**
7. Reinstall the VPS
8. SSH in: `ssh root@<vps-ip>`

## Repository Setup (one-time)

Add `CACHIX_AUTH_TOKEN` as a GitHub repo secret (Settings → Secrets → Actions) using a token from [app.cachix.org](https://app.cachix.org) for the `qcow2` cache.
