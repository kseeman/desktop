-- -----------------------------------------------------------------------------
-- Hyprland configuration
-- -----------------------------------------------------------------------------
--
-- Entry point for the Lua-native desktop that replaces HyDE. Hyprland 0.56+
-- reads Lua directly; the `hl` API is documented by the LuaLS stub Hyprland
-- ships at /usr/share/hypr/stubs/hl.meta.lua, so pointing lua_ls at that
-- directory gives this file completion and type checking.
--
-- Selected by the "Hyprland (dotfiles)" session entry, which passes this path
-- with --config. It is deliberately NOT installed at $XDG_CONFIG_HOME/hypr/
-- hyprland.lua: Hyprland prefers hyprland.lua over hyprland.conf, so a file
-- there would silently take the session away from HyDE while it is still the
-- default.
--
-- Verify before logging in -- os/linux/desktop/verify-config.sh does this, and
-- the installer refuses to link a config that fails:
--
--   Hyprland --verify-config -c os/linux/desktop/init.lua
--
-- One rule this file and everything it requires must keep: no exec at the top
-- level. Verifying a config runs it, so a top-level hl.exec_cmd launches the
-- application every time the config is checked. Execs belong in
-- hl.on("hyprland.start", ...), which does not run under --verify-config.

-- Modules resolve relative to this file rather than the working directory,
-- which is wherever the compositor happened to be started from.
local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = here .. "?.lua;" .. here .. "?/init.lua;" .. package.path

require("config.env")
require("config.general")
require("config.input")
require("config.decoration")
require("config.animations")
require("config.misc")
require("config.rules")
require("config.workspaces")

require("bindings")

require("config.startup")

-- -----------------------------------------------------------------------------
-- Rice warnings
-- -----------------------------------------------------------------------------

-- Anything lib/rice.lua had to work around -- a name that no longer matches a
-- directory, a rice.lua that does not parse. It falls back rather than failing,
-- which is right for runtime state a switch can leave half-written, but a
-- silent fallback is how you end up wondering why a look did not change.
--
-- Raised here rather than there because that module is loaded while the config
-- is still parsing, when there is no session to notify yet.
local rice = require("lib.rice")

for _, warning in ipairs(rice.warnings) do
    hl.notification.create({
        text = "rice: " .. warning,
        timeout = 10000,
    })
end

-- -----------------------------------------------------------------------------
-- Machine-local configuration
-- -----------------------------------------------------------------------------

-- Loaded last so it outranks everything above, and optional so a machine
-- without one is not an error -- the same arrangement as
-- ~/.config/dotfiles/nvim/local.lua and ~/.config/dotfiles/zsh/local.zsh.
--
-- This is where a machine describes itself, and it is not a convenience:
-- monitors are the obvious case. hl.monitor() names physical outputs, which
-- differ per machine and are rewritten by nwg-displays whenever displays are
-- rearranged, so they are excluded from this repo for the same reason
-- monitors.conf and nvidia.conf are. Without this hook there would be nowhere
-- for them to go, and the session would come up on whatever Hyprland guesses.
--
-- Hardware environment belongs here too: NVIDIA driver selection, VA-API
-- backends, anything describing one graphics stack.
--
--   -- ~/.config/dotfiles/hypr/local.lua
--   hl.monitor({ output = "DP-1", mode = "5120x1440@239.76", position = "auto", scale = 1 })
--   hl.env("LIBVA_DRIVER_NAME", "nvidia")
--
-- pcall rather than a file check: a local config that throws should say so and
-- leave the rest of the session standing, not take the login down with it.
local xdg_config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local user_config = xdg_config .. "/dotfiles/hypr/local.lua"

local ok, err = pcall(dofile, user_config)

if not ok and not tostring(err):match("cannot open") then
    hl.notification.create({
        text = "local.lua: " .. tostring(err),
        timeout = 10000,
    })
end
