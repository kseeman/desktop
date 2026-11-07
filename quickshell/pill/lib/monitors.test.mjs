import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { parse, setMonitor, setWorkspaceLoops } = require("./monitors.js");

let failed = 0;
function eq(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a === e) console.log("PASS " + msg);
    else { failed++; console.log("FAIL " + msg + "\n  expected " + e + "\n  got      " + a); }
}
function ok(cond, msg) { eq(!!cond, true, msg); }

const lua = `hl.monitor({
    output   = "DP-1",
    mode     = "2560x1440@280",
    position = "2560x0",
    scale    = 1,
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "2560x1440@144",
    position = "0x0",
    scale    = 1,
})

for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1" })
end

for i = 6, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1" })
end
`;

const moved = setMonitor(lua, "DP-1", "1920x1080@60", "0x0", 1.25);
ok(moved.ok, "setMonitor rewrites existing block");
ok(moved.text.includes('mode     = "1920x1080@60"'), "mode replaced");
ok(moved.text.includes('position = "0x0"'), "position replaced");
ok(moved.text.includes("scale    = 1.25"), "scale replaced");
ok(moved.text.includes('output   = "HDMI-A-1"'), "other block untouched");

const appended = setMonitor(lua, "DP-3", "2560x1440@280", "2560x0", 1);
ok(appended.ok, "setMonitor appends unknown output");
ok(appended.text.includes('output   = "DP-3"'), "new block carries the output");
ok(appended.text.indexOf('output   = "DP-3"') > appended.text.indexOf("for i = 6, 10"), "block lands after the loops");
ok(appended.text.includes('output   = "DP-1"'), "stale block left intact");

const loops = setWorkspaceLoops(lua, "DP-3", "HDMI-A-1");
ok(loops.ok, "setWorkspaceLoops accepts the two loops");
eq(loops.mainRange, [1, 5], "main range follows the workspace-1 loop");
eq(loops.otherRange, [6, 10], "other range");
ok(loops.text.includes('monitor = "DP-3" })\nend\n\nfor i = 6, 10'), "workspace-1 loop points at the new main");
ok(loops.text.includes('monitor = "HDMI-A-1" })\nend'), "second loop points at the other real output");
ok(!loops.text.includes('monitor = "DP-1"'), "stale name purged from loops");

const swappedBack = setWorkspaceLoops(loops.text, "HDMI-A-1", "DP-3");
ok(swappedBack.ok, "swap is reversible");
ok(swappedBack.text.includes('monitor = "HDMI-A-1" })\nend\n\nfor i = 6, 10'), "workspace-1 loop back on HDMI");

const noLoops = setWorkspaceLoops("hl.monitor({ output = \"DP-1\" })\n", "A", "B");
ok(!noLoops.ok, "missing loops report failure");

// The shape this desktop actually persists into: local.lua holds the monitor
// blocks and workspace loops alongside env/config blocks the rewriters must
// never touch, plus a bare workspace_rule outside any loop (a third monitor's
// workspace), which the loop regex must not count.
const localLua = `hl.monitor({
    output = "DP-1",
    mode = "5120x1440@239.76",
    position = "520x3255",
    scale = 1.0,
})

hl.env("LIBVA_DRIVER_NAME", "nvidia")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

for id = 1, 7 do
    hl.workspace_rule({ workspace = tostring(id), monitor = "DP-1", default = id == 1 })
end

for id = 8, 9 do
    hl.workspace_rule({ workspace = tostring(id), monitor = "DP-2", default = id == 8 })
end

hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-1", default = true })
`;

const localSet = setMonitor(localLua, "DP-1", "5120x1440@120", "0x0", 1);
ok(localSet.ok, "local.lua: monitor block rewritten");
ok(localSet.text.includes('mode = "5120x1440@120"'), "local.lua: mode replaced in place");
ok(localSet.text.includes("no_hardware_cursors = true"), "local.lua: hl.config block untouched");
ok(localSet.text.includes('hl.env("LIBVA_DRIVER_NAME", "nvidia")'), "local.lua: hl.env untouched");

const localLoops = setWorkspaceLoops(localLua, "DP-2", "DP-1");
ok(localLoops.ok, "local.lua: bare workspace_rule does not count as a loop");
eq(localLoops.mainRange, [1, 7], "local.lua: main range follows workspace 1");
eq(localLoops.otherRange, [8, 9], "local.lua: other range");
ok(localLoops.text.includes('{ workspace = "10", monitor = "HDMI-A-1", default = true }'),
    "local.lua: bare rule keeps its monitor");

const parsed = parse(JSON.stringify([{
    name: "DP-3", width: 2560, height: 1440, refreshRate: 279.96, scale: 1, x: 0, y: 0,
    availableModes: ["2560x1440@279.96Hz", "bogus"]
}]));
eq(parsed.length, 1, "parse keeps the monitor");
eq(parsed[0].refresh, 280, "refresh rounds like mode hz");
eq(parsed[0].modes.length, 1, "unparseable modes drop out");

process.exit(failed === 0 ? 0 : 1);
