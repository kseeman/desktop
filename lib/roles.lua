-- -----------------------------------------------------------------------------
-- Roles
-- -----------------------------------------------------------------------------
--
-- A role is a job the desktop needs doing -- launcher, lock, notifications. A
-- provider is something that does it. This file says which provider currently
-- holds each role, and it is the only place that says so.
--
-- The point is that nothing else names a component. A binding asks for the
-- launcher, not for quickshell; startup starts whatever is active, not a list
-- of programs. Swapping the launcher is then an edit here rather than an edit
-- everywhere a command was written out -- which is what bindings/launchers.lua
-- looked like one commit ago, and what every new binding would have looked
-- like.
--
-- A provider is a plain table and should stay one: which roles it fills, how to
-- start it if it is long-running, and the command for each role something binds
-- a key to. No lifecycle hooks, no registration order, nothing to debug at
-- login. Anything more and this becomes the part that gets maintained instead
-- of the desktop.
--
-- One provider may fill several roles -- the pill fills nine -- so starting is
-- deduplicated by provider, not by role.
local rice = require("lib.rice")

local M = {}

-- Which provider holds each role.
--
-- This table is what a rice will eventually set, rather than being edited by
-- hand. Until then it is the whole configuration: every value is a filename in
-- providers/.
local DEFAULT = {
    bar = "pill",
    launcher = "pill",
    clipboard = "pill",
    notifications = "pill",
    wallpaper = "pill",
    tray = "pill",
    media = "pill",
    audio = "pill",

    -- Stripping the desktop for a game is a whole-desktop state, so it is a
    -- role rather than a binding that knows about the bar: swapping the bar
    -- means the replacement answers for this too.
    gamemode = "pill",

    lock = "hyprlock",

    -- The pill offers one too; this is what the key has always opened.
    power = "wlogout",
}

-- The active rice overrides whichever roles it names and leaves the rest, so a
-- rice that only changes the launcher says only that.
local ACTIVE = setmetatable(rice.providers, { __index = DEFAULT })

local cache = {}

local function provider(name)
    if not cache[name] then
        cache[name] = require("providers." .. name)
    end

    return cache[name]
end

--- The provider currently holding a role.
--- @param role string
--- @return table
local function holder(role)
    local name = ACTIVE[role]

    -- Raised rather than tolerated, because verify-config.sh runs this file and
    -- the installer refuses a config that fails -- so a typo here is caught
    -- before a login instead of at one. That is the opposite of the palette,
    -- which falls back: a palette is generated data that can be half-written,
    -- while this is repo code with a checker in front of it.
    if not name then
        error("no provider for role '" .. tostring(role) .. "'")
    end

    return provider(name)
end

--- The command that invokes whatever currently fills a role.
---
--- Separate from action() because a shell caller wants the string, not a
--- dispatcher -- quickshell/scripts/lock.sh asks for this so that hypridle and
--- the bar's power menu both reach whichever lock screen is active.
--- @param role string
--- @return string
function M.action_command(role)
    local p = holder(role)
    local cmd = p.actions and p.actions[role]

    if not cmd then
        error("provider '" .. p.name .. "' fills '" .. role .. "' but offers no action for it")
    end

    return cmd
end

--- A dispatcher for hl.bind that invokes whatever currently fills the role.
--- @param role string
--- @return table dispatcher
function M.action(role)
    return hl.dsp.exec_cmd(M.action_command(role))
end

--- Every active provider, each once, in a stable order.
--- @return table[]
local function active_providers()
    local seen = {}
    local out = {}

    -- Sorted so the order does not follow pairs() iteration, which would make
    -- the autostart sequence change between runs for no reason.
    -- Iterating DEFAULT rather than ACTIVE: ACTIVE inherits through a
    -- metatable, and pairs() does not see inherited keys -- so a rice naming
    -- only one role would otherwise shrink the desktop to that one role.
    local names = {}
    for role in pairs(DEFAULT) do
        names[#names + 1] = role
    end
    table.sort(names)

    for _, role in ipairs(names) do
        local p = holder(role)

        if not seen[p.name] then
            seen[p.name] = true
            out[#out + 1] = p
        end
    end

    return out
end

--- Templates declared by active providers, for render-theme.lua.
---
--- Only the active ones: a provider nothing uses should not have its config
--- regenerated, and an inactive one may reference palette names that no longer
--- exist.
--- @return table[] each { src = string, out = string }
function M.templates()
    local out = {}

    for _, p in ipairs(active_providers()) do
        for _, t in ipairs(p.templates or {}) do
            out[#out + 1] = t
        end
    end

    return out
end

--- Start commands for every active provider that is long-running, each once.
--- @return string[]
function M.start_commands()
    local out = {}

    for _, p in ipairs(active_providers()) do
        if p.start then
            out[#out + 1] = p.start
        end
    end

    return out
end

return M
