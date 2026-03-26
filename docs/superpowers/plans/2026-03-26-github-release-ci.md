# GitHub Release CI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the NixOS qcow2 image as a GitHub release asset (public URL) via a `workflow_dispatch` CI pipeline and a local release script, using cachix for build caching.

**Architecture:** The local repo is pushed to `git@github.com:JoeRu/contabo_qcow2.git`. A `workflow_dispatch` GitHub Actions workflow builds the image with Nix, compresses it internally with `qemu-img convert -c`, and uploads it as a release asset. A companion shell script does the same locally. Both produce the URL `https://github.com/JoeRu/contabo_qcow2/releases/download/<version>/nixos.qcow2`.

**Tech Stack:** GitHub Actions, cachix (`qcow2` cache), Nix flakes, `qemu-img`, `gh` CLI, bash.

---

## Prerequisites

- `gh auth login` — already done
- SSH key for `git@github.com` must be configured (test: `ssh -T git@github.com`)
- Cachix `CACHIX_AUTH_TOKEN` must be added as a GitHub repo secret before the CI workflow will succeed

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `.github/workflows/build.yml` | Create | `workflow_dispatch` CI: build → compress → release |
| `scripts/release.sh` | Create | Local equivalent: build → compress → release |
| `.gitignore` | Modify | Add `nixos.qcow2` (compressed artifact generated locally) |

No changes to `flake.nix`, `modules/contabo.nix`, or `modules/user.nix`.

---

## Task 1: Add git remote and push to GitHub

**Files:** none (git operations only)

- [ ] **Step 1: Verify SSH access to GitHub**

```bash
ssh -T git@github.com
```

Expected: `Hi JoeRu! You've successfully authenticated...`

If this fails, add your SSH key to GitHub before continuing.

- [ ] **Step 2: Add remote**

```bash
git remote add origin git@github.com:JoeRu/contabo_qcow2.git
```

- [ ] **Step 3: Push**

```bash
git push -u origin master
```

Expected: all commits pushed, branch `master` tracking `origin/master`.

---

## Task 2: Create `scripts/release.sh`

**Files:**
- Create: `scripts/release.sh`
- Modify: `.gitignore`

- [ ] **Step 1: Create the scripts directory and release script**

```bash
mkdir -p scripts
```

```bash
#!/usr/bin/env bash
# scripts/release.sh
# Build the NixOS qcow2 image locally, compress it, and publish as a GitHub release.
# Usage: ./scripts/release.sh <version>   e.g. ./scripts/release.sh v1.0
set -euo pipefail

VERSION=${1:?Usage: ./scripts/release.sh <version>  e.g. v1.0}

echo "==> Building NixOS image..."
nix build .#nixosConfigurations.contabo.config.system.build.image

echo "==> Compressing image (internal qcow2 compression)..."
nix shell nixpkgs#qemu -c qemu-img convert -c -O qcow2 result/nixos.qcow2 nixos.qcow2

echo "==> Creating GitHub release ${VERSION}..."
gh release create "${VERSION}" nixos.qcow2 \
  --title "NixOS ${VERSION}" \
  --notes "NixOS 25.05 qcow2 image for Contabo VPS"

echo ""
echo "Done. Contabo upload URL:"
echo "https://github.com/JoeRu/contabo_qcow2/releases/download/${VERSION}/nixos.qcow2"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/release.sh
```

- [ ] **Step 3: Verify it exits cleanly when called without arguments**

```bash
./scripts/release.sh 2>&1 || true
```

Expected output contains: `Usage: ./scripts/release.sh <version>`

- [ ] **Step 4: Add `nixos.qcow2` to `.gitignore`**

```bash
echo "nixos.qcow2" >> .gitignore
```

- [ ] **Step 5: Commit**

```bash
git add scripts/release.sh .gitignore
git commit -m "feat: add local release script"
```

---

## Task 3: Create `.github/workflows/build.yml`

**Files:**
- Create: `.github/workflows/build.yml`

- [ ] **Step 1: Create the workflow file**

```bash
mkdir -p .github/workflows
```

```yaml
# .github/workflows/build.yml
name: Build and Release NixOS qcow2

on:
  workflow_dispatch:
    inputs:
      version:
        description: "Release version (e.g. v1.0)"
        required: true
        type: string

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v27
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Setup cachix
        uses: cachix/cachix-action@v15
        with:
          name: qcow2
          authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}

      - name: Build image
        run: nix build .#nixosConfigurations.contabo.config.system.build.image

      - name: Compress image (internal qcow2 compression)
        run: nix shell nixpkgs#qemu -c qemu-img convert -c -O qcow2 result/nixos.qcow2 nixos.qcow2

      - name: Create GitHub release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release create "${{ inputs.version }}" nixos.qcow2 \
            --title "NixOS ${{ inputs.version }}" \
            --notes "NixOS 25.05 qcow2 image for Contabo VPS"
          echo "Contabo upload URL:"
          echo "https://github.com/JoeRu/contabo_qcow2/releases/download/${{ inputs.version }}/nixos.qcow2"
```

- [ ] **Step 2: Validate YAML syntax**

```bash
nix shell nixpkgs#yq -c yq e . .github/workflows/build.yml > /dev/null && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build.yml
git commit -m "feat: add workflow_dispatch CI for qcow2 release"
```

---

## Task 4: Push and verify on GitHub

**Files:** none (git + GitHub operations)

- [ ] **Step 1: Push all new commits**

```bash
git push
```

Expected: `scripts/release.sh` and `.github/workflows/build.yml` appear on GitHub.

- [ ] **Step 2: Verify workflow appears in GitHub Actions UI**

```bash
gh workflow list
```

Expected output includes:
```
Build and Release NixOS qcow2   active   build.yml
```

- [ ] **Step 3: Create the cachix cache (if not already done)**

1. Go to https://app.cachix.org and sign in
2. Create a new cache named `qcow2` (must match the name hardcoded in `build.yml`)
3. Go to the cache settings → Auth tokens → create a new token
4. Copy the token — you'll use it in the next step

- [ ] **Step 4: Add `CACHIX_AUTH_TOKEN` secret to the repo**

```bash
gh secret set CACHIX_AUTH_TOKEN
```

Paste your cachix auth token when prompted.

Expected: `✓ Set secret CACHIX_AUTH_TOKEN`

---

## Task 5: Trigger a test release

- [ ] **Step 1: Trigger the workflow with a test version**

```bash
gh workflow run build.yml --field version=v1.0
```

Expected: `✓ Created workflow dispatch event for build.yml at master`

- [ ] **Step 2: Monitor the run**

```bash
gh run list --workflow=build.yml
```

Wait for status to change from `in_progress` to `completed`. Watch logs:

```bash
gh run watch
```

Expected final status: `✓ completed`

- [ ] **Step 3: Verify the release and URL**

```bash
gh release view v1.0
```

Expected: release exists with `nixos.qcow2` asset attached.

```bash
echo "Contabo URL: https://github.com/JoeRu/contabo_qcow2/releases/download/v1.0/nixos.qcow2"
```

Paste this URL into Contabo's custom image upload field.

---

## Contabo Upload Reference

After any release (CI or local), the URL format is:
```
https://github.com/JoeRu/contabo_qcow2/releases/download/<version>/nixos.qcow2
```
