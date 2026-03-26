# flake.nix
{
  description = "NixOS qcow2 image for Contabo VPS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.contabo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/virtualisation/disk-image.nix"
        ./modules/contabo.nix
        ./modules/user.nix
      ];
    };
  };
}
