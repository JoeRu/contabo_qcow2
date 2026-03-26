# GitHub Release & CI for NixOS Contabo qcow2 — Design Spec

**Date:** 2026-03-26
**Status:** Approved

---

## Goal

Publish the NixOS qcow2 image as a GitHub release asset with a public URL suitable for Contabo's custom image upload, via both a GitHub Actions CI workflow (triggered manually) and a local release script.

---

## Repository

`git@github.com:JoeRu/contabo_qcow2.git`

---

## Components

```
├── modules/contabo.nix              # unchanged (no compress option needed)
├── .github/
│   └── workflows/
│       └── build.yml                # NEW: workflow_dispatch CI
└── scripts/
    └── release.sh                   # NEW: local manual release script
```

---

## Image Compression

**Contabo constraint:** Contabo supports internal qcow2 compression only. External archive formats (`.qcow2.gz`, `.qcow2.zst`) are explicitly not supported.

**NixOS constraint:** `disk-image.nix` in NixOS 25.05 does not expose an `image.compress` option.

**Solution:** After `nix build`, run `qemu-img convert -c -O qcow2` to produce an internally compressed copy:

```bash
qemu-img convert -c -O qcow2 result/nixos.qcow2 nixos.qcow2
```

This is the only format Contabo accepts that also fits under GitHub's 2 GB release asset limit (~400–700 MB compressed vs 2.1 GB uncompressed).

Both the CI workflow and local script perform this conversion step before uploading.

---

## CI Path: `.github/workflows/build.yml`

**Trigger:** `workflow_dispatch` with one input:
- `version` (string, required) — e.g. `v1.0`

**Steps:**
1. `actions/checkout` — check out the repo
2. `cachix/install-nix-action` — install Nix with flakes enabled (flakes on by default in recent versions)
3. `cachix/cachix-action` with `name: qcow2` and `authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}` — authenticate and push build outputs to cache
4. `nix build .#nixosConfigurations.contabo.config.system.build.image` — build the uncompressed qcow2
5. `nix shell nixpkgs#qemu -c qemu-img convert -c -O qcow2 result/nixos.qcow2 nixos.qcow2` — produce internally compressed qcow2
6. `gh release create ${{ inputs.version }} nixos.qcow2 --title "NixOS ${{ inputs.version }}" --notes "NixOS 25.05 qcow2 for Contabo"`

**Environment on step 6:**
```yaml
env:
  GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Secrets required:**
- `CACHIX_AUTH_TOKEN` — added manually in GitHub repo Settings → Secrets
- `CACHIX_CACHE_NAME` — the name of your cachix cache (or hardcoded in `build.yml`)
- `GITHUB_TOKEN` — built-in, no setup needed

**Output URL format:**
```
https://github.com/JoeRu/contabo_qcow2/releases/download/<version>/nixos.qcow2
```

---

## Local Path: `scripts/release.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
VERSION=${1:?Usage: ./scripts/release.sh <version>}
nix build .#nixosConfigurations.contabo.config.system.build.image
nix shell nixpkgs#qemu -c qemu-img convert -c -O qcow2 result/nixos.qcow2 nixos.qcow2
gh release create "$VERSION" nixos.qcow2 \
  --title "NixOS $VERSION" \
  --notes "NixOS 25.05 qcow2 for Contabo"
echo "Upload complete. URL:"
echo "https://github.com/JoeRu/contabo_qcow2/releases/download/${VERSION}/nixos.qcow2"
```

**Prerequisites:** `gh auth login` (already done).

---

## One-Time Setup Steps

1. Add GitHub remote: `git remote add origin git@github.com:JoeRu/contabo_qcow2.git`
2. Push: `git push -u origin master`
3. Create a cachix cache at cachix.org, obtain auth token
4. Add the following GitHub repo secrets (Settings → Secrets and variables → Actions):
   - `CACHIX_AUTH_TOKEN` — cachix authentication token
   - Optionally `CACHIX_CACHE_NAME` — or hardcode cache name directly in `build.yml`

---

## Release URL for Contabo

After a release is created (via CI or local script), provide this URL to Contabo's custom image upload:

```
https://github.com/JoeRu/contabo_qcow2/releases/download/<version>/nixos.qcow2
```

---

## Out of Scope

- Automatic tag-based or push-based triggers (workflow_dispatch only)
- Signed/verified releases
- Multi-architecture builds
