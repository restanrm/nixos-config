"""Check that the Noctalia migration leaves the accepted base system unchanged."""

import hashlib
import json
import pathlib
import subprocess
import sys

if len(sys.argv) != 2:
    sys.exit("Usage: python3 scripts/check-base-upgrade.py PRIVATE_BACKUP_DIRECTORY")
root = pathlib.Path(__file__).resolve().parents[1]
backup = pathlib.Path(sys.argv[1]).resolve()
assert backup.is_relative_to(root)
manifest = json.loads((backup / "manifest.json").read_text())
for line in (backup / "SHA256SUMS").read_text().splitlines():
    digest, name = line.split("  ", 1)
    assert hashlib.sha256((backup / name).read_bytes()).hexdigest() == digest, name
old = json.loads((backup / "flake.lock").read_text())["nodes"]
new = json.loads((root / "flake.lock").read_text())["nodes"]
for name in ("nixpkgs", "home-manager", "sekoia-io-agent", "nixpkgs_2"):
    assert new[name] == old[name], f"Unrelated input changed: {name}"

query = """cfg: let hm = cfg.home-manager.users.nrm; in {
  systemStateVersion = cfg.system.stateVersion;
  homeStateVersion = hm.home.stateVersion;
  autoUpgrade = cfg.system.autoUpgrade.enable;
  gc = cfg.nix.gc.automatic;
  hyprland = hm.wayland.windowManager.hyprland.settings;
  hyprlandType = hm.wayland.windowManager.hyprland.configType;
  idle = hm.services.hypridle.settings;
  lock = hm.programs.hyprlock.settings;
  ssh = hm.home.file.".ssh/config".text;
  sshAgent = cfg.programs.ssh.startAgent;
  qtTheme = hm.qt.platformTheme.name;
}"""


def evaluate(flake):
    return json.loads(
        subprocess.check_output(
            [
                "nix",
                "eval",
                "--no-write-lock-file",
                "--json",
                flake + "#nixosConfigurations.hp-ara.config",
                "--apply",
                query,
            ],
            cwd=root,
            text=True,
        )
    )


baseline = evaluate(f"git+file://{root}?rev={manifest['source_revision']}")
current = evaluate(".")
assert current == baseline, (
    "Base system, SSH, layout, idle or lock configuration changed"
)
assert current["systemStateVersion"] == current["homeStateVersion"] == "26.05"
assert current["sshAgent"] and not current["autoUpgrade"] and not current["gc"]
assert current["hyprlandType"] == "lua"
print(
    "PASS: backups, base inputs, state versions, SSH, layout, idle and locking unchanged"
)
