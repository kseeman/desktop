#!/usr/bin/env lua
-- -----------------------------------------------------------------------------
-- render-theme.lua
-- -----------------------------------------------------------------------------
--
-- Generates every config that needs a colour in it, from lib/palette.lua.
--
-- Some consumers cannot read Lua. hyprlock parses hyprlang, wlogout parses CSS,
-- the bar reads JSON -- so before this existed each carried the palette values
-- typed out a second time, with a comment promising they would be generated
-- one day. That works while there is one palette and silently keeps the old
-- colours the moment there are two.
--
-- What it renders is not a fixed list: it asks lib/roles.lua for the *active*
-- providers and renders the templates they declare. Swap the launcher and its
-- template stops being rendered along with it, without an edit here.
--
--   render-theme.lua            render, quietly
--   render-theme.lua --verbose  say what was written
--
-- Run by the installer and again at session start, so a palette edit reaches
-- every consumer on the next login without running the installer. It is
-- idempotent and takes milliseconds.
--
-- Output goes to $XDG_CACHE_HOME/dotfiles/theme/. Generated, disposable, and
-- deliberately untracked: a hand-edit there is overwritten by the next render,
-- which is the contract that keeps the palette the single source.

local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = here .. "?.lua;" .. here .. "?/init.lua;" .. package.path

-- roles.lua builds dispatchers through hl.dsp for the bindings; nothing in the
-- rendering path needs them, but requiring the module evaluates those calls. A
-- stub keeps this runnable under plain lua, outside the compositor.
if not hl then
    hl = { dsp = { exec_cmd = function(c) return c end, exit = function() end } }
end

local palette = require("lib.palette")
local paths = require("lib.paths")
local roles = require("lib.roles")

local verbose = false
for _, a in ipairs(arg or {}) do
    if a == "--verbose" or a == "-v" then
        verbose = true
    end
end

-- -----------------------------------------------------------------------------
-- Substitution
-- -----------------------------------------------------------------------------

-- @name@ is the palette value as CSS hex, @name:bare@ the same without the
-- leading #, which is what hyprlang wants inside rgba(). Two forms rather than
-- one per consumer: a template stays readable as the file it is going to be.
local FORMS = {
    [""] = function(hex)
        return hex
    end,
    [":bare"] = function(hex)
        return (hex:gsub("^#", ""))
    end,
}

-- Substitution is textual and applies to the whole file, comments included, so
-- a template cannot document its own syntax by spelling a token out.
local function substitute(text, source)
    local missing = {}

    local rendered = text:gsub("@([%w_]+)(:?%a*)@", function(name, form)
        local value = palette[name]

        -- Unknown names are fatal rather than left in place. A stray @accnet@
        -- would otherwise reach hyprlock as a literal and fail at a lock
        -- screen, which is the worst place to find a typo.
        if type(value) ~= "string" then
            missing[#missing + 1] = name
            return ""
        end

        local fmt = FORMS[form]

        if not fmt then
            missing[#missing + 1] = name .. form .. " (unknown form '" .. form .. "')"
            return ""
        end

        return fmt(value)
    end)

    if #missing > 0 then
        error(source .. ": no palette value for: " .. table.concat(missing, ", "), 0)
    end

    return rendered
end

-- -----------------------------------------------------------------------------
-- Paths
-- -----------------------------------------------------------------------------

local ENV = {
    THEME_DIR = paths.theme,
    XDG_CACHE_HOME = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache"),
    XDG_CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config"),
    HOME = os.getenv("HOME"),
}

-- Duplicate slashes are collapsed because $THEME_DIR already ends in one and a
-- template reads better written as "$THEME_DIR/name".
local function expand(path)
    local expanded = path:gsub("%$([%w_]+)", function(name)
        local value = ENV[name]

        if not value then
            error("unknown variable $" .. name .. " in output path", 0)
        end

        return value
    end)

    return (expanded:gsub("//+", "/"))
end

local function write(path, text)
    local dir = path:match("^(.*)/[^/]*$")

    if dir then
        os.execute("mkdir -p '" .. dir .. "'")
    end

    local f = assert(io.open(path, "w"))
    f:write(text)
    f:close()
end

-- -----------------------------------------------------------------------------
-- Render
-- -----------------------------------------------------------------------------

-- Consumers that are not swappable components.
--
-- lib/roles.lua answers for anything a rice can swap -- a launcher, a lock
-- screen. tmux is not one of those: it is always tmux, there is no role for it
-- to fill and no provider to declare it. Rendering it from a role would mean
-- inventing a component system for something that has exactly one
-- implementation.
local BASE = {
    { src = "tmux.conf.in", out = "$THEME_DIR/tmux.conf" },
}

local templates = {}

for _, t in ipairs(BASE) do
    templates[#templates + 1] = t
end

for _, t in ipairs(roles.templates()) do
    templates[#templates + 1] = t
end

local count = 0

for _, template in ipairs(templates) do
    local src = paths.desktop_file(template.src)
    local out = expand(template.out)

    local f = assert(io.open(src, "r"), "missing template: " .. src)
    local text = f:read("a")
    f:close()

    write(out, substitute(text, template.src))

    count = count + 1

    if verbose then
        print(template.src .. " -> " .. out)
    end
end

if verbose then
    print(count .. " file" .. (count == 1 and "" or "s") .. " rendered")
end
