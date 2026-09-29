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
local M = {}

-- Which provider holds each role.
--
-- This table is what a rice will eventually set, rather than being edited by
-- hand. Until then it is the whole configuration: every value is a filename in
-- providers/.
local ACTIVE = {
    bar = "pill",
    launcher = "pill",
    clipboard = "pill",
    notifications = "pill",
    wallpaper = "pill",
    tray = "pill",
    media = "pill",
    audio = "pill",

    lock = "hyprlock",

    -- The pill offers one too; this is what the key has always opened.
    power = "wlogout",
}

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

--- A dispatcher for hl.bind that invokes whatever currently fills the role.
--- @param role string
--- @return table dispatcher
function M.action(role)
    local p = holder(role)
    local cmd = p.actions and p.actions[role]

    if not cmd then
        error("provider '" .. p.name .. "' fills '" .. role .. "' but offers no action for it")
    end

    return hl.dsp.exec_cmd(cmd)
end

--- Start commands for every active provider that is long-running, each once.
--- @return string[]
function M.start_commands()
    local seen = {}
    local out = {}

    -- Sorted so the order does not follow pairs() iteration, which would make
    -- the autostart sequence change between runs for no reason.
    local roles = {}
    for role in pairs(ACTIVE) do
        roles[#roles + 1] = role
    end
    table.sort(roles)

    for _, role in ipairs(roles) do
        local p = holder(role)

        if p.start and not seen[p.name] then
            seen[p.name] = true
            out[#out + 1] = p.start
        end
    end

    return out
end

return M
