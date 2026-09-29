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

  - `Pill.qml` + `shell.qml` — the rest height is 28 where upstream has 38.
    The number is written in both files (`restH` draws it, `restHeight`
    reserves it from tiled windows) and they have to agree, so each carries a
    comment pointing at the other.

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
