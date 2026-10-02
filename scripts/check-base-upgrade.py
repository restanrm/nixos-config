"""Phase 1 checks against a private Phase 0 backup (no activation or windows)."""

import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import tarfile
import tempfile

if len(sys.argv) != 2:
    sys.exit("Usage: python3 scripts/check-base-upgrade.py PRIVATE_BACKUP_DIRECTORY")
root = pathlib.Path(__file__).resolve().parents[1]
backup = pathlib.Path(sys.argv[1]).resolve()
assert backup.is_relative_to(root), "Backup must be inside this repository"
manifest = json.loads((backup / "manifest.json").read_text())
old = json.loads((backup / "flake.lock").read_text())["nodes"]
new = json.loads((root / "flake.lock").read_text())["nodes"]

for directory in (backup, backup / "validation"):
    for line in (directory / "SHA256SUMS").read_text().splitlines():
        digest, name = line.split("  ", 1)
        assert hashlib.sha256((directory / name).read_bytes()).hexdigest() == digest, (
            name
        )

for name in ("noctalia", "noctalia-qs"):
    assert new[name]["locked"] == old[name]["locked"], f"{name} changed"
    assert new[name]["inputs"]["nixpkgs"] == ["noctalia-nixpkgs"]
assert new["noctalia-nixpkgs"]["locked"] == old["nixpkgs"]["locked"]
for name in ("sekoia-io-agent", "nixpkgs_2", "systems", "treefmt-nix"):
    assert new[name] == old[name], f"{name} changed"

query = """cfg: let hm = cfg.home-manager.users.nrm; in {
  noctalia = toString hm.programs.noctalia-shell.package;
  noctaliaSource = toString hm.programs.noctalia-shell.package.src;
  noctaliaVersion = hm.programs.noctalia-shell.package.version;
  noctaliaPreFixup = hm.programs.noctalia-shell.package.preFixup;
  fuse = cfg.programs.fuse.enable;
  fusermount = cfg.security.wrappers.fusermount3.source;
  settings = hm.programs.noctalia-shell.settings;
  idle = hm.services.hypridle.settings;
  lock = hm.programs.hyprlock.settings;
  systemStateVersion = cfg.system.stateVersion;
  homeStateVersion = hm.home.stateVersion;
  autoUpgrade = cfg.system.autoUpgrade.enable;
  gc = cfg.nix.gc.automatic;
  hyprlandType = hm.wayland.windowManager.hyprland.configType;
  hyprlandConfig = hm.xdg.configFile."hypr/hyprland.conf".text;
  sshConfig = hm.home.file.".ssh/config".text;
  qtTheme = hm.qt.platformTheme.name;
}"""
config = json.loads(
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
legacy = json.loads(
    subprocess.check_output(
        [
            "nix",
            "eval",
            "--impure",
            "--no-write-lock-file",
            "--json",
            "--expr",
            f"""let
      f = builtins.getFlake {json.dumps(str(root))};
      p = f.inputs.noctalia-nixpkgs.legacyPackages.x86_64-linux;
      shell = f.inputs.noctalia.packages.x86_64-linux.default;
    in {{
      base = toString shell;
      source = toString shell.src;
      version = shell.version;
      mesa = toString p.mesa;
      python = toString p.python3;
      glvnd = toString p.libglvnd;
    }}""",
        ],
        text=True,
    )
)
assert legacy["base"] == manifest["noctalia_package"], "Frozen base package changed"
assert config["noctaliaSource"] == legacy["source"]
assert config["noctaliaVersion"] == legacy["version"]
vendor = f"{legacy['mesa']}/share/glvnd/egl_vendor.d/50_mesa.json"
assert f'--set __EGL_VENDOR_LIBRARY_FILENAMES "{vendor}"' in config["noctaliaPreFixup"]
assert config["fuse"] and str(config["fusermount"]).endswith("/bin/fusermount3")

# Use the frozen interpreter/libc, not the current host Python. No window is created.
subprocess.run(
    [
        f"{legacy['python']}/bin/python3",
        "-c",
        """
import ctypes as c, sys
egl = c.CDLL(sys.argv[1] + "/lib/libEGL.so.1")
egl.eglGetDisplay.argtypes = [c.c_void_p]
egl.eglGetDisplay.restype = c.c_void_p
egl.eglInitialize.argtypes = [c.c_void_p, c.POINTER(c.c_int), c.POINTER(c.c_int)]
egl.eglInitialize.restype = c.c_uint
egl.eglTerminate.argtypes = [c.c_void_p]
display = egl.eglGetDisplay(None)
major, minor = c.c_int(), c.c_int()
assert egl.eglInitialize(display, c.byref(major), c.byref(minor)), "Frozen EGL initialization failed"
egl.eglTerminate(display)
print("PASS: frozen EGL driver initialized without creating a window")
""",
        legacy["glvnd"],
    ],
    env=os.environ
    | {"EGL_PLATFORM": "surfaceless", "__EGL_VENDOR_LIBRARY_FILENAMES": vendor},
    check=True,
)
assert config["systemStateVersion"] == config["homeStateVersion"] == "26.05"
assert not config["autoUpgrade"] and not config["gc"]
assert config["hyprlandType"] == "hyprlang"
assert config["qtTheme"] == "gtk3"
assert "env=QT_QPA_PLATFORMTHEME, gtk3" in config["hyprlandConfig"]
assert "exec-once=noctalia-shell" in config["hyprlandConfig"]
assert "exec-once=noctalia\n" not in config["hyprlandConfig"]
assert config["settings"]["idle"]["enabled"] is False
assert config["idle"]["general"]["lock_cmd"] == "pidof hyprlock || hyprlock"
assert config["lock"]["auth"]["fingerprint"]["enabled"] is True
assert not {"disable_loading", "no_fade_in"} & config["lock"]["general"].keys()
with tarfile.open(backup / "data-resolved.tar.gz") as archive:
    assert config["settings"] == json.load(
        archive.extractfile(".config/noctalia/settings.json")
    )

baseline_ssh = backup / "validation" / "ssh-baseline.conf"
hosts = re.findall(r"^Host (.+)$", baseline_ssh.read_text(), re.MULTILINE)
assert hosts == re.findall(r"^Host (.+)$", config["sshConfig"], re.MULTILINE)


def effective_ssh(path, host):
    output = subprocess.check_output(
        [
            "ssh",
            "-G",
            "-T",
            "-F",
            str(path),
            host,
        ],
        text=True,
    )
    # The only intentional SSH difference is the updated YubiKey library path.
    return re.sub(
        r"/nix/store/[a-z0-9]{32}-yubico-piv-tool-[^/\s]+", "YUBICO_PACKAGE", output
    )


with tempfile.TemporaryDirectory(dir=backup) as directory:
    candidate = pathlib.Path(directory) / "ssh.conf"
    candidate.write_text(config["sshConfig"])
    for host in hosts:
        host = "phase1-check.invalid" if host == "*" else host
        assert effective_ssh(baseline_ssh, host) == effective_ssh(candidate, host), host

print(
    f"PASS: backups, frozen Noctalia source/settings and EGL, state versions, legacy Hyprland, locking, FUSE, and {len(hosts)} SSH cases"
)
