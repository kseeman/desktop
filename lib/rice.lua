-- -----------------------------------------------------------------------------
-- Rice
-- -----------------------------------------------------------------------------
--
-- Which look is active, and what it says.
--
-- A rice is a directory under rices/ holding a palette and a rice.lua that
-- names which provider fills each role and the non-colour knobs -- gaps,
-- rounding, blur, motion. Everything a look is, in other words, apart from the
-- machine it runs on.
--
-- Which one is active lives in a state file rather than in the repo, so a
-- machine can wear a different look without a commit and without the choice
-- following a push to another machine.
--
-- **Nothing here is fatal.** A missing state file, a name that no longer
-- matches a directory, a rice.lua with a syntax error -- each falls back and
-- says so, because this is mutable runtime state that a switch can leave
-- half-written. That is the opposite of lib/roles.lua, which raises: the roles
-- table is repo code with verify-config.sh in front of it, while this is a file
-- a command wrote thirty seconds ago.
local paths = require("lib.paths")

local M = {}

local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")

M.state_file = state_home .. "/dotfiles/rice"

M.dir = paths.desktop_file("rices/")

--- The rice used when the state file is missing or names something unusable.
M.DEFAULT = "violet"

--- Problems hit while resolving, for callers that can surface them.
--- Collected rather than printed: this module is loaded during config parsing,
--- where there is no session to notify yet.
M.warnings = {}

local function warn(message)
    M.warnings[#M.warnings + 1] = message
end

local function read_state()
    local f = io.open(M.state_file, "r")

    if not f then
        return nil
    end

    local name = f:read("l")
    f:close()

    -- Trimmed, because the file is written by a shell command and a stray
    -- newline or space would turn a good name into a missing directory.
    return name and name:match("^%s*(.-)%s*$")
end

local function load_file(name, file)
    local path = M.dir .. name .. "/" .. file
    local ok, result = pcall(dofile, path)

    if not ok then
        -- "cannot open" is absence, which is allowed: a rice may carry only a
        -- palette, or only provider choices. Anything else is a broken file and
        -- worth saying out loud.
        if not tostring(result):match("cannot open") then
            warn(file .. " in rice '" .. name .. "': " .. tostring(result))
        end

        return nil
    end

    if type(result) ~= "table" then
        warn(file .. " in rice '" .. name .. "' did not return a table")
        return nil
    end

    return result
end

--- @return boolean
local function exists(name)
    -- A rice is a directory, and the only portable way to ask is to try to open
    -- something inside it. Either file is enough to count as present.
    for _, file in ipairs({ "rice.lua", "palette.lua" }) do
        local f = io.open(M.dir .. name .. "/" .. file, "r")

        if f then
            f:close()
            return true
        end
    end

    return false
end

local requested = read_state()

if requested and not exists(requested) then
    warn("rice '" .. requested .. "' is not in " .. M.dir .. ", using '" .. M.DEFAULT .. "'")
    requested = nil
end

--- The rice in force.
M.name = requested or M.DEFAULT

local definition = load_file(M.name, "rice.lua") or {}

--- Colours, or nil to leave the palette on its fallback floor.
M.palette = load_file(M.name, "palette.lua")

--- Role to provider name. Partial: roles the rice does not mention keep the
--- default provider, so a rice that only changes the launcher says only that.
M.providers = definition.providers or {}

--- Non-colour knobs -- gaps, rounding, blur, motion. Partial in the same way.
M.look = definition.look or {}

--- One line for a listing.
M.description = definition.description or ""

return M
