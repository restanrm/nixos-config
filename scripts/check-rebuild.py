"""Check rebuild helpers and installed activation flags without switching."""

import ast
import os
import pathlib
import re
import shutil
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[1]
for name, action in (
    ("rebuild.sh", "switch"),
    ("qrebuild", "test"),
    ("modules/home/zsh.nix", "switch"),
):
    text = (root / name).read_text()
    calls = [
        line
        for line in text.splitlines()
        if re.search(
            r"^\s*(?:sudo\s+)?(?:/\S+/)?nixos-rebuild\s+(?:switch|test)\b", line
        )
    ]
    assert len(calls) == (2 if name == "rebuild.sh" else 1), name
    assert all(
        f"/run/current-system/sw/bin/nixos-rebuild {action} --no-reexec" in call
        for call in calls
    ), name

# Exercise qrebuild without elevation or activation, including failure propagation.
with tempfile.TemporaryDirectory(dir=root / ".git") as directory:
    mock_dir = pathlib.Path(directory)
    sudo = mock_dir / "sudo"
    sudo.write_text(
        '#!/usr/bin/env bash\nprintf "%s\\0" "$@" > "$ARGS_FILE"\nexit "$MOCK_EXIT"\n'
    )
    sudo.chmod(0o700)
    hostname = mock_dir / "hostname"
    hostname.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$MOCK_HOSTNAME"\n')
    hostname.chmod(0o700)
    args_file = mock_dir / "args"
    env = os.environ | {
        "PATH": f"{mock_dir}:{os.environ['PATH']}",
        "ARGS_FILE": str(args_file),
        "MOCK_EXIT": "0",
        "MOCK_HOSTNAME": "laptop-ara",
    }
    for hostname, target in (("laptop-ara", "hp-ara"), ("tortuga", "tortuga")):
        result = subprocess.run(
            [str(root / "qrebuild"), "--option", "cores", "2"],
            cwd=mock_dir,
            env=env | {"MOCK_HOSTNAME": hostname},
            text=True,
            capture_output=True,
            check=True,
        )
        assert args_file.read_bytes().split(b"\0")[:-1] == [
            b"/run/current-system/sw/bin/nixos-rebuild",
            b"test",
            b"--no-reexec",
            b"--flake",
            f"{root}#{target}".encode(),
            b"--option",
            b"cores",
            b"2",
        ]
        assert "Test activation complete" in result.stdout
    result = subprocess.run(
        [str(root / "qrebuild")],
        cwd=mock_dir,
        env=env | {"MOCK_EXIT": "7"},
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 7
    assert "Test activation complete" not in result.stdout

rebuild = (root / "rebuild.sh").read_text()
assert "OLD_SYSTEM=$(readlink -f /run/current-system)" in rebuild
assert 'nvd diff "$OLD_SYSTEM" /run/current-system' in rebuild

# Simulate the SSH receiver and rebuild without connecting or elevating.
with tempfile.TemporaryDirectory(dir=root / ".git") as directory:
    base = pathlib.Path(directory)
    source_dir, remote, bin_dir = (base / name for name in ("source", "remote", "bin"))
    for path in (source_dir, remote, bin_dir):
        path.mkdir()
    for name in ("bash", "dirname", "git", "mktemp", "readlink", "rm", "tar", "zsh"):
        (bin_dir / name).symlink_to(shutil.which(name))

    def mock(name, body):
        path = bin_dir / name
        path.write_text("#!/usr/bin/env bash\nset -eu\n" + body)
        path.chmod(0o700)

    mock("hostname", 'printf "%s\\n" "${MOCK_HOSTNAME:-laptop-ara}"\n')
    mock("sudo", 'exec "$@"\n')
    mock(
        "nixos-rebuild",
        """printf '%s\\0' "$@" > "$ARGS_FILE"
if [[ "$4" == path:* ]]; then
  snapshot=${4#path:}
  snapshot=${snapshot%#*}
  [[ $(<"$snapshot/flake.nix") == "working copy" ]]
  [[ ! -e "$snapshot/.git" && ! -e "$snapshot/deleted" && ! -e "$snapshot/untracked" ]]
fi
exit "$MOCK_EXIT"
""",
    )
    mock(
        "ssh",
        """[[ "$2 $3 $4 $5 $6 $7" == '-o ForwardAgent=no -o StrictHostKeyChecking=yes -- nrm@192.168.1.133' ]]
[[ "$1" == -T || "$1" == -t ]]
cd "$REMOTE_HOME"
HOME="$REMOTE_HOME" MOCK_HOSTNAME="${REMOTE_HOSTNAME:-tortuga}" exec zsh -c "$8"
""",
    )
    args_file = base / "args"
    env = os.environ | {
        "PATH": str(bin_dir),
        "ARGS_FILE": str(args_file),
        "REMOTE_HOME": str(remote),
        "MOCK_EXIT": "0",
    }
    script = source_dir / "rebuild.sh"
    script.write_text(
        rebuild.replace(
            "/run/current-system/sw/bin/nixos-rebuild", str(bin_dir / "nixos-rebuild")
        )
    )
    script.chmod(0o700)
    flake = source_dir / "flake.nix"
    flake.write_text("old copy\n")
    (source_dir / "deleted").touch()
    subprocess.run(["git", "init", "-q"], cwd=source_dir, env=env, check=True)
    subprocess.run(
        ["git", "add", "flake.nix", "deleted"], cwd=source_dir, env=env, check=True
    )
    flake.write_text("working copy\n")
    (source_dir / "deleted").unlink()
    (source_dir / "untracked").touch()

    def run_rebuild(*args, **overrides):
        return subprocess.run(
            [script, *args], env=env | overrides, text=True, capture_output=True
        )

    local = run_rebuild()
    assert local.returncode == 0, local.stderr
    assert args_file.read_bytes().split(b"\0")[:-1] == [
        b"switch",
        b"--no-reexec",
        b"--flake",
        b".#hp-ara",
        b"--sudo",
    ]
    result = run_rebuild("tortuga")
    assert result.returncode == 0, result.stderr
    assert "Configuration applied on tortuga" in result.stdout
    args = args_file.read_bytes().split(b"\0")[:-1]
    assert args[:3] == [b"switch", b"--no-reexec", b"--flake"]
    assert args[3].startswith(f"path:{remote}/.nixos-rebuild.".encode()) and args[
        3
    ].endswith(b"#tortuga")
    assert not list(remote.iterdir())
    result = run_rebuild("tortuga", MOCK_EXIT="7")
    assert result.returncode == 7, result.stderr
    assert "Configuration applied" not in result.stdout and not list(remote.iterdir())
    args_file.unlink()
    result = run_rebuild("tortuga", REMOTE_HOSTNAME="other")
    assert result.returncode != 0 and "Unexpected remote hostname" in result.stderr
    assert not args_file.exists() and not list(remote.iterdir())

installed = (
    pathlib.Path("/run/current-system/sw/bin/nixos-rebuild").resolve().parents[1]
)
source = next(installed.glob("lib/python*/site-packages/nixos_rebuild/nix.py"))
prefix = next(
    ast.literal_eval(node.value)
    for node in ast.parse(source.read_text()).body
    if isinstance(node, ast.AnnAssign)
    and isinstance(node.target, ast.Name)
    and node.target.id == "SWITCH_TO_CONFIGURATION_CMD_PREFIX"
)
help_text = subprocess.check_output(
    ["/run/current-system/sw/bin/systemd-run", "--help"], text=True
)
supported = set(re.findall(r"--[a-z-]+", help_text))
for flag in prefix:
    if flag.startswith("--"):
        assert flag.split("=", 1)[0] in supported, (
            f"Unsupported activation flag: {flag}"
        )
assert "systemd-run" in prefix, "Activation service must not be bypassed"
print(
    "PASS: all rebuild helpers retain the installed client; activation flags are supported"
)
