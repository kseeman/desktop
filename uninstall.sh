#!/usr/bin/env bash

set -euo pipefail

# Undoes what install.sh put in place, and nothing it cannot be sure it put
# there:
#
# - Every symlink pointing into this repo is removed, and what link_config
#   moved aside for it is put back. Found by the same scan the dotfiles'
#   uninstaller uses, restricted to this repo.
# - The login session entry is removed, since a stale one fails a login.
#
# Packages, ~/.config/hypr/hypridle.conf (the bar owns it once seeded) and the
# generated theme cache are left alone and only reported.
#
# Run this before the dotfiles' own uninstall.sh: the helpers are read from
# ~/.dotfiles, which that removes.

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

DESKTOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"

SESSION_ENTRY="/usr/share/wayland-sessions/hyprland-dotfiles.desktop"

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        -h|--help)
            echo "Usage: ./uninstall.sh [--dry-run]"
            exit 0
            ;;
    esac
done

if [[ ! -f "$HOME/.dotfiles/lib/install.sh" ]]; then
    echo "~/.dotfiles/lib/install.sh is missing, so the dotfiles were uninstalled"
    echo "first. Remove ~/.config/hypr/scripts, the links in ~/.config/hypr into"
    echo "this repo, and $SESSION_ENTRY by hand."
    exit 1
fi

source "$HOME/.dotfiles/lib/install.sh"

# Only this repo: the dotfiles' links are the dotfiles' uninstaller's business.
REPO_ROOTS=("$DESKTOP_DIR")

info "Uninstalling the desktop from:"
echo "$DESKTOP_DIR"

if [[ "$DRY_RUN" == true ]]; then
    echo "Running in dry-run mode. No changes will be made."
fi

# -----------------------------------------------------------------------------
# Links
# -----------------------------------------------------------------------------

info "Removing links into the repo..."

links="$(repo_links)"

if [[ -z "$links" ]]; then
    echo "None found."
fi

remove_repo_links "$links"

# -----------------------------------------------------------------------------
# The session entry
# -----------------------------------------------------------------------------

# Outside $HOME, installed with sudo, and therefore missed by every scan above.
#
# Worth more care than a dangling symlink: what is left behind is an entry at
# the login screen pointing at a config that no longer exists, so choosing it
# fails the login rather than doing nothing. Someone would meet that at a
# greeter, which is the worst place to debug anything.
#
# Only removed when its Exec still names this repo's init.lua. A hand-edited
# entry, or one another tool happens to have put at the same path, is left and
# reported.

if [[ -f "$SESSION_ENTRY" ]]; then
    if grep -qF "$DESKTOP_DIR/init.lua" "$SESSION_ENTRY" 2> /dev/null; then
        info "Removing the session entry..."
        run "sudo rm '$SESSION_ENTRY'"
    else
        echo "Left $SESSION_ENTRY: its Exec does not name this repo."
    fi
fi

# -----------------------------------------------------------------------------
# Left in place
# -----------------------------------------------------------------------------

echo ""
echo "======================================"
if [[ "$DRY_RUN" == true ]]; then
    echo " Dry run complete: nothing was changed"
else
    echo " Desktop uninstalled"
fi
echo "======================================"
echo ""
echo "Left in place, since they may predate the desktop or be in use:"
echo "  Packages            $DESKTOP_DIR/packages/pacman.txt and aur.txt"
echo "  Idle settings       ~/.config/hypr/hypridle.conf"
echo "  Generated theme     \${XDG_CACHE_HOME:-~/.cache}/dotfiles/theme"
echo ""
echo "This checkout itself is untouched."
