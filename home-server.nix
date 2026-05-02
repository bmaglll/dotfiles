{ config, pkgs, ... }:

{
  home.username = "bmag";
  home.homeDirectory = "/home/bmag";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    btop
    fzf
    ripgrep
    fd
    bat
    eza
    jq
    gh
    wl-clipboard
    fastfetch
    claude-code
  ];

  home.sessionPath = [ "$HOME/bin" ];

  programs.bash = {
    enable = true;
    initExtra = ''
      PS1='\[\033[01;32m\][\D{%H:%M:%S}]\[\033[00m\] \[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    '';
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    shortcut = "space";
    baseIndex = 1;
    extraConfig = ''
      setw -g mouse on
      bind BSpace kill-window
      set -g status-style "bg=#b388ff,fg=#000000"
      set -g status-right ""
      set -g renumber-windows on
      set -g allow-passthrough on
    '';
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
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

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = "";
  };
  xdg.configFile."nvim".source = ./nvim;

  programs.home-manager.enable = true;
}
