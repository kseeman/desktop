# Pill scripts

The vendored pill shells out to helpers it expects at
`~/.config/hypr/scripts/`. They are part of Ricelin (MIT) but live in its
*hypr* config rather than in `configs/quickshell/pill/`, so the original
vendoring took the QML and left every script behind — the launcher searched
apps fine and opened nothing, because `launch(entry)` always routes through
`launch-guard.sh` and `bash <missing file>` fails silently.

The directory is symlinked to `~/.config/hypr/scripts` by the installer, so a
script added here is live without an installer change. `~/.config/hypr` is
otherwise HyDE's, but it ships no `scripts/` of its own, so nothing is
displaced.

## Present

  - `launch-guard.sh` — verbatim. Runs the app, keeps the first 64K of stderr,
    and toasts exit code plus stderr with a Copy action if it dies non-zero
    within five seconds. Later exits are the user closing the app and stay
    silent. It outlives the app on purpose: a reader that quit at the cap would
    hand the app SIGPIPE on its next log line.

  - `cliphist-thumbs.sh` + `magick-policy/` — verbatim. Builds image
    thumbnails for the clipboard surface and prunes ones whose entry is gone.

    **It is not optional, and that is the trap.** `Cliphist.qml` chains
    `refresh()` to `thumbProc`, and only that process exiting starts
    `cliphist list` — so with the script missing, the picker showed nothing at
    all, text entries included, while `cliphist list` in a terminal returned
    hundreds. Nothing about the symptom points at thumbnails.

    `magick-policy/policy.xml` is a real security control, not configuration:
    clipboard bytes are untrusted input to ImageMagick, so it permits plain
    raster coders and turns off delegates, the MVG/MSL/PS/text family and
    indirect `@file` reads, which are the historical RCE vectors. The script
    points `MAGICK_CONFIGURE_PATH` at it relative to `$0`, so the directory has
    to travel with the script.

## Deliberately absent

Not oversights — each needs a decision rather than a copy:

  - `ricelin-update.py` (28K) and `ricelin` — an updater and CLI for *their*
    install. Wanted here only if this repo wants to be updated by Ricelin,
    which is the opposite of why the pill was copied rather than pinned.
  - `wallpaper.sh`, `wallpaper-search.sh`, `wallpaper-thumbs.sh` — the
    wallpaper picker; blocked on the crop-versus-fit choice for an ultrawide.
  - `wallcolors.py` — regenerates the palette from the wallpaper. This is what
    the theme engine replaces with matugen, so porting it now is work done
    twice.
  - `lock.sh` — this desktop locks with its own hyprlock config; theirs would
    reach for a setup that is not here.
  - `display-apply.sh`, `gamemode.sh`, `minimize-toggle.sh`,
    `special-toggle.sh`, `rec-thumbs.sh` — each drives a surface that has not
    been exercised yet. Port on first use, not before.

The consequence while one is absent is always the same shape: the surface
opens, looks right, and its buttons do nothing.
