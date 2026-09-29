#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# snapshot.sh
# -----------------------------------------------------------------------------
#
# Captures the current desktop configuration so it can be put back exactly as it
# is today. This exists for the HyDE -> Lua migration: every phase of that work
# is reversible, and this is what "reversible" is measured against.
#
#   snapshot.sh                 snapshot to ~/.config-backups/<timestamp>
#   snapshot.sh p0-baseline     ... with a label, for per-phase snapshots
#   snapshot.sh --dry-run       show what would be captured
#
# Restore with restore.sh, which reads the archive rather than keeping its own
# copy of the list below -- the same reason uninstall.sh finds what to unlink
# instead of listing it.
#
# The destination is deliberately OUTSIDE this repository. The archive contains
# ~/.config/zsh/.zsh_history and whatever else the desktop holds; this repo is
# public. Never move a snapshot into the working tree.
#
# Size: the first snapshot is ~2.4GB, almost entirely ~/.config/hyde/themes
# (61 themes' wallpapers). Later snapshots hardlink unchanged files against the
# previous one via --link-dest, so they cost close to nothing.

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SNAPSHOT_ROOT="${DOTFILES_SNAPSHOT_DIR:-$HOME/.config-backups}"

DRY_RUN=false
LABEL=""

# What today's desktop is made of, relative to $HOME. Paths that do not exist
# are skipped, so this list is safe to share between machines.
#
# Deliberately captured even though they are large or regenerable: restoring has
# to reproduce today exactly, and "it would probably rebuild itself" is not a
# guarantee. ~/HyDE is the one exception -- it is a git clone, so META records
# its remote and commit instead of 400MB of history.
#
# Four of these are here because config alone does not describe a desktop:
#
#   .local/state/hyde     staterc names the *active* theme. Without it a restore
#                         puts back all 61 themes and none of them selected.
#   .local/share/waybar   the layouts and styles staterc points at, which live
#   .local/share/rofi     outside the captured ~/.config counterparts.
#   .local/share/themes   the target of the captured ~/.config/gtk-4.0 symlink.
#                         Restoring the link without it leaves it dangling.
#
# ~/.local/share/icons (6.7GB) is left out: it is an installed asset, replaced
# by reinstalling its package, and nothing here modifies it.
SNAPSHOT_PATHS=(
    .config/hypr
    .config/hyde
    .config/waybar
    .config/rofi
    .config/dunst
    .config/wlogout
    .config/kitty
    .config/fastfetch
    .config/Kvantum
    .config/qt5ct
    .config/qt6ct
    .config/gtk-3.0
    .config/gtk-4.0
    .config/xsettingsd
    .config/uwsm
    .config/pypr
    .config/zsh
    .config/dconf
    .config/systemd/user
    .local/lib/hyde
    .local/share/hyde
    .local/share/hypr
    .local/share/waybar
    .local/share/rofi
    .local/share/themes
    .local/state/hyde
    .local/bin/hyde-shell
    .local/bin/hydectl
    .gtkrc-2.0
    .zshenv
    .zshrc
)

# Excluded from the paths above, not from the snapshot as a whole. These are
# build artefacts of a package manager rather than configuration: 638MB of the
# 639MB in ~/.local/state/hyde is two virtualenvs, while the part that matters
# is a 236-byte staterc naming the active theme.
SNAPSHOT_EXCLUDES=(
    /.local/state/hyde/python_env
    /.local/state/hyde/pip_env
)

# -----------------------------------------------------------------------------
# Arguments
# -----------------------------------------------------------------------------

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        --help | -h)
            sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        -*)
            echo "snapshot.sh: unknown option: $arg" >&2
            exit 1
            ;;
        *)
            # The label becomes part of a directory name and passes through
            # eval in run(), so it is restricted rather than sanitised: a slash
            # would nest the snapshot somewhere unintended, and a quote would
            # break the commands built from it.
            [[ -z "$LABEL" ]] || {
                echo "snapshot.sh: only one label, got '$LABEL' and '$arg'" >&2
                exit 1
            }

            [[ "$arg" =~ ^[A-Za-z0-9._-]+$ ]] || {
                echo "snapshot.sh: label may only contain letters, digits, . _ -" >&2
                exit 1
            }

            LABEL="$arg"
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

info() {
    echo ""
    echo "==> $1"
}

run() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] $*"
    else
        eval "$@"
    fi
}

# -----------------------------------------------------------------------------
# Destination
# -----------------------------------------------------------------------------

# Colons are legal in a filename but awkward in one, so the ISO time uses
# dashes throughout. Sorting stays chronological either way.
name="$(date +%Y-%m-%dT%H-%M-%S)"
[[ -n "$LABEL" ]] && name="$name-$LABEL"

DEST="$SNAPSHOT_ROOT/$name"

# The most recent existing snapshot, used as rsync's --link-dest so unchanged
# files are hardlinked rather than copied again. Without it, one snapshot per
# migration phase would cost 2.4GB each.
# MANIFEST is written last, so its presence is what distinguishes a finished
# snapshot from the remains of an interrupted one. Hardlinking against wreckage
# would be wrong, and picking it as "the latest" is how a restore ends up
# diagnosing the wrong problem.
previous=""
if [[ -d "$SNAPSHOT_ROOT" ]]; then
    previous="$(find "$SNAPSHOT_ROOT" -mindepth 2 -maxdepth 2 -name MANIFEST 2>/dev/null |
        xargs -r -n1 dirname | sort | tail -1)"
fi

info "Snapshot: $DEST"
[[ -n "$previous" ]] && echo "    hardlinking unchanged files against $(basename "$previous")"

run "mkdir -p '$DEST/files' '$DEST/packages'"

# -----------------------------------------------------------------------------
# Files
# -----------------------------------------------------------------------------

# Only the paths that actually exist: rsync fails the whole run on a missing
# source, and which of these are present differs per machine.
present=()
for path in "${SNAPSHOT_PATHS[@]}"; do
    [[ -e "$HOME/$path" || -L "$HOME/$path" ]] && present+=("$path")
done

if [[ ${#present[@]} -eq 0 ]]; then
    echo "Nothing to snapshot: none of the configured paths exist." >&2
    exit 1
fi

info "Capturing ${#present[@]} paths..."

# -a preserves symlinks *as symlinks* rather than following them, which is what
# keeps ~/.config/gtk-4.0 (a link into ~/.local/share/themes) a link. -R plus
# the /./ pivot in each source path recreates the $HOME-relative tree under
# files/, so restoring is a straight copy back with no path rewriting.
rsync_opts=(-aHR --info=stats1)
[[ -n "$previous" ]] && rsync_opts+=("--link-dest=$previous/files")
[[ "$DRY_RUN" == true ]] && rsync_opts+=(--dry-run)

# Anchored at the transfer root, which -R makes the $HOME-relative path.
for exclude in "${SNAPSHOT_EXCLUDES[@]}"; do
    rsync_opts+=("--exclude=$exclude")
done

sources=()
for path in "${present[@]}"; do
    sources+=("$HOME/./$path")
done

# 24 is "a source file vanished during the transfer", which is routine when
# copying a live ~/.config out from under running applications and does not make
# the snapshot unusable. Anything else is a real failure and stops the run.
rsync_status=0
rsync "${rsync_opts[@]}" "${sources[@]}" "$DEST/files/" || rsync_status=$?

if [[ $rsync_status -ne 0 && $rsync_status -ne 24 ]]; then
    echo "rsync failed with status $rsync_status" >&2
    exit 1
fi

[[ $rsync_status -eq 24 ]] && echo "    (some files vanished mid-copy; that is expected on a live system)"

# -----------------------------------------------------------------------------
# System state
# -----------------------------------------------------------------------------

info "Recording package and service state..."

# || true on both: a pacman query with no results exits 1, and under `set -e`
# that would abandon the snapshot here -- after files/ is written but before the
# manifest that makes it restorable. A machine with no AUR packages is ordinary,
# not an error.
if command -v pacman &>/dev/null; then
    run "pacman -Qqe > '$DEST/packages/pacman-explicit.txt' || true"
    run "pacman -Qqm > '$DEST/packages/pacman-foreign.txt' || true"
fi

if command -v systemctl &>/dev/null; then
    # || true: this exits non-zero when it has nothing to list, which is fine.
    run "systemctl --user list-unit-files --state=enabled --no-pager --plain \
        > '$DEST/packages/systemd-user-enabled.txt' 2>/dev/null || true"
fi

# -----------------------------------------------------------------------------
# Metadata
# -----------------------------------------------------------------------------

# ~/HyDE is a git clone. Recording where it came from and which commit is both
# smaller and more useful than copying it: reinstalling HyDE means checking that
# commit out again, not restoring a directory.
hyde_remote="$(git -C "$HOME/HyDE" remote get-url origin 2>/dev/null || echo "-")"
hyde_commit="$(git -C "$HOME/HyDE" rev-parse HEAD 2>/dev/null || echo "-")"

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
dotfiles_commit="$(git -C "$dotfiles_dir" rev-parse HEAD 2>/dev/null || echo "-")"

if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] write META"
else
    cat > "$DEST/META" <<EOF
snapshot        $name
created         $(date -Is)
host            $(hostname)
user            $USER
kernel          $(uname -r)
hyprland        $(hyprctl version 2>/dev/null | head -1 || echo "-")
hyde_remote     $hyde_remote
hyde_commit     $hyde_commit
dotfiles_commit $dotfiles_commit
label           ${LABEL:--}

This archive contains private data (shell history, application state).
It lives outside the dotfiles repository on purpose. Do not commit it.
EOF
fi

# -----------------------------------------------------------------------------
# Captured roots
# -----------------------------------------------------------------------------

# The roots this snapshot covers, one per line, so the archive describes itself
# and restore.sh needs no second copy of SNAPSHOT_PATHS.
#
# This is not bookkeeping: restore.sh deletes files under each root that the
# snapshot does not contain, which is the only way a restore actually undoes an
# addition. Scoping those deletes needs to know where a captured root ends, and
# the files/ tree alone cannot say whether .config or .config/hypr was the root.
if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] write PATHS"
else
    printf '%s\n' "${present[@]}" > "$DEST/PATHS"
fi

# -----------------------------------------------------------------------------
# Integrity
# -----------------------------------------------------------------------------

# MANIFEST is sha256sum's own format so `sha256sum -c MANIFEST` verifies the
# archive directly -- restore.sh checks it before writing anything. Symlinks are
# listed separately because hashing one would hash its target's contents, which
# both defeats the check and follows the link this script took care to preserve.
if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] write MANIFEST and SYMLINKS"
else
    info "Hashing (2GB+ takes a moment)..."

    (
        cd "$DEST/files"
        find . -type f -print0 | sort -z | xargs -0 -r sha256sum > "$DEST/MANIFEST"
        find . -type l -printf '%p\t%l\n' | sort > "$DEST/SYMLINKS"
    )

    files="$(wc -l < "$DEST/MANIFEST")"
    links="$(wc -l < "$DEST/SYMLINKS")"
    size="$(du -sh "$DEST" | cut -f1)"

    info "Done: $files files, $links symlinks, $size"
    echo "    $DEST"
    echo ""
    echo "Restore with:"
    echo "    $(dirname "${BASH_SOURCE[0]}")/restore.sh --dry-run"
fi
