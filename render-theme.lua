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
local look = require("lib.look")

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
    -- KDE colour schemes take decimal triples, not hex.
    [":rgb"] = function(hex)
        local h = hex:gsub("^#", "")
        return ("%d,%d,%d"):format(
            tonumber(h:sub(1, 2), 16),
            tonumber(h:sub(3, 4), 16),
            tonumber(h:sub(5, 6), 16)
        )
    end,
}

-- Not every substitution is a colour. The icon theme is a look knob a rice
-- names, and it belongs in the same generated files as the colours -- kdeglobals
-- carries both -- so it resolves here rather than through a second mechanism.
--
-- Only names the palette does not define are looked up here, so a colour can
-- never be shadowed by one of these.
local LOOK = {
    icon_theme = look.icon_theme,
}

-- Substitution is textual and applies to the whole file, comments included, so
-- a template cannot document its own syntax by spelling a token out.
local function substitute(text, source)
    local missing = {}

    local rendered = text:gsub("@([%w_]+)(:?%a*)@", function(name, form)
        local value = palette[name]

        if type(value) ~= "string" then
            local plain = LOOK[name]

            -- A look value is text, so the colour forms do not apply to it.
            if type(plain) == "string" then
                if form ~= "" then
                    missing[#missing + 1] = name .. form .. " (not a colour)"
                    return ""
                end

                return plain
            end
        end

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

-- Merge rendered `[Section] key=value` pairs into an existing ini, leaving every
-- other key and section alone.
--
-- Needed because kdeglobals, kvantum.kvconfig and the qt*ct configs are live
-- files the applications write to themselves -- file-dialog geometry, wallet
-- settings, whatever Kvantum Manager last did. Generating them whole would take
-- those with it on every render, which is the write-through hazard hypridle.conf
-- already taught this repo once.
--
-- Deliberately dumb: no type awareness, no comment preservation beyond passing
-- lines through untouched. These are ini files written by Qt, not by hand.
-- Sorted, so a fresh machine writes the same file twice rather than following
-- pairs() iteration -- the same reason active_providers() sorts.
local function sorted_keys(tb)
    local keys = {}
    for k in pairs(tb) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function merge_ini(path, text)
    local wanted = {}
    local order = {}
    local section

    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local name = line:match("^%s*%[([^%]]+)%]%s*$")

        if name then
            section = name
            if not wanted[section] then
                wanted[section] = {}
                order[#order + 1] = section
            end
        elseif section then
            local k, v = line:match("^%s*([^=%s]+)%s*=%s*(.*)$")
            if k then
                wanted[section][k] = v
            end
        end
    end

    local out = {}
    local seen = {}
    local current

    local existing = io.open(path, "r")

    if existing then
        for line in existing:lines() do
            local name = line:match("^%s*%[([^%]]+)%]%s*$")

            if name then
                -- Flush any keys this section should have but did not.
                if current and wanted[current] then
                    for _, k in ipairs(sorted_keys(wanted[current])) do
                        if not seen[current .. "\0" .. k] then
                            out[#out + 1] = k .. "=" .. wanted[current][k]
                        end
                    end
                end

                current = name
                seen[current] = true
                out[#out + 1] = line
            else
                local k = line:match("^%s*([^=%s]+)%s*=")
                local replacement = k and current and wanted[current] and wanted[current][k]

                if replacement then
                    out[#out + 1] = k .. "=" .. replacement
                    seen[current .. "\0" .. k] = true
                else
                    out[#out + 1] = line
                end
            end
        end

        existing:close()

        if current and wanted[current] then
            for _, k in ipairs(sorted_keys(wanted[current])) do
                if not seen[current .. "\0" .. k] then
                    out[#out + 1] = k .. "=" .. wanted[current][k]
                end
            end
        end
    end

    -- Sections the file did not have at all.
    for _, name in ipairs(order) do
        if not seen[name] then
            out[#out + 1] = ""
            out[#out + 1] = "[" .. name .. "]"
            for _, k in ipairs(sorted_keys(wanted[name])) do
                out[#out + 1] = k .. "=" .. wanted[name][k]
            end
        end
    end

    write(path, table.concat(out, "\n") .. "\n")
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
    -- $HOME rather than $THEME_DIR, and that is kitty's constraint rather than
    -- a preference. It cannot express ${VAR:-default}, and it errors on a file
    -- included twice -- so naming both the default and the XDG location, the
    -- way tmux.conf does, puts a dialog in front of every new terminal. One
    -- include can therefore only say $HOME, and this has to match it.
    { src = "kitty.conf.in", out = "$HOME/.cache/dotfiles/theme/kitty.conf" },
    -- nvim resolves XDG itself, so unlike kitty this one stays under
    -- $THEME_DIR. Read by nvim/lua/themes/rice.lua, which owns the mapping
    -- onto base46's names.
    { src = "nvim.lua.in", out = "$THEME_DIR/nvim.lua" },

    -- Qt, in four parts, because Qt theming is in four places.
    --
    -- Kvantum draws the widgets and takes its colours from its own theme rather
    -- than from any palette, which is why recolouring it is unavoidable: with
    -- the theme left alone, every colour below is overruled on screen.
    { src = "qt/kvantum-theme.kvconfig.in", out = "$XDG_CONFIG_HOME/Kvantum/rice/rice.kvconfig" },
    { src = "qt/kvantum-theme.svg.in", out = "$XDG_CONFIG_HOME/Kvantum/rice/rice.svg" },
    { src = "qt/kvantum.kvconfig.in", out = "$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig", merge = true },

    -- KDE applications (Dolphin, Ark, Gwenview) read kdeglobals and ignore the
    -- qt*ct palette entirely.
    { src = "qt/kdeglobals.in", out = "$XDG_CONFIG_HOME/kdeglobals", merge = true },

    -- Non-KDE Qt applications read qt5ct/qt6ct instead. One scheme serves both.
    { src = "qt/qtct-colors.conf.in", out = "$XDG_CONFIG_HOME/qt-color-schemes/rice.conf" },
    { src = "qt/qtct.conf.in", out = "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf", merge = true },
    { src = "qt/qtct.conf.in", out = "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf", merge = true },
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

    if template.merge then
        merge_ini(out, substitute(text, template.src))
    else
        write(out, substitute(text, template.src))
    end

    count = count + 1

    if verbose then
        print(template.src .. " -> " .. out)
    end
end

if verbose then
    print(count .. " file" .. (count == 1 and "" or "s") .. " rendered")
end
