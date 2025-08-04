{ pkgs, ... }:

let
  rootTriggerScript = pkgs.writeScript "log-hw-event" ''
    #!${pkgs.runtimeShell}
    touch "/tmp/hw-trigger-$(date +%s)-$1"
  '';
in {
  imports = [ ./hardware-configuration.nix ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.command-not-found.enable = false;

  # Hostname
  networking.hostName = "nix";

  # Shell
  programs.fish.enable = true;

  # User
  users.users.gg = {
    isNormalUser = true;
    description = "Gerhard Gustavsen";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
    shell = pkgs.fish;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = false;
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      enableCryptodisk = true;
      device = "nodev";
    };
    timeout = 1;
  };
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];

  # Language and locale
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure keyboard layout
  console.keyMap = "no";
  services.xserver.xkb = {
    layout = "no";
    options = "lv3:ralt_switch";
  };

  # Tiling manager
  services = {
    xserver = {
      enable = true;
      windowManager.awesome = {
        enable = true;
        luaModules = with pkgs.luaPackages; [
          luarocks # is the package manager for Lua modules
          luadbi-mysql # Database abstraction layer
        ];
      };
    };

    displayManager = {
      sddm.enable = true;
      defaultSession = "none+awesome";
      autoLogin.enable = true;
      autoLogin.user = "gg";
    };
  };
  programs.i3lock.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    jetbrains-mono # system font
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.inconsolata
    font-awesome
  ];
  fonts.fontDir.enable = true;

  # ENV varriables
  environment.variables = {
    TERMINAL = "xfce4-terminal";
    EDITOR = "vim";
    BROWSER = "firefox";
  };
  systemd.user.extraConfig = ''
    ImportEnvironment=DISPLAY XAUTHORITY
  ''; # SUSPECT
  xdg.mime = {
    enable = true;
    defaultApplications = {
      # file manager
      "inode/directory" = "Thunar.desktop";
      # HTML files
      "text/html" = "firefox.desktop";
      # URL handlers
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
  };

  # Filemanager
  programs.thunar.enable = true;
  programs.xfconf.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [ thunar-archive-plugin ];
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
  services.udisks2.enable = true; # AutoMount backend

  # Networking protocols
  networking.networkmanager.enable = true; # Enable networking
  networking.firewall.enable = true; # Firewall
  services.openssh.enable = true; # Enable SSH
  services.printing.enable = true; # Enable printer support
  networking.modemmanager.enable = true;
  systemd.services.ModemManager = {
    enable = pkgs.lib.mkForce true;
    wantedBy = [ "multi-user.target" "network.target" ];
  };

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  environment.etc = {
    "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text =
      "	bluez_monitor.properties = {\n		[\"bluez5.enable-sbc-xq\"] = true,\n		[\"bluez5.enable-msbc\"] = true,\n		[\"bluez5.enable-hw-volume\"] = true,\n		[\"bluez5.headset-roles\"] = \"[ hsp_hs hsp_ag hfp_hf hfp_ag ]\"\n	}\n";
  };

  # Inverse tutchpad scolling
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  # Security
  security.polkit.enable = true; # managing user premitions
  programs.dconf.enable = true; # somthing, something, keys...
  # services.pcscd.enable = true; # Smart card... I donno
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Graphics
  hardware.graphics.enable32Bit = true; # Steam support
  services.picom = {
    enable = true;
    settings.vsync = true;
  };
  hardware.graphics = { enable = true; };
  services.xserver.videoDrivers = [ "intel" ]; # "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;

    # prime = {
    #   sync.enable = true;
    #   # Make sure to use the correct Bus ID values for your system!
    #   intelBusId = "PCI:0:2:0";
    #   nvidiaBusId = "PCI:12:0:0";
    # };
  };

  # Nix garbage collection
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "monthly"; # You can change this to "daily" if you want
      options = "--delete-older-than 14d"; # Keep only the last 2 weeks
    };
  };

  # Monitor and usb connection watch:
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="tty", TAG+="systemd", ENV{SYSTEMD_WANTS}="log-usb-event.service"
    ACTION=="change", SUBSYSTEM=="drm", TAG+="systemd", ENV{SYSTEMD_WANTS}="log-monitor-event.service"
    ACTION=="change", KERNEL=="lid*", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="0", \
      TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="log-on-lid.service"
  '';
  systemd.services.log-usb-event = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${rootTriggerScript} usb";
    };
  };
  systemd.services.log-monitor-event = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${rootTriggerScript} monitor";
    };
  };
  systemd.services.log-on-lid = {
    description = "Delay suspend to allow screen lock";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        "${pkgs.bash}/bin/bash -c '${rootTriggerScript} sleep; sleep 3'";
    };
  };

  # SYSTEM WIDE PROGRAMS
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Terminal:
    xfce.xfce4-terminal
    vim

    # Mobile internett:
    modem-manager-gui

    # Backupp browser:
    chromium

    # Multi monitor support:
    arandr
    autorandr

    # Microcontrollers:
    mpremote
    esptool # ?
    picocom # ?
    minicom # ?

    # Coding resources:
    python3
    gcc
    poetry
    nixfmt-classic # Nix formatter

    # Small programs:
    rofi # Application launcer
    dunst # notification daemon
    flameshot # screenshot app
    pavucontrol # Audio controll
    polkit_gnome # GUI for user auth
    networkmanagerapplet # nm-applet nm-connection-editor
    brightnessctl # Backlight brightness support
    galculator # Calculator
    udiskie # USB automout applet
    baobab # disk analyser tool
    speedtest-cli # network speed test
    nethogs # program network usage
    bluetuith

    # Cmd tools:
    zip # zip files
    unzip # unzip files
    gnupg # OpenPGP, encrypt/decrypt & sign data
    curl # transfer data over URLs (HTTP, FTP, etc.)
    file # detect a file’s type/format
    xclip # clipboard manager
    htop # program control pannel
    libnotify # notifyer backend
    xorg.xev # show keycodes
    xorg.xmodmap # list keycodes
    imagemagick # Blur images
    xdotool # for scripts flashing to microcontollers
    wget
    usbutils
    lsof
    pciutils
    inotify-tools
    coreutils
    maim
    lshw
    sshfs # accsess to folk.NTNU
    xidlehook # autolocker
  ];

  system.stateVersion = "24.11"; # apparantly important! ¯\_(ツ)_/¯
  home-manager.backupFileExtension = ".backup";

  # Might be important later from here on

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # Configure network proxy if necessary:
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether. 

  # services.upower.enable = true; # battery API

}
