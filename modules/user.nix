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


  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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

environment.systemPackages = with pkgs; [
    wget htop curl zsh git docker nmap sshpass lsof unzip openssl
    dateutils bc mutt gnupg gh dig pciutils jq tmux
    docker-compose docker-buildx nano vim

    # Wrapper so users never need to remember the --flake flag.
    # Usage: nixos-update
    # To apply changes: cd /etc/nixos && git pull && nixos-update
    (pkgs.writeShellScriptBin "nixos-update" ''
      export NIX_CONFIG="experimental-features = nix-command flakes"
      exec nixos-rebuild switch --flake /etc/nixos#contabo "$@"
    '')
  ];

  # --- Welcome message (shown on SSH and console login) ---
  # Edit this block to change the message. After editing:
  #   cd /etc/nixos && git pull && nixos-update
  users.motd = ''

    === NixOS on Contabo VPS ===

    System management: see /etc/nixos/README.md
      (auto-cloned from GitHub on first boot)

    Apply config changes:
      cd /etc/nixos && git pull && nixos-update

    ACTION REQUIRED on first login:
      Change the admin password:   passwd
      Or remove the user:
        Edit /etc/nixos/modules/user.nix -> delete users.users.admin
        Then: nixos-update

    To edit this message: /etc/nixos/modules/user.nix -> users.motd

  '';

  # --- First-boot: clone the NixOS config repo to /etc/nixos ---
  # Runs once after cloud-init has configured the network.
  # Change the URL below if you fork this repository.
  systemd.services.setup-nixos-config = {
    description = "Clone NixOS flake config to /etc/nixos on first boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "cloud-init.service" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/etc/nixos/flake.nix";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "setup-nixos-config" ''
        ${pkgs.git}/bin/git clone https://github.com/JoeRu/contabo_qcow2.git /etc/nixos
        echo "NixOS config cloned to /etc/nixos"
      '';
    };
  };

  # --- Per-user .zshrc skeleton ---
  # Created on first activation; never overwritten so users can edit freely.
  # System-wide zsh settings (oh-my-zsh, prompt) live in /etc/zshrc.
  system.activationScripts.zshrcSkeleton = {
    deps = [];
    text = ''
      for home in /home/admin /root; do
        if [ ! -f "$home/.zshrc" ]; then
          mkdir -p "$home"
          cat > "$home/.zshrc" << 'ZSHRC'
# ~/.zshrc — per-user zsh config
# This file is yours to edit. It will not be overwritten by nixos-update.
# System-wide settings (oh-my-zsh, prompt, packages) are in /etc/zshrc.
ZSHRC
          chown --reference="$home" "$home/.zshrc" 2>/dev/null || true
        fi
      done
    '';
  };

  # Default user — cloud-init targets this account for password/SSH key injection.
  # "admin" matches Contabo's expected default_user name.
  # Fallback password is for VNC access only — cloud-init overrides at first boot.
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "XchangeMe!";
  };
}
