#!/usr/bin/env bash
set -euo pipefail

# -------------------- Colors --------------------
GREEN="\033[1;32m"
PURPLE="\033[38;2;135;0;255m"
RED="\033[1;31m"
RESET="\033[0m"

# -------------------- Functions --------------------

step() { echo -e "${PURPLE}[  ▶▶  ]${RESET} $1"; }

success() { echo -e "${GREEN}[  OK  ]${RESET} $1"; }

error() { echo -e "${RED}[  !!  ]${RESET} $1"; }

copy() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if cp -f "$src" "$dest"; then
        success "Copied $src → $dest"
    else error "ERROR: failed to copy $src → $dest" >&2; fi
}

link() {
    local target="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if ln -sf "$target" "$dest"; then
        success "Linked $dest → $target"
    else error "ERROR: failed to link $dest → $target" >&2; fi
}

kill_clients_on_workspace() {
  local tag="$1"
  awesome-client <<EOF
for _, c in ipairs(client.get()) do
  if c.first_tag and c.first_tag.name == "${tag}" then
    c:kill()
  end
end
EOF
}

save_visible_tags() {
  : > /tmp/awesome-visible-tags
  for screen in $(seq 1 5); do
    raw_output=$(awesome-client "return (screen[${screen}] and screen[${screen}].selected_tag and screen[${screen}].selected_tag.name) or ''" 2>/dev/null)
    tag=$(printf "%s" "$raw_output" | sed -n 's/.*"\(.*\)".*/\1/p')
    tag=$(printf "%s" "$tag" | tr -d '"\n ')
    if [ -n "$tag" ]; then
      echo "${screen}:${tag}" >> /tmp/awesome-visible-tags
    fi
  done
}

# -------------------- Paths --------------------
REPO_DIR="$HOME/nixCore/nixos"
TARGET_DIR="/etc/nixos"
COREDOT="$HOME/nixCore/dotfiles"
DOT="$HOME/.config"
CORESCR="$HOME/nixCore/scripts"
EXE="$HOME/.local/bin"

# -------------------- Operations --------------------

reload() {
    step "Copying dotfiles…"
    copy "$COREDOT/xfce-terminal.xml" "$DOT/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml"
    copy "$COREDOT/dunst.conf" "$DOT/dunst/dunstrc"
    copy "$COREDOT/udiskie.yml" "$DOT/udiskie/config.yml"
    copy "$COREDOT/rofi.rasi" "$DOT/rofi/config.rasi"
    copy "$COREDOT/fish/prompt.fish" "$DOT/fish/functions/fish_prompt.fish"
    copy "$COREDOT/fish/prompt_right.fish" "$DOT/fish/functions/fish_right_prompt.fish"
    copy "$COREDOT/fish/startup.fish" "$DOT/fish/config.fish"
    copy "$COREDOT/fish/theme.fish" "$DOT/fish/fish_variables"
    copy "$COREDOT/awesome.lua" "$DOT/awesome/rc.lua"
    copy "$COREDOT/statusbar.lua" "$DOT/awesome/statusbar.lua"
    copy "$COREDOT/theme.lua" "$DOT/awesome/theme.lua"

    step "Creating symlinks for scripts…"
    link "$CORESCR/reconfigure.sh" "$EXE/reconfigure"
    link "$CORESCR/microcontroller-flash.sh" "$EXE/mcflash"
    link "$CORESCR/mode.sh" "$EXE/mode"
    link "$CORESCR/egpu.sh" "$EXE/egpu"
    chmod +x "$EXE/"*

    if [ -n "${DISPLAY-}" ] && command -v awesome-client &>/dev/null; then
        step "Killing programs on hidden workspaces..."
        kill_clients_on_workspace scrap
        kill_clients_on_workspace preload
        success "All programs successfully murdered"
        step "Saving visible tags per screen..."
        save_visible_tags
        step "Reloading AwesomeWM configuration..."
        success "\033[1;32mAll done!"
        awesome-client 'awesome.restart()' >/dev/null 2>&1
    else
        error "Not in an X session or awesome-client not found; skipping AwesomeWM reload."
    fi
}

rebuild() {
    step "Copying flake files into $TARGET_DIR…"
    sudo cp -f "$REPO_DIR"/{flake.nix,flake.lock,configuration.nix,home.nix} "$TARGET_DIR/"
    sudo chown root:root "$TARGET_DIR"/{flake.nix,flake.lock,configuration.nix,home.nix}
    sudo chmod 644 "$TARGET_DIR"/{flake.nix,flake.lock,configuration.nix,home.nix}
    success "Flake files updated in $TARGET_DIR"

    step "Building new system configuration…"
    sudo nixos-rebuild switch --flake "$TARGET_DIR#nix" 2>&1 | tee >(grep --color error >&2) || false
    success "System rebuild complete."
    reload
}

update() {
    step "Updating flake.lock in $REPO_DIR…"
    nix flake update --flake "$REPO_DIR"
    success "Flake.lock updated."
}

upgrade() {
    update
    rebuild
}

# -------------------- Entry Point --------------------
case "${1-}" in
rebuild) rebuild ;;
reload) reload ;;
update) update ;;
upgrade) upgrade ;;
*)
    echo -e "${RED}Usage: $0 {rebuild|reload|update|upgrade}${RESET}" >&2
    exit 1
    ;;
esac
