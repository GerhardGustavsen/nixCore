{ system, nixpkgs, home-manager, pkgs, ... }: {

  # ------------------------------------------------------------------------------------------
  # ----------------------------------------- SETTINGS ---------------------------------------
  # ------------------------------------------------------------------------------------------

  home.stateVersion = "24.11";

  # ENV varriables
  home.sessionVariables = {
    GIT_EDITOR = "vim";
    EDITOR = "vim";
    BROWSER = "firefox";
    XCURSOR_THEME = "phinger-cursors-light";
  };

  # Custom directories
  xdg.userDirs = {
    enable = true;
    download = "$HOME/downloads";
    pictures = "$HOME/media/img";
    videos = "$HOME/media/vid";
    music = "$HOME/media/music";
    documents = "$HOME/workspaces";
    desktop = "$HOME/workspaces";
    templates = "$HOME/.xdgdirs/templates";
  };

  # ------------------------------------------------------------------------------------------
  # ----------------------------------------- SERVICES ---------------------------------------
  # ------------------------------------------------------------------------------------------

  # Battery notify
  #systemd.user.services.battery-warn = {
  #  Unit = { Description = "Battery warning via dunst"; };
  #  Service = {
  #    ExecStart = "%h/scripts/battery-warn.sh";
  #    Restart = "always";
  #    Group = "users";
  #    RestartSec = 10;
  #  };
  #  Install = { WantedBy = [ "default.target" ]; };
  #};

  # Autoconnect monitors and microcontollers
  systemd.user.services.new-device = {
    Unit = {
      Description = "autoconnect monitors and microcontollers";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/nixCore/scripts/hardware-connect.sh";
      Restart = "on-failure";
      RestartSec = 10;
      Environment = "PATH=/run/current-system/sw/bin";
      Group = "users";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # ------------------------------------------------------------------------------------------
  # ----------------------------------------- RICE -------------------------------------------
  # ------------------------------------------------------------------------------------------

  home.pointerCursor = {
    name = "phinger-cursors-light";
    package = pkgs.phinger-cursors;
    size = 32;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # ------------------------------------------------------------------------------------------
  # ----------------------------------------- USER PROGRAMS ----------------------------------
  # ------------------------------------------------------------------------------------------

  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [

    # Big programs:
    slack
    spotify
    steam
    kicad-small
    discord

    # Editors:
    vscode
    libreoffice

    # Rice:
    unclutter
    neofetch
    xwallpaper
    papirus-icon-theme
  ];

  # ------------------------------------------------------------------------------------------
  # ----------------------------------------- GIT --------------------------------------------
  # ------------------------------------------------------------------------------------------

  programs.git = {
    enable = true;
    userName = "Gerhard Gustavsen";
    userEmail = "gerhard.gustavsen@outlook.com";
  };

  # ------------------------------------------------------------------------------------------
  # ----------------------------------------- FIREFOX ----------------------------------------
  # ------------------------------------------------------------------------------------------

  programs = {
    firefox = {
      enable = true;
      languagePacks = [ "en-UK" "no" ];

      # ---- POLICIES ----
      # Check about:policies#documentation for options.
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
        DisplayMenuBar =
          "default-off"; # alternatives: "always", "never" or "default-on"
        SearchBar = "unified"; # alternative: "separate"
        PasswordManagerEnabled = false;

        # ---- EXTENSIONS ----
        # Check about:support for extension/add-on ID strings.
        # Valid strings for installation_mode are "allowed", "blocked",
        # "force_installed" and "normal_installed".
        ExtensionSettings = {
          "*".installation_mode = "allowed";
          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          # Privacy Badger:
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
          # Proton Pass:
          "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
            installation_mode = "force_installed";
          };
          # Theme:
          "dreamer-bold-colorway@mozilla.org" = {
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/dreamer-bold/latest.xpi";
            installation_mode = "force_installed";
          };
        };

        # ---- PREFERENCES ----
        # Check about:config for options.
        Preferences = {
          "browser.contentblocking.category" = {
            Value = "strict";
            Status = "locked";
          };
        };
      };
    };
  };

}
