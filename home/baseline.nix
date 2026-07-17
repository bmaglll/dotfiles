{ config, pkgs, ... }:

# Home-Manager baseline: shared by EVERY host (desktops + server).
# Desktop-only additions live in ./desktop.nix, which the desktop hosts
# import on top of this file. The server imports this file alone.
{
  home.username = "bmag";
  home.homeDirectory = "/home/bmag";
  home.stateVersion = "25.11";

  home.sessionPath = [ "$HOME/bin" ];

  ###########################################################################################
  # Shared CLI packages
  ###########################################################################################
  home.packages = with pkgs; [
    btop
    fzf
    ripgrep
    fd
    bat
    eza
    jq
    gh
    fastfetch
    claude-code
    opencode
  ];

  ###########################################################################################
  # Bash
  ###########################################################################################
  programs.bash = {
    enable = true;
    initExtra = ''
      source ${../shell/nx.sh}
      PS1='\[\033[01;32m\][\D{%H:%M:%S}]\[\033[00m\] \[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

      # On SSH login, attach to (or create) the "Main" tmux session.
      # No-op for local Hyprland shells since SSH_CONNECTION is unset there.
      if [[ -z "$TMUX" && -n "$SSH_CONNECTION" ]]; then
        exec tmux new-session -A -s Main
      fi
    '';
  };

  ###########################################################################################
  # tmux (amber status bar; desktop overlay overrides with the host-aware version)
  ###########################################################################################
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    shortcut = "space";
    baseIndex = 1;
    extraConfig = ''
      setw -g mouse on
      bind BSpace kill-window
      set -g status-style "bg=#ffbf00,fg=#000000"
      set -g status-right ""
      set -g renumber-windows on
      set -g allow-passthrough on
    '';
  };

  ###########################################################################################
  # Yazi (file manager)
  ###########################################################################################
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    shellWrapperName = "yy";
    plugins = {
      smart-enter = pkgs.writeTextFile {
        name = "smart-enter";
        destination = "/main.lua";
        text = ''
          --- @sync entry
          return {
            entry = function(state)
              local h = cx.active.current.hovered
              if h and h.cha.is_dir then
                ya.emit("enter", {})
              else
                ya.emit("open", {})
              end
            end,
          }
        '';
      };
    };
    keymap = {
      mgr.prepend_keymap = [
        { on = ["<Enter>"]; run = "plugin smart-enter"; desc = "Enter directory or open file"; }
      ];
    };
    settings = {
      mgr = {
        sort_by = "mtime";
        sort_reverse = true;
        show_hidden = true;
        ratio = [2 4 3];
        linemode = "mtime";
      };
    };
  };

  ###########################################################################################
  # neovim
  ###########################################################################################
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    withRuby = false;
    withPython3 = false;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [ ];
    # IMPORTANT: stop using extraConfig once you're using init.lua
    extraConfig = "";
  };
  xdg.configFile."nvim".source = ../nvim;

  programs.home-manager.enable = true;
}
