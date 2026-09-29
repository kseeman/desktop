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

require("config.general")
require("config.input")
require("config.decoration")
require("config.animations")
require("config.rules")
require("config.workspaces")

require("bindings")

require("config.startup")
