# desktop

A Lua-configured Hyprland desktop for Arch-based Linux: a Quickshell bar,
switchable rices with palettes that can come from the wallpaper, generated
themes for everything else that carries a colour, and snapshot tooling to make
changes to all of it reversible.

It is installed on top of [dotfiles](https://github.com/kseeman/dotfiles),
which own the shell, Neovim, tmux and kitty. This repo themes those by writing
`$XDG_CACHE_HOME/dotfiles/theme/`, and they work unchanged without it.

## Install

The dotfiles first, then this:

```sh
git clone https://github.com/kseeman/dotfiles ~/Repos/dotfiles
~/Repos/dotfiles/install.sh

git clone https://github.com/kseeman/desktop ~/Repos/desktop
~/Repos/desktop/install.sh            # --dry-run to see what it would do
```

It installs the packages in `packages/`, verifies the config, installs a
**Hyprland (dotfiles)** login session pointing at this checkout, renders the
theme files and links the bar's helper scripts into `~/.config/hypr/scripts`.
Pick the session once at the greeter; sddm remembers it.

The session names this checkout's path, so if you move it, run `install.sh`
again.

## Uninstall

```sh
~/Repos/desktop/uninstall.sh          # before the dotfiles' uninstall.sh
```

Removes the links into this repo and the session entry. Packages, the idle
settings the bar owns and the generated theme cache are left and reported.

## Day to day

```sh
./rice.sh                             # list rices, marking the active one
./rice.sh switch slate                # wear a different one
./nested.sh                           # try the config in a nested compositor
./verify-config.sh init.lua           # check a config before it reaches a login
```

## Snapshots

```sh
./snapshot.sh <label>                 # capture the desktop's state
./restore.sh --dry-run                # see what putting it back would change
./archive.sh put                      # encrypted copy to removable storage
```

Snapshots go to `$XDG_DATA_HOME/dotfiles/snapshots`, never into this repo: they
hold shell history and secrets.

## Layout

```
init.lua            entry point Hyprland is started with
config/ bindings/   the Hyprland configuration itself
lib/                palette, roles, rice resolution, paths
providers/          which program fills each role (bar, lock, wallpaper, ...)
rices/<name>/       one directory per look: palette.lua and rice.lua
quickshell/pill/    the bar, vendored from Ricelin (see VENDORED.md)
render-theme.lua    renders *.in templates from the active palette
qt/ wlogout/        templates for the rest of the generated configs
session/            the login session entry template
hyde/               HyDE's user-tier files, kept but inert
packages/           pacman and AUR manifests
```

`CLAUDE.md` holds the reasoning behind most of this — read it before changing
anything structural.
