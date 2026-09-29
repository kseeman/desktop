-- -----------------------------------------------------------------------------
-- Paths
-- -----------------------------------------------------------------------------
--
-- Where this desktop lives, worked out from where this file lives.
--
-- Everything here used to say $HOME/.dotfiles, which is a symlink to the main
-- checkout -- so a config loaded from a worktree still started the *main*
-- checkout's bar, lock and launcher. Nested testing of a branch silently tested
-- main instead, which is how two bars ended up stacked on one screen.
--
-- Deriving it instead makes a checkout self-contained: the config that is
-- running is the one whose parts get used. init.lua already does this for
-- package.path; this is the same trick, kept in one place so consumers do not
-- each reimplement a walk up the tree.
local M = {}

-- <desktop>/lib/paths.lua -> <desktop>/
local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"

M.desktop = here:gsub("lib/$", "")

-- Where render-theme.lua writes the configs it generates from the palette.
--
-- A cache rather than config, because every file under it is derived and
-- rebuilt on demand: losing it costs one render. It is also why nothing
-- generated is tracked -- a hand-edit there is overwritten by the next theme
-- change, which is the intended contract.
local cache = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")

M.theme = cache .. "/dotfiles/theme/"

--- Absolute path to something inside the desktop directory.
--- @param rel string path relative to os/linux/desktop
--- @return string
function M.desktop_file(rel)
    return M.desktop .. rel
end

return M
