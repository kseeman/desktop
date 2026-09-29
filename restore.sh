#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# restore.sh
# -----------------------------------------------------------------------------
#
# Puts a snapshot.sh archive back. This is the way out of the HyDE -> Lua
# migration: whatever a phase changed, this returns the desktop to the state the
# snapshot captured.
#
#   restore.sh --dry-run              show what the latest snapshot would change
#   restore.sh                        restore the latest snapshot (asks first)
#   restore.sh 2026-09-28T22-05-22-p0-baseline
#   restore.sh --target /tmp/scratch  restore somewhere else, for testing
#
# What gets restored comes from the archive's own PATHS file, not from a list
# kept here. A second copy of snapshot.sh's list would drift, and drift in this
# script means a restore that silently misses something.
#
# The restore is faithful by default: files under a captured root that the
# snapshot does not contain are DELETED. That is not tidiness -- an addition is
# only really undone if it goes away. Hyprland reads ~/.config/hypr/hyprland.lua
# in preference to hyprland.conf, so a leftover file from an abandoned phase
# would quietly keep control of the session. Use --no-delete to leave additions
# in place.
#
# Log out before restoring anything that a running session holds open.

set -euo pipefail

SNAPSHOT_ROOT="${DOTFILES_SNAPSHOT_DIR:-$HOME/.config-backups}"

DRY_RUN=false
ASSUME_YES=false
DELETE=true
TARGET="$HOME"
SNAPSHOT=""

# -----------------------------------------------------------------------------
# Arguments
# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --yes | -y)
            ASSUME_YES=true
            ;;
        --no-delete)
            DELETE=false
            ;;
        --target)
            TARGET="${2:?--target needs a directory}"
            shift
            ;;
        --help | -h)
            sed -n '3,26p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        -*)
            echo "restore.sh: unknown option: $1" >&2
            exit 1
            ;;
        *)
            SNAPSHOT="$1"
            ;;
    esac
    shift
done

info() {
    echo ""
    echo "==> $1"
}

# -----------------------------------------------------------------------------
# Locate the snapshot
# -----------------------------------------------------------------------------

if [[ -z "$SNAPSHOT" ]]; then
    SNAPSHOT="$(find "$SNAPSHOT_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' 2>/dev/null |
        sort | tail -1)"

    [[ -n "$SNAPSHOT" ]] || {
        echo "No snapshots found in $SNAPSHOT_ROOT" >&2
        exit 1
    }
elif [[ ! -d "$SNAPSHOT" ]]; then
    # A bare name is resolved against the snapshot root, so the name printed by
    # snapshot.sh can be pasted straight back in.
    SNAPSHOT="$SNAPSHOT_ROOT/$SNAPSHOT"
fi

[[ -d "$SNAPSHOT/files" ]] || {
    echo "Not a snapshot (no files/ directory): $SNAPSHOT" >&2
    exit 1
}

[[ -f "$SNAPSHOT/PATHS" ]] || {
    echo "Snapshot has no PATHS file, so its captured roots are unknown: $SNAPSHOT" >&2
    echo "It predates restore.sh and cannot be restored safely." >&2
    exit 1
}

info "Snapshot: $SNAPSHOT"
[[ -f "$SNAPSHOT/META" ]] && sed -n '1,10p' "$SNAPSHOT/META" | sed 's/^/    /'

[[ "$TARGET" != "$HOME" ]] && echo "    restoring into $TARGET (not \$HOME)"

# -----------------------------------------------------------------------------
# Verify the archive
# -----------------------------------------------------------------------------

# Checked before anything is written, so a truncated or corrupted archive is
# caught while the current state is still intact.
info "Verifying archive..."

if ! (cd "$SNAPSHOT/files" && sha256sum -c "$SNAPSHOT/MANIFEST" --quiet); then
    echo "" >&2
    echo "Archive failed verification. Refusing to restore from it." >&2
    exit 1
fi

echo "    MANIFEST ok ($(wc -l < "$SNAPSHOT/MANIFEST") files)"

# MANIFEST covers regular files only -- hashing a symlink would hash whatever it
# points at, which says nothing about the link itself. The links are the part of
# this archive most likely to be wrong in a way that still looks fine, so they
# are compared separately: ~/.config/gtk-4.0 pointing at the wrong theme would
# restore cleanly and break the desktop.
if [[ -f "$SNAPSHOT/SYMLINKS" ]]; then
    if ! diff -q \
        <(cd "$SNAPSHOT/files" && find . -type l -printf '%p\t%l\n' | sort) \
        "$SNAPSHOT/SYMLINKS" > /dev/null; then
        echo "" >&2
        echo "Symlinks in the archive no longer match SYMLINKS." >&2
        echo "Refusing to restore from it." >&2
        exit 1
    fi

    echo "    SYMLINKS ok ($(wc -l < "$SNAPSHOT/SYMLINKS") links)"
fi

# -----------------------------------------------------------------------------
# Restore
# -----------------------------------------------------------------------------

mapfile -t roots < "$SNAPSHOT/PATHS"

rsync_opts=(-aH)
[[ "$DRY_RUN" == true ]] && rsync_opts+=(--dry-run --itemize-changes)

if [[ "$DRY_RUN" == false && "$ASSUME_YES" == false ]]; then
    echo ""
    echo "About to restore ${#roots[@]} paths into $TARGET."
    [[ "$DELETE" == true ]] && echo "Files not in the snapshot will be DELETED under those paths."
    echo ""
    read -r -p "Type 'restore' to continue: " reply
    [[ "$reply" == "restore" ]] || {
        echo "Aborted."
        exit 1
    }
fi

info "Restoring ${#roots[@]} paths..."

for root in "${roots[@]}"; do
    [[ -n "$root" ]] || continue

    src="$SNAPSHOT/files/$root"
    dst="$TARGET/$root"

    [[ -e "$src" || -L "$src" ]] || {
        echo "    skip (not in archive): $root"
        continue
    }

    echo "    $root"

    # A directory is synced into place with --delete scoped to that one root, so
    # nothing outside the captured paths can ever be removed. Symlinks and plain
    # files are handed to rsync as a single source: --delete means nothing for
    # them, and -a copies a symlink as a symlink rather than its target.
    if [[ -d "$src" && ! -L "$src" ]]; then
        [[ "$DRY_RUN" == true ]] || mkdir -p "$dst"

        opts=("${rsync_opts[@]}")
        [[ "$DELETE" == true ]] && opts+=(--delete)

        rsync "${opts[@]}" "$src/" "$dst/"
    else
        [[ "$DRY_RUN" == true ]] || mkdir -p "$(dirname "$dst")"

        rsync "${rsync_opts[@]}" "$src" "$(dirname "$dst")/"
    fi
done

# -----------------------------------------------------------------------------
# What this does not do
# -----------------------------------------------------------------------------

# Packages are recorded but never installed: putting a package list back is a
# decision about the system, not about configuration, and doing it silently
# inside a config restore would be a surprise. The lists are there to diff.
if [[ "$DRY_RUN" == true ]]; then
    info "Dry run: nothing was written."
else
    info "Restored."
fi

echo ""
echo "Not restored (recorded for reference only):"
echo "    packages    $SNAPSHOT/packages/"
echo "    HyDE clone  see hyde_remote / hyde_commit in $SNAPSHOT/META"
echo ""
echo "Compare the current package set with:"
echo "    diff <(pacman -Qqe) $SNAPSHOT/packages/pacman-explicit.txt"
