{ pkgs, ... }: {
  home.username = "alunity";
  home.homeDirectory = "/home/alunity";
  home.stateVersion = "24.11"; # Match your system stateVersion

  programs.home-manager.enable = true;

  # Install user-specific apps
  home.packages = with pkgs; [
    google-chrome
    ghostty
    mpv
    git
    neovim
    tmux
    nerd-fonts.caskaydia-cove
    fish
    fastfetch
  ];


  home.sessionVariables = {
    EDITOR = "nvim";
    MOODLE_TOKEN = "REMOVED_SECRET";
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "ls -l";
      ".." = "cd ..";
      update = "home-manager switch";
      v = "nvim";
    };
  };

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true; # This handles the "correct path" magic
    
    settings = {
      # Use the Nix-aware path for fish
      command = "${pkgs.fish}/bin/fish --login --interactive";
      
      font-family = "CaskaydiaCove Nerd Font";
      font-size = 12;

      theme = "Catppuccin Mocha";
      
      shell-integration-features = "ssh-env";
      
      # Keybinds
      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
      ];

      # Window tweeks
      confirm-close-surface = false;
    };
  };

  programs.fish = {
    enable = true;
    
    # Standard Aliases
    shellAliases = {
      ls = "ls -l";
      v = "nvim";
    };

    # Nix-Specific Abbreviations (they expand as you type!)
    shellAbbrs = {
      # System Management
      ".." = "cd ..";
      nrs = "sudo nixos-rebuild switch --flake .#nixy";
      hms = "nix run home-manager -- switch --flake .#nixy";
      
      # Cleanup & Maintenance
      ngc = "nix-collect-garbage -d"; # Delete old generations to free space
      nopt = "nix-store --optimise"; # Hard-link duplicate files to save space
      
      # Searching & Running
      ns = "nix search nixpkgs";
      nr = "nix run nixpkgs#"; # Usage: nr hello
      
      # Inspection
      nconf = "nvim /etc/nixos/configuration.nix";
      hconf = "nvim ~/.config/home-manager/home.nix";
    };

    interactiveShellInit = ''
        set -g fish_greeting ""
        # Enable Vim mode
        fish_vi_key_bindings

        # Optional: Set the cursor shapes for different modes
        set fish_cursor_default block
        set fish_cursor_insert line
        set fish_cursor_replace_one underscore
        set fish_cursor_visual block
      '';
  };


  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "alunity";
        email = "75143943+alunity@users.noreply.github.com";
      };
      init.defaultBranch = "main";
    };

    signing.format = null;
  };

  programs.tmux = {
    enable = true;

    shell = "${pkgs.fish}/bin/fish";
    
    # --- Basic Settings ---
    shortcut = "a";          # Replaces unbind C-b and set-option -g prefix C-a
    baseIndex = 1;           # set -g base-index 1
    mouse = true;            # setw -g mouse on
    keyMode = "vi";          # set-window-option -g mode-keys vi
    escapeTime = 0;          # set -s escape-time 0
    terminal = "screen-256color"; # set-option -g default-terminal

    # --- Extra Configuration (Bindings and UI) ---
    extraConfig = ''
      # Terminal Overrides/Features
      set -ga terminal-overrides ",screen-256color*:Tc"
      set-option -a terminal-features 'xterm-256color:RGB'
      set-option -g focus-events on

      # Status Style
      set -g status-style 'bg=#333333 fg=#c3b1e1'

      # Custom Bindings
      bind r source-file ~/.config/tmux/tmux.conf
      bind c new-window -c "#{pane_current_path}"

      # Copy Mode (Vi style)
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel '${pkgs.xclip}/bin/xclip -in -selection clipboard'

      # Vim-like pane switching
      bind -r ^ last-window
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R
    '';
  };

  home.file = {
  };

  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      # Optional but highly recommended for Vi users:
      keymap = "vi";
      show-all-if-ambiguous = true;
    };
    # If you have extra raw lines you want to add:
    extraConfig = ''
      set completion-ignore-case on
    '';
  };


  fonts.fontconfig.enable = true;
}
