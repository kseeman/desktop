# Vendored: Ricelin's pill

This directory is a verbatim copy of `configs/quickshell/pill/` from
[Ricelin](https://github.com/Gakuseei/Ricelin), MIT licensed — see `LICENSE`,
which is theirs and stays with the code.

    upstream  https://github.com/Gakuseei/Ricelin
    commit    2109754024 18bb5eed60a40b5bc89c006c7d741e
    dated     2026-09-26

## It is copied rather than cloned on purpose

A pinned clone would be easier to update and impossible to edit — a commit bump
would wipe local changes. Copying inverts that: upstream updates become manual,
and the code is free to change. That is the trade this repo wants, because the
design is the reason it is here and the design is expected to drift.

The commit above is recorded only so a future diff against upstream is possible.
Nothing depends on it, and nothing here needs to stay in step with it.

## Local changes

Kept short on purpose: every entry here is a line that has to be re-applied by
hand if this is ever re-copied from upstream.

  - `IdleLock.qml` — `buildConf()` also writes `unlock_cmd` and the two
    `ignore_*_inhibit` settings. It rewrites the whole file, and upstream's
    version omits them, so changing an idle timeout would silently drop them
    from a config that had them.

  - `Singletons/Cliphist.qml` — `listProc.onExited` takes the exit code from
    the signal, `(exitCode, exitStatus) => …`, instead of reading
    `listProc.exitCode` off the object.

    **A version incompatibility, so check this first if another surface goes
    quiet.** Quickshell 0.3.1 declares `exited(int exitCode, int exitStatus)`
    and has no `exitCode` property; upstream targets a newer build where it is
    one. Reading the property yields `undefined`, `undefined !== 0` is true, so
    every *successful* read took the failure branch: `applyList()` never ran,
    the surface showed `0 / 0` with no "History empty" message, and a 2s timer
    retried forever. `cliphist list` in a terminal returned 750 entries
    throughout. This was the only `.exitCode` read in the tree.

  - `Pill.qml` + `shell.qml` — the rest height is 28 where upstream has 38.
    The number is written in both files (`restH` draws it, `restHeight`
    reserves it from tiled windows) and they have to agree, so each carries a
    comment pointing at the other.

  - `Updates.qml` is **deleted**, with its row, loader and `updatesW`/
    `updatesOpen`/`surfaces` entries, and `authPending` with it.

    It drove Ricelin's own updater at `~/.config/hypr/scripts/ricelin-update.py`
    — a script this repo never installs. Its job is to pull upstream over the
    install and three-way-merge the local edits, which is the thing copying
    rather than cloning exists to prevent, so it was never going to be wired up.
    `authPending` existed only to drop the pill's modal grab for that updater's
    pkexec prompt, so `shell.qml`'s `modal` and `keyboardFocus` lost their
    branch on it. `Settings.qml`'s `idleRow` gained `last: true`, which the
    Updates row had been carrying.

  - `Settings.qml` + `GlyphIcon.qml` + `Pill.qml` — a **Wallpaper** row in the
    settings index, third, between Look and Display.

    Upstream ships the wallpaper surface with no way into it: `Wallpaper.qml` is
    complete, `shell.qml` exposes it over IPC, and nothing in the UI calls
    `requestSurface("wallpaper")`. They open it by other means, so the surface
    was unreachable here. The row is the ordinary `kind: "nav"` shape, so it
    needed no new machinery — only the entry, an `image` glyph (the set had no
    picture icon), and `wallpaperOpen` added to `surfaceBack()`'s
    settings-return list so its header behaves like every other sub-surface.

  - `shell.qml` + `Pill.qml` — the bar no longer reacts to `Flags.gameMode`.
    `exclusiveZone` and `implicitHeight` are `reservedH` unconditionally, and
    `"game"` is gone from `Pill.qml`'s `mode` chain (one closing paren with it).

    Upstream shrinks the bar to a 34px sliver in game mode, which makes it
    unusable exactly when a game is running full-screen underneath. Game mode
    here is a compositor change only -- gaps, rounding, blur, shadows,
    animations and transparency -- and the bar is left alone.

    The `mode === "game"` branches further down are left in place and are now
    unreachable. That keeps the diff to four lines and makes restoring the
    upstream behaviour a matter of putting the condition back.

  - `shell.qml` — the keep-awake inhibitor runs under
    `setpriv --pdeathsig=TERM`.

    **A blocking sleep inhibitor that outlives the bar makes `systemctl
    suspend` silently do nothing**, which takes the bar's own sleep button with
    it. Three had accumulated here from pill restarts, with `keepAwake` long
    since off, and sleep had simply stopped working with no error anywhere.

    Quickshell stopping the `Process` is not enough: the child was reparented
    and kept running. The death signal is what makes it hold however the bar
    goes away, including a crash. `setpriv` is util-linux, so it is always
    present.

  - `Pill.qml` — the body's drop shadow is off (`layer.enabled: false` where
    upstream has `!pill.morphing` and a `MultiEffect`). Upstream draws a
    0.7-blur shadow at 50% black offset 3px down, which reads as a halo pooling
    under the bar. Disabling the layer rather than only `shadowEnabled` also
    drops the offscreen buffer, which by upstream's own comment is the top
    per-frame cost of a morph.

## What else is ours

Nothing else in this directory. The seam is elsewhere:

  - colours arrive as `$XDG_CACHE_HOME/ricelin/colors.json`, which `Dyn.qml`
    watches and hot-reloads. That file is generated from this repo's palette,
    which is how their design wears a different scheme without an edit here.
  - `Theme.qml` takes the dynamic branch only while `Flags.paletteMode` is not
    "static", so that flag has to stay off the curated vermilion identity.

Edit these files freely. They are no longer upstream's in any sense that
matters; they are a starting point that happens to have been written elsewhere.
