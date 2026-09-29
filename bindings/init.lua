-- -----------------------------------------------------------------------------
-- Keybindings
-- -----------------------------------------------------------------------------
--
-- Split by what a binding is for rather than by which key it uses, so adding
-- one means opening the file named after the thing it does.
--
-- Every binding carries a `desc`. That is not documentation: `hyprctl binds`
-- reports a Lua dispatcher as an opaque registry index, so the description is
-- the only readable record of what a key does -- exactly the constraint tmux
-- has, where `list-keys -N` shows only bindings with a note and one added
-- without is silently missing from the search.
require("bindings.apps")
require("bindings.windows")
require("bindings.workspaces")
require("bindings.launchers")
require("bindings.screenshot")
require("bindings.media")
require("bindings.session")
