# modules/user.nix
# Add your custom packages, users, and services here.
# This file is safe to edit — it will not interfere with Contabo requirements.
{ pkgs, ... }: {

# Default Packages and settings
programs.tmux.enable = true;

  # Select internationalisation properties.
   i18n.defaultLocale = "de_DE.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };
   i18n.extraLocaleSettings = {
     LC_MESSAGES = "en_US.UTF-8";
     LC_TIME = "de_DE.UTF-8";
   };


  nix.settings.auto-optimise-store = true;
  # Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

users.defaultUserShell = pkgs.zsh; # Make zsh default shell

 programs.zsh.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" "sudo" "docker" ];
  };

environment.systemPackages = with pkgs; [ wget htop wget curl zsh git docker nmap sshpass lsof unzip openssl dateutils bc mutt gnupg gh unzip dig pciutils jq tmux docker-compose docker-buildx nano vim ];

  # Fallback user for VNC/console access.
  users.users.mynixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Cloud-init overrides this at first boot with the password set in the Contabo portal.
    # This is a fallback for VNC access only — change it after first login.
    initialPassword = "XchangeMe!";
  };
}
