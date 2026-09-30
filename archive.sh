#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# archive.sh
# -----------------------------------------------------------------------------
#
# Copies a snapshot to removable storage, encrypted.
#
#   archive.sh list                       what is on the destination
#   archive.sh put [snapshot]             pack, encrypt and copy (latest by default)
#   archive.sh get <name>                 bring one back as a local snapshot
#   archive.sh verify [name]              check the checksum and the passphrase
#
# The snapshots themselves stay where they are. This is a second, slower copy
# for the failure the local ones cannot cover: the machine being lost rather
# than a migration phase going wrong.
#
# -----------------------------------------------------------------------------
# Why a tar, and why encrypted
# -----------------------------------------------------------------------------
#
# The destination is a vfat stick, which is the only option that survives losing
# the machine -- and vfat stores no symlinks, no permission bits and no
# hardlinks. A snapshot is 763 symlinks and a `chmod 600` credentials file, so
# copying the tree there would silently destroy exactly the things the archive
# is careful about. A tar carries all of it as metadata inside one file.
#
# Encrypted because the archive holds ~/.config/dotfiles -- secrets and four
# thousand lines of shell history -- and vfat has no permissions to protect them
# with. On a stick that can be lost, that is the difference between a backup and
# a disclosure.
#
# **Symmetric, with a passphrase, on purpose.** A key file kept on this machine
# would make the archive unreadable in the one situation it exists for. Keep the
# passphrase in 1Password; it is the only part that must outlive the disk.
#
# Split into 3G parts because vfat cannot hold a file larger than 4G.

set -euo pipefail

DESKTOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

XDG_DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
SNAPSHOT_ROOT="${DOTFILES_SNAPSHOT_DIR:-$XDG_DATA/dotfiles/snapshots}"

# Where the stick is expected. Overridable, because a mount point is a property
# of the machine rather than of this repo.
DEST="${DOTFILES_ARCHIVE_DIR:-/run/media/$USER/USB321FD/dotfiles-snapshots}"

PART_SIZE="${DOTFILES_ARCHIVE_PART_SIZE:-3G}"

info() { echo ""; echo "==> $*"; }

# Read once, then hand it to gpg on fd 3. Not fd 0: that is the tar stream, and
# gpg would happily take the first line of the archive as the passphrase.
# `read_passphrase confirm` asks twice and compares, which is what writing an
# archive needs: nothing downstream can tell a typo from a passphrase, so a
# mistyped one encrypts successfully, reports Done, and stays wrong until the
# day the archive is needed. Reading is different -- a wrong passphrase there
# simply fails to decrypt, immediately and visibly -- so `get` and `verify` ask
# once.
read_passphrase() {
    local confirm="${1:-}"

    if [[ -n "${DOTFILES_ARCHIVE_PASSPHRASE:-}" ]]; then
        PASSPHRASE="$DOTFILES_ARCHIVE_PASSPHRASE"
        return 0
    fi

    # From the terminal rather than stdin, so the passphrase is never taken out
    # of a pipe and this still prompts when stdin is redirected.
    #
    # `|| true` matters more than it looks. `read` returns non-zero on EOF, and
    # under `set -e` that killed the script *before* the guard below could say
    # anything -- so running this without a terminal gave a silent exit 1 and an
    # empty destination directory, which is the worst way to learn that nothing
    # was archived.
    # Opened rather than tested with -r: /dev/tty passes a readability test even
    # with no controlling terminal, and only fails when something tries to open
    # it ("No such device or address").
    PASSPHRASE=""

    if { : < /dev/tty; } 2> /dev/null; then
        read -rsp "    Passphrase: " PASSPHRASE < /dev/tty || PASSPHRASE=""
        echo ""
    fi

    # Worded for every caller, not just put: verify and get read an archive and
    # write nothing, so "refusing to write an archive nothing protects" was
    # simply untrue on two of the three paths.
    [[ -n "$PASSPHRASE" ]] || {
        echo "No passphrase, and no terminal to ask for one." >&2
        echo "Run this from a terminal, or set DOTFILES_ARCHIVE_PASSPHRASE." >&2
        exit 1
    }

    if [[ "$confirm" == "confirm" ]]; then
        local again=""

        read -rsp "    Again:      " again < /dev/tty || again=""
        echo ""

        [[ "$PASSPHRASE" == "$again" ]] || {
            echo "The two did not match; nothing written." >&2
            exit 1
        }
    fi
}

# -----------------------------------------------------------------------------
# Destination
# -----------------------------------------------------------------------------

# A destination that is not mounted is the failure worth guarding against: the
# directory would be created on the root disk, the copy would succeed, and the
# result would look exactly like a backup while sitting on the disk it was meant
# to survive.
require_mounted() {
    local dir="$DEST"

    # Walk up to the nearest existing ancestor -- the archive directory itself
    # may not exist yet on a fresh stick.
    while [[ ! -d "$dir" && "$dir" != "/" ]]; do
        dir="$(dirname "$dir")"
    done

    # The test is "a different filesystem from the snapshots", not "a mount
    # point". An unmounted stick leaves its mount point as an ordinary empty
    # directory on the root disk, so the copy would succeed and look exactly
    # like a backup while sitting on the disk it exists to survive. Comparing
    # devices catches that, and says something true rather than something
    # incidental.
    local dest_dev source_dev
    dest_dev="$(findmnt -no SOURCE --target "$dir" 2>/dev/null || true)"
    source_dev="$(findmnt -no SOURCE --target "$SNAPSHOT_ROOT" 2>/dev/null || true)"

    if [[ -z "$dest_dev" || "$dest_dev" == "$source_dev" ]]; then
        echo "Refusing: $DEST is on the same filesystem as the snapshots." >&2
        echo "" >&2
        echo "    snapshots  $source_dev" >&2
        echo "    archive    ${dest_dev:-unresolvable}" >&2
        echo "" >&2
        echo "An unmounted stick leaves an ordinary empty directory behind, so" >&2
        echo "this would have looked like a backup while sitting on the disk it" >&2
        echo "exists to survive. Mount it, or set DOTFILES_ARCHIVE_DIR." >&2
        exit 1
    fi
}

latest_snapshot() {
    # MANIFEST is written last, so its presence is what marks a snapshot
    # complete -- an interrupted one is never picked.
    local newest=""
    for d in "$SNAPSHOT_ROOT"/*/; do
        [[ -f "$d/MANIFEST" ]] || continue
        newest="$d"
    done
    [[ -n "$newest" ]] || {
        echo "No complete snapshot in $SNAPSHOT_ROOT" >&2
        exit 1
    }
    basename "$newest"
}

# -----------------------------------------------------------------------------
# Commands
# -----------------------------------------------------------------------------

# The most recently archived name, so `verify` needs no argument in the common
# case -- checking the one just written.
#
# Sorted by name rather than mtime: the names are timestamps, and a restored or
# recopied archive would carry a newer mtime while being an older snapshot.
latest_archived() {
    local f newest=""

    for f in "$DEST"/*.sha256; do
        [[ -f "$f" ]] || continue
        local name
        name="$(basename "$f" .sha256)"
        [[ "$name" > "$newest" ]] && newest="$name"
    done

    printf '%s' "$newest"
}

cmd_list() {
    require_mounted

    [[ -d "$DEST" ]] || {
        echo "Nothing archived yet at $DEST"
        return 0
    }

    for f in "$DEST"/*.sha256; do
        [[ -f "$f" ]] || continue
        local name parts size
        name="$(basename "$f" .sha256)"
        parts=$(find "$DEST" -name "$name.part-*" | wc -l)
        size=$(du -shc "$DEST/$name".part-* 2>/dev/null | tail -1 | cut -f1)
        printf '  %-40s %s in %s part(s)\n' "$name" "$size" "$parts"
    done
}

cmd_put() {
    local name="${1:-$(latest_snapshot)}"
    local src="$SNAPSHOT_ROOT/$name"

    [[ -f "$src/MANIFEST" ]] || {
        echo "Not a complete snapshot: $src" >&2
        exit 1
    }

    require_mounted

    info "Archiving $name"
    echo "    from $src"
    echo "    to   $DEST"
    echo ""
    echo "    gpg will ask for a passphrase. Use the one in your password"
    echo "    manager -- it is the only thing that must outlive this disk."

    # -C so the archive holds the snapshot directory rather than an absolute
    # path, which is what lets `get` unpack it anywhere.
    #
    # The sha256 is of the encrypted stream, so it verifies what is actually on
    # the stick rather than what was meant to be written.
    read_passphrase confirm

    # After the passphrase, so a refused prompt leaves nothing behind. An empty
    # directory on the stick looks like an archive that failed halfway.
    mkdir -p "$DEST"

    tar -C "$SNAPSHOT_ROOT" -czf - "$name" \
        | gpg --symmetric --cipher-algo AES256 --batch --yes \
            --pinentry-mode loopback --passphrase-fd 3 3<<< "$PASSPHRASE" \
        | tee >(sha256sum | sed "s|-|$name|" > "$DEST/$name.sha256") \
        | split -b "$PART_SIZE" - "$DEST/$name.part-" || {
            echo "Archive failed; removing partial output." >&2
            rm -f "$DEST/$name".part-* "$DEST/$name.sha256"
            exit 1
        }

    info "Done"
    cmd_list
}

cmd_get() {
    local name="${1:?get needs a snapshot name}"

    require_mounted

    local parts=("$DEST/$name".part-*)
    [[ -e "${parts[0]}" ]] || {
        echo "No archive named $name at $DEST" >&2
        exit 1
    }

    info "Verifying $name"
    cat "${parts[@]}" | sha256sum | sed "s|-|$name|" > /tmp/archive-check.$$
    if ! diff -q /tmp/archive-check.$$ "$DEST/$name.sha256" > /dev/null; then
        rm -f /tmp/archive-check.$$
        echo "Checksum mismatch: the parts on the stick do not match what was written." >&2
        exit 1
    fi
    rm -f /tmp/archive-check.$$
    echo "    checksum matches"

    info "Unpacking to $SNAPSHOT_ROOT/$name"
    mkdir -p "$SNAPSHOT_ROOT"
    read_passphrase

    cat "${parts[@]}" \
        | gpg --decrypt --batch --pinentry-mode loopback --passphrase-fd 3 3<<< "$PASSPHRASE" 2>/dev/null \
        | tar -C "$SNAPSHOT_ROOT" -xzf -

    info "Done"
    echo "    restore it with: $DESKTOP_DIR/restore.sh --dry-run"
}

# Check an archive without unpacking it: the checksum against the bytes on the
# stick, then the passphrase against the archive itself.
#
# This exists because `put` cannot prove its own passphrase was typed correctly
# -- it can only prove the one it was given encrypts. Only a decrypt proves the
# passphrase in the password manager is the one that opens the archive, and
# that is worth knowing before the machine is gone rather than after.
#
# `tar -t` rather than `-x`: the whole stream is still read and every header
# parsed, so a truncated or corrupted archive is caught, but nothing is written
# and there is no temporary copy to remember to delete.
cmd_verify() {
    require_mounted

    local name="${1:-$(latest_archived)}"

    [[ -n "$name" ]] || {
        echo "Nothing archived at $DEST" >&2
        exit 1
    }

    local parts=("$DEST/$name".part-*)

    [[ -e "${parts[0]}" ]] || {
        echo "No archive named $name at $DEST" >&2
        exit 1
    }

    info "Verifying $name"

    local recorded
    recorded="$(awk '{print $1}' "$DEST/$name.sha256" 2> /dev/null || true)"

    if [[ -n "$recorded" ]]; then
        local actual
        actual="$(cat "${parts[@]}" | sha256sum | awk '{print $1}')"

        if [[ "$actual" == "$recorded" ]]; then
            echo "    checksum    ok"
        else
            echo "    checksum    MISMATCH -- the bytes on the disk are not the ones written" >&2
            exit 1
        fi
    else
        echo "    checksum    no .sha256 recorded, skipping" >&2
    fi

    read_passphrase

    if cat "${parts[@]}" \
        | gpg --decrypt --batch --quiet --pinentry-mode loopback \
            --passphrase-fd 3 3<<< "$PASSPHRASE" 2> /dev/null \
        | tar -tz > /dev/null 2>&1; then
        echo "    passphrase  ok"
        echo "    archive     readable end to end"
    else
        echo "    passphrase  WRONG, or the archive is damaged" >&2
        exit 1
    fi

    info "Done"
}

case "${1:-list}" in
    list) cmd_list ;;
    verify) cmd_verify "${2:-}" ;;
    put) cmd_put "${2:-}" ;;
    get) cmd_get "${2:-}" ;;
    --help | -h) sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//' ;;
    *)
        echo "archive.sh: unknown command: $1" >&2
        exit 1
        ;;
esac
