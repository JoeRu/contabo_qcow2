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

  # Custom prompt prefix — applied for all users via /etc/zshrc, after oh-my-zsh loads.
  # $fg[cyan]/$fg[blue] are provided by oh-my-zsh's color module.
  programs.zsh.interactiveShellInit = ''
    PROMPT="$fg[cyan]%}$USER@%{$fg[blue]%}%m ''${PROMPT}"
  '';

environment.systemPackages = with pkgs; [ wget htop wget curl zsh git docker nmap sshpass lsof unzip openssl dateutils bc mutt gnupg gh unzip dig pciutils jq tmux docker-compose docker-buildx nano vim ];

  # --- Welcome message (shown on SSH and console login) ---
  # Edit this block to change the message shown at login.
  # After editing: rebuild and redeploy a new image version.
  users.motd = ''

    === NixOS on Contabo VPS ===

    ACTION REQUIRED on first login:
      Change the mynixos password:   passwd
      Or remove the user entirely:
        1. Edit modules/user.nix in your local repo
        2. Delete the users.users.mynixos block
        3. Rebuild and redeploy the image

    To edit this message:
      modules/user.nix -> users.motd

  '';

  # Fallback user for VNC/console access.
  users.users.mynixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Cloud-init overrides this at first boot with the password set in the Contabo portal.
    # This is a fallback for VNC access only — change it after first login.
    initialPassword = "XchangeMe!";
  };
}
