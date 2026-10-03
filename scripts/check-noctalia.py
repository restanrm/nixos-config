"""Check Noctalia v5 configuration and data migration without starting the shell."""

import json
import pathlib
import subprocess
import tarfile
import tempfile

import tomllib

root = pathlib.Path(__file__).resolve().parents[1]
backup = root / ".git/noctalia-v5-migration"
locks = json.loads((root / "flake.lock").read_text())["nodes"]
assert locks["noctalia"]["locked"]["rev"] == "064476d48818896ef0dd93f42ccb632dd8f52c55"
assert (
    locks["noctalia-plugins"]["locked"]["rev"]
    == "01c3ad4fc2da5d1c1ef03bff7cbfe44b759f2ce6"
)
assert not {"noctalia-qs", "noctalia-nixpkgs", "systems", "treefmt-nix"} & locks.keys()
query = """cfg: let hm = cfg.home-manager.users.nrm; in {
  package = toString hm.programs.noctalia.package;
  config = toString hm.xdg.configFile."noctalia/config.toml".source;
  settings = hm.programs.noctalia.settings;
  checkConfig = hm.programs.noctalia.checkConfig;
  files = builtins.attrNames hm.xdg.configFile;
  keyring = cfg.services.gnome.gnome-keyring.enable;
  pamKeyring = cfg.security.pam.services.greetd.enableGnomeKeyring;
  gcrAgent = cfg.services.gnome.gcr-ssh-agent.enable;
  target = hm.wayland.systemd.target;
  service = hm.systemd.user.services.noctalia;
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
settings = data["settings"]
assert (
    data["checkConfig"]
    and data["keyring"]
    and data["pamKeyring"]
    and not data["gcrAgent"]
)
assert "noctalia/settings.json" not in data["files"]
assert settings["storage"]["key_source"] == "secret-service"
assert not settings["lockscreen"]["enabled"]
assert all(not row["enabled"] for row in settings["idle"]["behavior"].values())
assert settings["theme"] == {
    "mode": "dark",
    "source": "builtin",
    "builtin": "Catppuccin",
}
assert settings["bar"]["main"]["position"] == "bottom"
assert settings["bar"]["main"]["thickness"] == 25
assert settings["widget"]["clock"]["format"] == "{:%Y-%m-%d %H:%M:%S}"
assert pathlib.Path(
    settings["widget"]["distro-control-center"]["custom_image"]
).is_file()
assert settings["plugins"]["auto_update"] == "none"
assert data["service"]["Install"]["WantedBy"] == [data["target"]]
assert data["service"]["Service"]["ExecStart"] == [data["package"] + "/bin/noctalia"]
assert data["service"]["Service"]["Restart"] == "on-failure"
locks_menu = [
    row for row in settings["shell"]["session"]["actions"] if row.get("label") == "Lock"
]
assert len(locks_menu) == 1 and locks_menu[0]["action"] == "command"
assert locks_menu[0]["command"] == "loginctl lock-session"

binary = data["package"] + "/bin/noctalia"
version = subprocess.check_output([binary, "--version"], text=True)
assert "5.2.1" in version and "064476d" in version
validation = subprocess.run(
    [binary, "config", "validate", data["config"]],
    text=True,
    capture_output=True,
    check=True,
)
assert "Config is valid" in validation.stdout
assert not validation.stderr.strip(), validation.stderr
assert "WARN" not in validation.stdout and "WRN" not in validation.stdout
source = pathlib.Path(settings["plugins"]["source"][0]["location"])
assert {p.name for p in source.iterdir()} == {"paged-todo", "screen-toolkit"}
for folder, plugin_id in (
    ("paged-todo", "baizhu/paged-todo"),
    ("screen-toolkit", "alexander/screen-toolkit"),
):
    plugin = tomllib.loads((source / folder / "plugin.toml").read_text())
    assert plugin["id"] == plugin_id and plugin["plugin_api"] <= 32
lint = subprocess.run(
    [
        binary,
        "plugins",
        "lint",
        str(source / "paged-todo"),
        str(source / "screen-toolkit"),
    ],
    text=True,
    capture_output=True,
    check=True,
)
assert "0 errors, 0 warnings" in lint.stdout

with tarfile.open(backup / "data-resolved.tar.gz") as archive:
    todo = json.load(archive.extractfile(".config/noctalia/plugins/todo/settings.json"))
    screen = json.load(
        archive.extractfile(".config/noctalia/plugins/screen-toolkit/settings.json")
    )


def lua_literal(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, str):
        return repr(value)
    if isinstance(value, list):
        return "{" + ",".join(lua_literal(v) for v in value) + "}"
    if isinstance(value, dict):
        return (
            "{"
            + ",".join(f"[{lua_literal(k)}]={lua_literal(v)}" for k, v in value.items())
            + "}"
        )
    return str(value)


with tempfile.TemporaryDirectory(dir=backup) as directory:
    directory = pathlib.Path(directory)
    old_json = directory / "screen.json"
    old_json.write_text(json.dumps(screen))
    target = directory / "screen-data"
    migrator = [
        "python3",
        str(root / "scripts/migrate-noctalia-state.py"),
        str(old_json),
        str(target),
    ]
    subprocess.run(migrator, check=True)
    assert (
        json.loads((target / "color-history.json").read_text())
        == screen["colorHistory"]
    )
    results = json.loads((target / "results.json").read_text())
    assert results["paletteColors"] == screen["paletteColors"]
    assert results["colorResult"]["hex"] == screen["resultHex"]
    assert (target / "results.json").stat().st_mode & 0o777 == 0o600
    (target / "color-history.json").write_text('["existing-v5-data"]')
    subprocess.run(migrator, check=True)
    assert json.loads((target / "color-history.json").read_text()) == [
        "existing-v5-data"
    ]

    # The pinned importer uses ordinary Lua apart from one Luau interpolated path.
    module = (source / "paged-todo/data.luau").read_text()
    special = "`{dataDir}/todos.json`"
    assert module.count(special) == 1
    module = module.replace(special, '(dataDir .. "/todos.json")')
    module_path = directory / "data.lua"
    module_path.write_text(module)
    harness = directory / "import-test.lua"
    harness.write_text(
        "local legacy = "
        + lua_literal(todo)
        + "\nlocal original = "
        + lua_literal(todo)
        + r"""
local live, written, reads = nil, nil, 0
local saved = {todos = {{id = "existing", text = "existing-v5-data"}}, pages = {{id = 0, name = "General"}}}
local existing = false
noctalia = {
  pluginDataDir = function() return "isolated-data" end,
  readFile = function(path)
    if path == "isolated-data/todos.json" then return existing and "saved" or nil end
    assert(path == "~/.config/noctalia/plugins/todo/settings.json")
    assert(not existing, "Existing v5 data must not re-import legacy data")
    reads = reads + 1
    return "legacy"
  end,
  writeFile = function(path, value)
    assert(path == "isolated-data/todos.json" and value == "encoded")
    written = live
  end,
  json = {
    decode = function(token) return token == "legacy" and legacy or saved end,
    encode = function(value) assert(value == live) return "encoded" end,
  },
  state = {get = function() return live end, set = function(_, value) live = value end},
}
local module = dofile(arg[1])
local data = module.load()
assert(#data.todos == #original.todos and #data.pages == #original.pages)
for i, record in ipairs(original.todos) do
  for key, value in pairs(record) do assert(data.todos[i][key] == value, "Todo metadata changed") end
end
for i, page in ipairs(original.pages) do
  for key, value in pairs(page) do assert(data.pages[i][key] == value, "Page metadata changed") end
end
assert(data.current_page_id == original.current_page_id and reads == 1 and written == data)
assert(module.load() == data and reads == 1)
live = nil
existing = true
assert(module.load().todos[1].id == "existing" and reads == 1)
print("PASS: todo importer preserves records/metadata and existing v5 state")
"""
    )
    subprocess.run([lua, str(harness), str(module_path)], check=True)

print(
    f"PASS: pinned v5, warning-free config, plugins, encryption/lock ownership, {len(todo['todos'])} todos and idempotent screen state"
)
