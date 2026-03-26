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
├── modules/contabo.nix              # MODIFIED: add image.compress = true
├── .github/
│   └── workflows/
│       └── build.yml                # NEW: workflow_dispatch CI
└── scripts/
    └── release.sh                   # NEW: local manual release script
```

---

## Required Change: `modules/contabo.nix`

Add to the Image Format section:

```nix
image.compress = true;   # reduces ~2.1 GB to ~400–700 MB for GitHub upload
```

This is required: GitHub release assets have a 2 GB hard limit. The uncompressed image is 2.1 GB.

---

## CI Path: `.github/workflows/build.yml`

**Trigger:** `workflow_dispatch` with one input:
- `version` (string, required) — e.g. `v1.0`

**Steps:**
1. `actions/checkout` — check out the repo
2. `cachix/install-nix-action` — install Nix with flakes enabled
3. `cachix/cachix-action` — authenticate with cachix using `CACHIX_AUTH_TOKEN` secret; push build outputs to cache for faster future runs
4. `nix build .#nixosConfigurations.contabo.config.system.build.image` — build the qcow2
5. `gh release create ${{ inputs.version }} result/nixos.qcow2` — create GitHub release and upload artifact

**Secrets required:**
- `CACHIX_AUTH_TOKEN` — added manually in GitHub repo Settings → Secrets
- `GITHUB_TOKEN` — built-in, no setup needed (used by `gh` CLI for release creation)

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
gh release create "$VERSION" result/nixos.qcow2 \
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
4. Add `CACHIX_AUTH_TOKEN` as a GitHub repo secret (Settings → Secrets and variables → Actions)
5. Add cachix cache name to `build.yml`

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
