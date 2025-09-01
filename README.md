  [~]❯ neofetch  
            ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖            gg@nix  
            ▜███▙       ▜███▙  ▟███▛            ------  
             ▜███▙       ▜███▙▟███▛             OS: NixOS  
              ▜███▙       ▜██████▛              Host: Thnkpad T480  
       ▟█████████████████▙ ▜████▛     ▟▙        Kernel: 6.12.43  
      ▟███████████████████▙ ▜███▙    ▟██▙       Uptime: yes  
             ▄▄▄▄▖           ▜███▙  ▟███▛       Packages: 1033 (nix-system), 1162 (nix-user)  
            ▟███▛             ▜██▛ ▟███▛        Shell: fish 4.0.2  
           ▟███▛               ▜▛ ▟███▛         Resolution: ok  
  ▟███████████▛                  ▟██████████▙   DE: none+awesome  
  ▜██████████▛                  ▟███████████▛   WM: awesome  
        ▟███▛ ▟▙               ▟███▛            Icons: Papirus-Dark [GTK2/3]  
       ▟███▛ ▟██▙             ▟███▛             Terminal: WezTerm  
      ▟███▛  ▜███▙           ▝▀▀▀▀              CPU: Intel i7-8550U (8) @ 4.000GHz  
      ▜██▛    ▜███▙ ▜██████████████████▛        GPU: Intel UHD Graphics  
       ▜▛     ▟████▙ ▜████████████████▛         GPU: NVIDIA GeForce eGPU  
             ▟██████▙       ▜███▙               Memory: 4973MiB / 23793MiB  
            ▟███▛▜███▙       ▜███▙  
           ▟███▛  ▜███▙       ▜███▙  
           ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘  
    
## Overview

This repo contains my NixOS flake-based configuration and setup scripts.  
It handles both system config (via `nixos-rebuild`) and user dotfiles (like AwesomeWM, fish, dunst, rofi, etc.).

## Main script: `reconfigure.sh`

One script to manage everything:

- `reload`  
  Syncs config files (dotfiles, scripts), restarts AwesomeWM if possible.

- `rebuild`  
  Copies the Nix flake to `/etc/nixos`, runs `nixos-rebuild switch`, then reloads.

- `update`  
  Runs `nix flake update` to update all packes to the latest version

- `upgrade`  
  Combines `update` and `rebuild` in one.

## Bootstrap Installation

To install this config on any NixOS system:

```bash
git clone https://github.com/GerhardGustavsen/nixCore ~/nixCore
cd ~/nixCore/scripts
./reconfigure.sh rebuild
```
