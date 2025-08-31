              ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖            gg@nix
              ▜███▙       ▜███▙  ▟███▛            ------
               ▜███▙       ▜███▙▟███▛             OS: NixOS 25.05 x86_64
                ▜███▙       ▜██████▛              Host: Any thinkpad
         ▟█████████████████▙ ▜████▛     ▟▙        Kernel: 6.12.28
        ▟███████████████████▙ ▜███▙    ▟██▙       Uptime: yes
               ▄▄▄▄▖           ▜███▙  ▟███▛       Packages: 979 (nix-system), 919 (nix-user)
              ▟███▛             ▜██▛ ▟███▛        Shell: fish 4.0.2
             ▟███▛               ▜▛ ▟███▛         Resolution: ok
    ▟███████████▛                  ▟██████████▙   DE: none+awesome
    ▜██████████▛                  ▟███████████▛   WM: awesome
          ▟███▛ ▟▙               ▟███▛            Icons: Papirus-Dark [GTK2/3]
         ▟███▛ ▟██▙             ▟███▛             Terminal: WezTerm
        ▟███▛  ▜███▙           ▝▀▀▀▀              CPU: Intel i5-8250U (8) @ 3.400GHz
        ▜██▛    ▜███▙ ▜██████████████████▛        GPU: Intel UHD Graphics 620
         ▜▛     ▟████▙ ▜████████████████▛         Memory: some
               ▟██████▙       ▜███▙
              ▟███▛▜███▙       ▜███▙
             ▟███▛  ▜███▙       ▜███▙
             ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘

## Overview

This repo contains my NixOS flake-based configuration and setup scripts.  
It handles both system config (via `nixos-rebuild`) and user dotfiles (like AwesomeWM, fish, dunst, rofi, etc.).

## Script: `reconfigure.sh`

One script to manage everything:

- `reload`  
  Syncs config files (dotfiles, scripts), restarts AwesomeWM if possible.

- `rebuild`  
  Copies the Nix flake to `/etc/nixos`, runs `nixos-rebuild switch`, then reloads.

- `update`  
  Runs `nix flake update` to pull the latest inputs.

- `upgrade`  
  Combines `update` and `rebuild` in one.

## Bootstrap Installation

To install this config on a fresh NixOS system:

```bash
git clone https://github.com/GerhardGustavsen/nixCore ~/nixCore
cd ~/nixCore/scripts
./reconfigure.sh rebuild
```
