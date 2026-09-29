-- Workspaces.
local mod = "SUPER"

-- 0 is workspace 10, which is why this counts to 10 and takes the key modulo.
for i = 1, 10 do
    local key = i % 10

    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { desc = "workspace " .. i })

    hl.bind(
        mod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i }),
        { desc = "move to workspace " .. i }
    )
end

-- Relative movement. "r" is relative within the monitor rather than across all
-- of them, so this walks 1-7 on the ultrawide without falling onto the 4K.
hl.bind(mod .. " + CONTROL + right", hl.dsp.focus({ workspace = "r+1" }), { desc = "workspace: next" })
hl.bind(mod .. " + CONTROL + left", hl.dsp.focus({ workspace = "r-1" }), { desc = "workspace: previous" })
hl.bind(mod .. " + CONTROL + down", hl.dsp.focus({ workspace = "empty" }), { desc = "workspace: first empty" })
