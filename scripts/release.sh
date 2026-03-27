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
  --notes "NixOS 25.11 qcow2 image for Contabo VPS"

echo ""
echo "Done. Contabo upload URL:"
echo "https://github.com/JoeRu/contabo_qcow2/releases/download/${VERSION}/nixos.qcow2"
