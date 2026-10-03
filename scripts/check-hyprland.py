"""Validate Lua configuration and behavior parity without activating a session."""

import collections
import json
import os
import pathlib
import re
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[1]
backup = root / ".git/hyprland-lua-migration"
old = json.loads((backup / "legacy-settings.json").read_text())
query = """cfg: let hm = cfg.home-manager.users.nrm; in {
  type = hm.wayland.windowManager.hyprland.configType;
  settings = hm.wayland.windowManager.hyprland.settings;
  text = hm.xdg.configFile."hypr/hyprland.lua".text;
  files = builtins.attrNames hm.xdg.configFile;
  hyprland = toString hm.wayland.windowManager.hyprland.finalPackage;
  noctalia = toString hm.programs.noctalia-shell.package;
  idle = hm.services.hypridle.settings;
}"""
data = json.loads(
    subprocess.check_output(
        [
            "nix",
            "eval",
            "--no-write-lock-file",
            "--json",
            ".#nixosConfigurations.hp-ara.config",
            "--apply",
            query,
        ],
        cwd=root,
        text=True,
    )
)
lua = (
    subprocess.check_output(
        [
            "nix",
            "eval",
            "--no-write-lock-file",
            "--raw",
            ".#nixosConfigurations.hp-ara.pkgs.lua5_5.outPath",
        ],
        cwd=root,
        text=True,
    ).strip()
    + "/bin/lua"
)
assert data["type"] == "lua" and "hypr/hyprland.conf" not in data["files"]
expected_config = {k: old[k] for k in ("general", "decoration", "input")}
expected_config["input"]["touchpad"]["tap_to_click"] = expected_config["input"][
    "touchpad"
].pop("tap-to-click")
assert data["settings"]["config"] == expected_config
assert data["settings"]["monitor"] == {
    "output": "",
    "mode": "preferred",
    "position": "auto",
    "scale": 1,
}
assert data["settings"]["gesture"] == {
    "fingers": 3,
    "direction": "horizontal",
    "action": "workspace",
}
assert data["settings"]["window_rule"] == [
    {"match": {"class": "org.pulseaudio.pavucontrol"}, "float": True},
    {"match": {"fullscreen": True}, "border_color": "rgb(FF0000) rgb(880808)"},
]

# Stubs only capture registrations. Actions, commands, and shutdown are never executed.
harness = r"""
local function emit(...)
  local fields = {...}
  for i, v in ipairs(fields) do fields[i] = string.format("%q", tostring(v)) end
  print("[" .. table.concat(fields, ",") .. "]")
end
local function action(name, arg) return {name = name, arg = tostring(arg or "")} end
local dirs = {left = "l", right = "r", up = "u", down = "d"}
local starts, stops = {}, {}
hl = {
  config = function() end,
  monitor = function() end,
  window_rule = function() end,
  gesture = function() end,
  env = function(k, v) emit("env", k, v) end,
  on = function(event, callback)
    if event == "hyprland.start" then table.insert(starts, callback)
    elseif event == "hyprland.shutdown" then table.insert(stops, callback)
    else error("Unexpected event: " .. event) end
  end,
  exec_cmd = function(cmd) emit("start", cmd) end,
  bind = function(keys, dispatch, opts)
    opts = opts or {}
    local flags = (opts.repeating and "e" or "") .. (opts.locked and "l" or "") .. (opts.mouse and "m" or "")
    emit("bind", keys, dispatch.name, dispatch.arg, flags)
  end,
  dsp = {
    exec_cmd = function(cmd) return action("exec", cmd) end,
    focus = function(opts)
      return opts.workspace and action("workspace", opts.workspace) or action("movefocus", assert(dirs[opts.direction]))
    end,
    window = {
      close = function() return action("killactive") end,
      float = function() return action("togglefloating") end,
      fullscreen = function(opts)
        assert(opts.mode == "maximized")
        return action("fullscreen", "1")
      end,
      swap = function(opts) return action("swapwindow", assert(dirs[opts.direction])) end,
      move = function(opts)
        assert(opts.follow == true)
        return action("movetoworkspace", opts.workspace)
      end,
      drag = function() return action("movewindow") end,
      resize = function() return action("resizewindow") end,
    },
    workspace = {
      toggle_special = function(name) return action("togglespecialworkspace", name) end,
      move = function(opts) return action("movecurrentworkspacetomonitor", opts.monitor) end,
    },
  },
}
os.execute = function(cmd) emit("stop", cmd) end
dofile(arg[1])
for _, callback in ipairs(starts) do callback() end
for _, callback in ipairs(stops) do callback() end
"""


def key(mods, symbol):
    return tuple(sorted(mods.upper().split())), symbol.upper()


expected_binds = collections.Counter()
for group, flags in (("bind", ""), ("bindel", "el"), ("bindl", "l"), ("bindm", "m")):
    for binding in old[group]:
        parts = [part.strip() for part in binding.split(",", 3)]
        mods, symbol, action = parts[:3]
        value = parts[3] if len(parts) == 4 else ""
        mods = mods.replace("$mod", old["$mod"])
        value = value.replace("$terminal", old["$terminal"])
        value = value.replace(
            "hyprctl dispatch exit", "hyprctl dispatch 'hl.dsp.exit()'"
        )
        expected_binds[key(mods, symbol), action, value, flags] += 1

with tempfile.TemporaryDirectory(dir=backup) as directory:
    directory = pathlib.Path(directory)
    config = directory / "hyprland.lua"
    config.write_text(data["text"])
    mock = directory / "capture.lua"
    mock.write_text(harness)
    records = [
        json.loads(line)
        for line in subprocess.check_output(
            [
                lua,
                str(mock),
                str(config),
            ],
            text=True,
        ).splitlines()
    ]
    binds = collections.Counter()
    env = {}
    starts, stops = [], []
    for record in records:
        if record[0] == "bind":
            parts = [part.strip() for part in record[1].split("+")]
            binds[key(" ".join(parts[:-1]), parts[-1]), *record[2:]] += 1
        elif record[0] == "env":
            env[record[1]] = record[2]
        elif record[0] == "start":
            starts.append(record[1])
        elif record[0] == "stop":
            stops.append(record[1])
    assert binds == expected_binds, {
        "missing": expected_binds - binds,
        "added": binds - expected_binds,
    }
    expected_env = dict(
        tuple(part.strip() for part in value.split(",", 1)) for value in old["env"]
    )
    assert env == expected_env
    assert starts[1:] == old["exec-once"]
    assert "dbus-update-activation-environment --systemd" in starts[0]
    assert "systemctl --user stop hyprland-session.target" in stops[0]

    # Evaluate the patched QML functions with fake IPC objects; do not run Noctalia.
    service = (
        pathlib.Path(data["noctalia"])
        / "share/noctalia-shell/Services/Compositor/HyprlandService.qml"
    )
    functions = "\n".join(
        re.findall(
            r"^  function .*?^  }", service.read_text(), re.MULTILINE | re.DOTALL
        )
    )
    js = directory / "noctalia-ipc.js"
    js.write_text(
        """
const calls = [];
const Hyprland = {dispatch: expr => calls.push(expr)};
const Quickshell = {execDetached: argv => {
  if (argv[0] === "hyprctl" && argv[1] === "dispatch") {
    if (argv.length !== 3) throw Error("Legacy dispatch argument list");
    calls.push(argv[2]);
  }
}};
const Logger = {e: (...args) => { throw Error(args.join(" ")); }, w: () => {}};
"""
        + functions
        + """
switchToWorkspace({name: 'code "quoted" workspace'});
switchToWorkspace({idx: 9});
focusWindow({id: "1a2b"});
closeWindow({id: "1a2b"});
turnOffMonitors(); turnOnMonitors(); logout();
spawn(["printf", "'%s'", "hello"]);
spawn("printf hello");
console.log(JSON.stringify(calls));
"""
    )
    expressions = json.loads(subprocess.check_output(["node", str(js)], text=True))
    assert len(expressions) == 10
    assert all(expr.startswith("hl.dsp.") for expr in expressions)
    assert "workspace = 9" in expressions[1]
    config.write_text(data["text"] + "\n" + "\n".join(expressions) + "\n")
    check = subprocess.run(
        [
            str(pathlib.Path(data["hyprland"]) / "bin/Hyprland"),
            "--verify-config",
            "--config",
            str(config),
        ],
        env=os.environ
        | {
            "XDG_CONFIG_HOME": str(directory / "config"),
            "XDG_STATE_HOME": str(directory / "state"),
            "XDG_CACHE_HOME": str(directory / "cache"),
        },
        text=True,
        capture_output=True,
        check=True,
    )
    assert "config ok" in check.stdout, check.stdout + check.stderr
    assert "Config is lua" in check.stdout + check.stderr
    assert (
        data["idle"]["general"]["after_sleep_cmd"]
        == "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'"
    )
    assert (
        data["idle"]["listener"][2]["on-timeout"]
        == "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'"
    )
    assert (
        data["idle"]["listener"][2]["on-resume"]
        == data["idle"]["general"]["after_sleep_cmd"]
    )

print(
    f"PASS: {sum(binds.values())} bindings, environment, layout, startup/shutdown, Noctalia IPC and Hyprland Lua parser"
)
