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

  # Fallback root password for VNC/console access.
  # Change this after first login: passwd root
  # To remove once SSH key access is confirmed working, delete these two lines.
  users.users.root.initialPassword = "changeme";
}
