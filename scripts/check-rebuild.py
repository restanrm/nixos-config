"""Check rebuild helpers and installed activation flags without switching."""

import ast
import os
import pathlib
import re
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
    assert len(calls) == 1, name
    assert (
        f"/run/current-system/sw/bin/nixos-rebuild {action} --no-reexec" in calls[0]
    ), name

# Exercise qrebuild without elevation or activation, including failure propagation.
with tempfile.TemporaryDirectory(dir=root / ".git") as directory:
    mock_dir = pathlib.Path(directory)
    sudo = mock_dir / "sudo"
    sudo.write_text(
        '#!/usr/bin/env bash\nprintf "%s\\0" "$@" > "$ARGS_FILE"\nexit "$MOCK_EXIT"\n'
    )
    sudo.chmod(0o700)
    args_file = mock_dir / "args"
    env = os.environ | {
        "PATH": f"{mock_dir}:{os.environ['PATH']}",
        "ARGS_FILE": str(args_file),
        "MOCK_EXIT": "0",
    }
    result = subprocess.run(
        [str(root / "qrebuild"), "--option", "cores", "2"],
        cwd=mock_dir,
        env=env,
        text=True,
        capture_output=True,
        check=True,
    )
    assert args_file.read_bytes().split(b"\0")[:-1] == [
        b"/run/current-system/sw/bin/nixos-rebuild",
        b"test",
        b"--no-reexec",
        b"--flake",
        f"{root}#hp-ara".encode(),
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
assert "$CONF_DIR/result" not in rebuild

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
