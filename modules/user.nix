# modules/user.nix
# Add your custom packages, users, and services here.
# This file is safe to edit — it will not interfere with Contabo requirements.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Add packages here, e.g.:
    # git
    # htop
    # vim
  ];
}
