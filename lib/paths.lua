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

--- Absolute path to something inside the desktop directory.
--- @param rel string path relative to os/linux/desktop
--- @return string
function M.desktop_file(rel)
    return M.desktop .. rel
end

return M
