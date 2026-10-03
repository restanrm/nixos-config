"""Exercise bwmenu with fake Bitwarden, rofi, and GPG commands only."""

import base64
import json
import os
import pathlib
import pty
import select
import shutil
import signal
import subprocess
import tempfile
import textwrap
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "modules/home/bitwarden.nix").read_text()
BINDINGS = (ROOT / "modules/home/hyprland/binds.nix").read_text()

start = SOURCE.index('bwmenu = pkgs.writeShellScriptBin "bwmenu" \'\'\n')
start = SOURCE.index("\n", start) + 1
end = SOURCE.index("\n  '';\nin {", start)
script = textwrap.dedent(SOURCE[start:end]).replace("''${", "${")

with tempfile.TemporaryDirectory(dir=ROOT / ".git") as temporary:
    root = pathlib.Path(temporary)
    bin_dir = root / "bin"
    bin_dir.mkdir()
    log = root / "bw.jsonl"
    rofi_log = root / "rofi.jsonl"
    gpg_log = root / "gpg.jsonl"
    alacritty_log = root / "alacritty.jsonl"
    fixture = {
        "type": 1,
        "id": "fixture-id",
        "name": "Example",
        "login": {
            "username": "fixture-user",
            "password": "fixture-password",
            "uris": [{"uri": "https://example.invalid"}],
        },
    }
    fixture_json = json.dumps([fixture])

    def executable(name, content):
        path = bin_dir / name
        path.write_text(content)
        path.chmod(0o700)
        return str(path)

    bw = executable(
        "bw",
        "#!/usr/bin/env python3\n"
        + f"LOG = {str(log)!r}\n"
        + "import json, os, pathlib, sys\n"
        + "args = sys.argv[1:]\n"
        + "action = args[0] if args else ''\n"
        + "record = {'args': args, 'session': os.environ.get('BW_SESSION'), "
        + "'password_set': 'BW_PASSWORD' in os.environ, "
        + "'password_ok': os.environ.get('BW_PASSWORD') == 'fixture-master-password', "
        + "'nointeraction': os.environ.get('BW_NOINTERACTION'), "
        + "'stdin_tty': sys.stdin.isatty(), 'stderr_tty': sys.stderr.isatty(), "
        + "'session_file_exists': pathlib.Path(os.environ.get('BW_LOCAL_SESSION_FILE', '/nonexistent')).exists()}\n"
        + "with open(LOG, 'a') as f: f.write(json.dumps(record) + '\\n')\n"
        + "if os.environ.get('BW_FAIL_ACTION') == action: sys.exit(9)\n"
        + "if action == 'config':\n"
        + "    if args[1:] == ['server']: print(os.environ.get('BW_SERVER_URL', 'https://vault.bitwarden.eu')); sys.exit(0)\n"
        + "    if args[1:2] == ['server'] and len(args) == 3:\n"
        + "        if os.environ.get('BW_STATUS', 'locked') in ('locked', 'unlocked'): sys.exit(9)\n"
        + "        sys.exit(0)\n"
        + "    sys.exit(9)\n"
        + "if action == 'status': print(json.dumps({'status': os.environ.get('BW_STATUS', 'locked')})); sys.exit(0)\n"
        + "if action == 'login':\n"
        + "    if not sys.stdin.isatty() or not sys.stderr.isatty(): sys.exit(10)\n"
        + "    sys.stderr.write('Authenticator App MFA code: '); sys.stderr.flush()\n"
        + "    token = sys.stdin.readline().strip()\n"
        + "    if token != os.environ.get('BW_MFA_TOKEN', '654321'):\n"
        + "        print('\\nInvalid authenticator code', file=sys.stderr); sys.exit(9)\n"
        + "    if os.environ.get('BW_LOGIN_SESSION'): print(os.environ['BW_LOGIN_SESSION'])\n"
        + "    sys.exit(0)\n"
        + "if action == 'unlock':\n"
        + "    print(os.environ.get('BW_UNLOCK_SESSION', 'unlocked-session')); sys.exit(0)\n"
        + "if action == 'sync': sys.exit(0)\n"
        + f"if args[:2] == ['list', 'items']: print({fixture_json!r}); sys.exit(0)\n"
        + "if args[:2] == ['list', 'folders']: print('[]'); sys.exit(0)\n"
        + "if args[:2] == ['get', 'totp']: print('123456'); sys.exit(0)\n"
        + "sys.exit(0)\n",
    )
    rofi = executable(
        "rofi",
        "#!/usr/bin/env python3\n"
        + f"LOG = {str(rofi_log)!r}\n"
        + f"COUNT = {str(root / 'menu-count')!r}\n"
        + "import json, os, pathlib, sys\n"
        + "args = sys.argv[1:]\n"
        + "kind = 'error' if '-e' in args else ('password' if '-password' in args else 'menu')\n"
        + "record = {'kind': kind, 'args': args}\n"
        + "if kind == 'error': record['message'] = args[args.index('-e') + 1]\n"
        + "with open(LOG, 'a') as f: f.write(json.dumps(record) + '\\n')\n"
        + "if kind == 'error': sys.exit(0)\n"
        + "if kind == 'password':\n"
        + "    if os.environ.get('ROFI_CANCEL_PASSWORD') == '1': sys.exit(1)\n"
        + "    print(os.environ.get('ROFI_PASSWORD', '')); sys.exit(0)\n"
        + "n = int(pathlib.Path(COUNT).read_text()) if pathlib.Path(COUNT).exists() else 0\n"
        + "pathlib.Path(COUNT).write_text(str(n + 1))\n"
        + "codes = os.environ.get('ROFI_MENU_CODES', '1').split(',')\n"
        + "code = int(codes[min(n, len(codes) - 1)])\n"
        + "if code == 0: print(os.environ.get('ROFI_MENU_INDEX', '0'))\n"
        + "sys.exit(code)\n",
    )
    gpg = executable(
        "gpg",
        "#!/usr/bin/env python3\n"
        + f"LOG = {str(gpg_log)!r}\n"
        + "import base64, json, os, pathlib, sys\n"
        + "args = sys.argv[1:]\n"
        + "try: passphrase = os.read(3, 4096).decode().strip()\n"
        + "except OSError: passphrase = ''\n"
        + "mode = 'decrypt' if '-d' in args else 'encrypt'\n"
        + "with open(LOG, 'a') as f: f.write(json.dumps({'mode': mode, 'args': args, 'passphrase_fd': bool(passphrase)}) + '\\n')\n"
        + "if mode == 'decrypt':\n"
        + "    data = pathlib.Path(args[-1]).read_bytes()\n"
        + "    if not data.startswith(b'TEST-ENCRYPTED:'): sys.exit(1)\n"
        + "    sys.stdout.buffer.write(base64.b64decode(data.split(b':', 1)[1])); sys.exit(0)\n"
        + "output = args[args.index('-o') + 1]\n"
        + "data = sys.stdin.buffer.read()\n"
        + "pathlib.Path(output).write_bytes(b'TEST-ENCRYPTED:' + base64.b64encode(data))\n",
    )
    alacritty = executable(
        "alacritty",
        "#!/usr/bin/env python3\n"
        + f"LOG = {str(alacritty_log)!r}\n"
        + "import json, os, pty, select, signal, sys\n"
        + "record = {'args': sys.argv[1:], 'transcript': ''}\n"
        + "if os.environ.get('ALACRITTY_CLOSE') != '1':\n"
        + "    if sys.argv[1] != '-e': sys.exit(64)\n"
        + "    pid, master = pty.fork()\n"
        + "    if pid == 0: os.execvpe(sys.argv[2], sys.argv[2:], os.environ)\n"
        + "    output = bytearray(); sent_code = sent_enter = False\n"
        + "    while True:\n"
        + "        ready, _, _ = select.select([master], [], [], 5)\n"
        + "        if not ready:\n"
        + "            os.kill(pid, signal.SIGTERM); break\n"
        + "        try: data = os.read(master, 4096)\n"
        + "        except OSError: break\n"
        + "        if not data: break\n"
        + "        output.extend(data)\n"
        + "        if not sent_code and b'Authenticator App MFA code:' in output:\n"
        + "            response = os.environ.get('ALACRITTY_MFA_RESPONSE', '654321')\n"
        + "            os.write(master, response.encode() + b'\\n'); sent_code = True\n"
        + "        if not sent_enter and b'Press Enter to close.' in output:\n"
        + "            os.write(master, b'\\n'); sent_enter = True\n"
        + "    os.waitpid(pid, 0)\n"
        + "    record['transcript'] = output.decode(errors='replace')\n"
        + "with open(LOG, 'a') as f: f.write(json.dumps(record) + '\\n')\n"
        + "sys.exit(0)\n",
    )
    clipboard = executable("wl-copy", "#!/bin/sh\ncat >/dev/null\n")
    jq = shutil.which("jq")
    assert jq, "jq is required by the Bitwarden Home Manager module"

    replacements = {
        "${pkgs.bitwarden-cli}/bin/bw": bw,
        "${pkgs.alacritty}/bin/alacritty": alacritty,
        "${pkgs.bash}/bin/bash": shutil.which("bash"),
        "${pkgs.rofi}/bin/rofi": rofi,
        "${pkgs.gnupg}/bin/gpg": gpg,
        "${pkgs.jq}/bin/jq": jq,
        "${pkgs.wl-clipboard}/bin/wl-copy": clipboard,
        "${pkgs.coreutils}/bin/cat": shutil.which("cat"),
        "${pkgs.coreutils}/bin/rm": shutil.which("rm"),
    }
    for command in ("date", "stat", "id", "sort", "cut"):
        binary = shutil.which(command)
        assert binary, f"{command} is required by the Bitwarden launcher"
        replacements[f"${{pkgs.coreutils}}/bin/{command}"] = binary
    for old, new in replacements.items():
        script = script.replace(old, new)
    assert "${pkgs." not in script, "unreplaced Nix command interpolation"

    launcher = root / "bwmenu"
    launcher.write_text("#!/usr/bin/env bash\n" + script)
    launcher.chmod(0o700)
    subprocess.run(["bash", "-n", str(launcher)], check=True)

    def encrypted(data):
        return b"TEST-ENCRYPTED:" + base64.b64encode(data.encode())

    def scenario(name, *, session=None, timestamp=None, cached=False, args=(), env=None):
        home = root / name
        runtime = home / "runtime"
        cache = home / "cache"
        runtime.mkdir(parents=True)
        runtime.chmod(0o700)
        environment = os.environ | {
            "HOME": str(home),
            "XDG_RUNTIME_DIR": str(runtime),
            "XDG_CACHE_HOME": str(cache),
            "BW_LOG": str(log),
            "ROFI_LOG": str(rofi_log),
            "GPG_LOG": str(gpg_log),
            "BW_STATUS": "locked",
            "BW_SERVER_URL": "https://vault.bitwarden.eu",
        }
        environment.update(env or {})
        log.unlink(missing_ok=True)
        rofi_log.unlink(missing_ok=True)
        gpg_log.unlink(missing_ok=True)
        alacritty_log.unlink(missing_ok=True)
        (root / "menu-count").unlink(missing_ok=True)
        runtime_cache = runtime / "bwmenu"
        environment["BW_LOCAL_SESSION_FILE"] = str(runtime_cache / "session")
        cache_dir = cache / "bwmenu"
        if session is not None:
            runtime_cache.mkdir(mode=0o700)
            (runtime_cache / "session").write_text(f"{session} {timestamp or int(time.time())}\n")
            (runtime_cache / "session").chmod(0o600)
        if cached:
            cache_dir.mkdir(parents=True, mode=0o700)
            (cache_dir / "logins.gpg").write_bytes(encrypted(fixture_json))
        result = subprocess.run(
            [str(launcher), *args],
            cwd=home,
            env=environment,
            text=True,
            capture_output=True,
            check=False,
        )
        bw_calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
        rofi_calls = [json.loads(line) for line in rofi_log.read_text().splitlines()] if rofi_log.exists() else []
        gpg_calls = [json.loads(line) for line in gpg_log.read_text().splitlines()] if gpg_log.exists() else []
        return result, runtime_cache, cache_dir, bw_calls, rofi_calls, gpg_calls

    def successful(result):
        assert result.returncode == 0, (result.returncode, result.stderr)

    # Valid encrypted cache/session is a local-only, fuzzy-menu fast path.
    result, runtime, cache, calls, rofi_calls, gpg_calls = scenario(
        "fast-path", session="cached-session", cached=True, args=("--auto-lock", "86400")
    )
    successful(result)
    assert not calls, "cached menu invoked Bitwarden CLI"
    assert not alacritty_log.exists(), "warm menu opened an authentication terminal"
    assert (runtime / "session").stat().st_mode & 0o777 == 0o600
    assert (runtime / "session").read_text().startswith("cached-session ")
    assert not (cache / "session").exists()
    assert b"fixture-password" not in (cache / "logins.gpg").read_bytes()
    assert any(call["kind"] == "menu" and "-matching" in call["args"] and "fuzzy" in call["args"] for call in rofi_calls)
    assert all(call["passphrase_fd"] for call in gpg_calls)
    assert all("--passphrase" not in call["args"] and "cached-session" not in call["args"] for call in gpg_calls)

    # 23 hours is reused without CLI; an expired (24h+) session is removed and replaced after unlock+sync.
    recent = int(time.time()) - 23 * 60 * 60
    result, _, _, calls, _, _ = scenario(
        "reuse-23h", session="recent-session", timestamp=recent, cached=True, args=("--auto-lock", "86400")
    )
    successful(result)
    assert not calls, "session younger than 24 hours was not reused"

    # An already-logged-in account unlocks without attempting the forbidden server setter.
    result, _, _, calls, _, _ = scenario(
        "logged-in-unlock",
        session="short-session",
        timestamp=int(time.time()) - 61,
        cached=True,
        args=("--auto-lock", "60"),
        env={"ROFI_PASSWORD": "fixture-master-password"},
    )
    successful(result)
    assert any(call["args"] == ["config", "server"] for call in calls)
    assert not any(call["args"][:2] == ["config", "server"] and len(call["args"]) == 3 for call in calls)
    unlock = next(call for call in calls if call["args"][0] == "unlock")
    assert unlock["nointeraction"] == "true"
    assert not alacritty_log.exists(), "already-logged-in unlock opened an authentication terminal"

    expired = int(time.time()) - 24 * 60 * 60 - 2
    result, runtime, cache, calls, rofi_calls, _ = scenario(
        "expire-24h",
        session="expired-session",
        timestamp=expired,
        cached=True,
        args=("--auto-lock", "172800"),
        env={"ROFI_PASSWORD": "fixture-master-password", "BW_UNLOCK_SESSION": "fresh-session"},
    )
    successful(result)
    unlock = next(call for call in calls if call["args"][0] == "unlock")
    assert unlock["args"] == ["unlock", "--raw", "--passwordenv", "BW_PASSWORD"]
    assert unlock["password_ok"] and "fixture-master-password" not in unlock["args"]
    assert unlock["nointeraction"] == "true"
    assert all("--session" not in call["args"] for call in calls)
    assert (runtime / "session").read_text().startswith("fresh-session ")
    assert all(message != "expired-session" for message in (runtime / "session").read_text().split())
    assert any(call["session"] == "fresh-session" and call["args"][0] == "sync" for call in calls)
    assert b"fixture-password" not in (cache / "logins.gpg").read_bytes()
    assert any(call["kind"] == "password" for call in rofi_calls)

    # A changed server is configured only before login.
    result, runtime, _, calls, rofi_calls, _ = scenario(
        "configure-unauthenticated-server",
        env={
            "BW_STATUS": "unauthenticated",
            "BW_SERVER_URL": "https://old.example.invalid",
            "BW_LOGIN_SESSION": "sso-session-key",
        },
    )
    successful(result)
    setters = [call for call in calls if len(call["args"]) == 3 and call["args"][:2] == ["config", "server"]]
    assert len(setters) == 1 and setters[0]["args"][-1] == "https://vault.bitwarden.eu"
    login = next(call for call in calls if call["args"][0] == "login")
    assert login["args"] == ["login", "--sso", "--raw"]
    assert login["nointeraction"] == "false" and login["stdin_tty"] and login["stderr_tty"]
    terminal = json.loads(alacritty_log.read_text().splitlines()[0])
    assert "Authenticator App MFA code:" in terminal["transcript"]
    assert "sso-session-key" not in terminal["transcript"]
    assert not list(runtime.glob(".sso.*")), "temporary SSO files survived success"

    # A changed server while logged in is visible and never triggers the forbidden setter.
    result, runtime, _, calls, rofi_calls, _ = scenario(
        "logged-in-server-mismatch",
        env={"BW_STATUS": "locked", "BW_SERVER_URL": "https://old.example.invalid"},
    )
    assert result.returncode != 0
    assert not any(len(call["args"]) == 3 and call["args"][:2] == ["config", "server"] for call in calls)
    assert not any(call["args"][0] == "unlock" for call in calls)
    assert not any(call["kind"] == "password" for call in rofi_calls)
    assert any("server mismatch" in call.get("message", "") for call in rofi_calls)
    assert not (runtime / "session").exists()

    # Use the SSO raw session when the installed CLI supplies one.
    result, runtime, _, calls, rofi_calls, _ = scenario(
        "sso-session",
        env={"BW_STATUS": "unauthenticated", "BW_LOGIN_SESSION": "sso-session-key"},
    )
    successful(result)
    login = next(call for call in calls if call["args"][0] == "login")
    assert login["args"] == ["login", "--sso", "--raw"] and login["nointeraction"] == "false"
    assert any(call["session"] == "sso-session-key" and call["args"][0] == "sync" for call in calls)
    assert not any(call["kind"] == "password" for call in rofi_calls)
    assert (runtime / "session").read_text().startswith("sso-session-key ")

    # If SSO returns no raw key, the GUI master-password prompt unlocks via --passwordenv only.
    result, runtime, _, calls, rofi_calls, _ = scenario(
        "sso-unlock",
        env={
            "BW_STATUS": "unauthenticated",
            "BW_LOGIN_SESSION": "",
            "ROFI_PASSWORD": "fixture-master-password",
            "BW_UNLOCK_SESSION": "unlock-session-key",
            "BW_SESSION": "ambient-session-must-not-be-used",
        },
    )
    successful(result)
    login = next(call for call in calls if call["args"][0] == "login")
    assert login["nointeraction"] == "false" and login["stdin_tty"] and login["stderr_tty"]
    assert alacritty_log.exists(), "SSO without a returned key skipped the authentication terminal"
    unlock = next(call for call in calls if call["args"][0] == "unlock")
    assert unlock["args"] == ["unlock", "--raw", "--passwordenv", "BW_PASSWORD"]
    assert unlock["password_ok"] and "fixture-master-password" not in unlock["args"]
    assert unlock["nointeraction"] == "true"
    assert all("--session" not in call["args"] for call in calls)
    assert all(call["session"] != "ambient-session-must-not-be-used" for call in calls)
    assert (runtime / "session").read_text().startswith("unlock-session-key ")
    assert any(call["kind"] == "password" for call in rofi_calls)
    assert not list(runtime.glob(".sso.*")), "temporary SSO files survived empty-session unlock"

    # Canceling the GUI prompt stops cleanly without unlocking, syncing, or caching a key.
    result, runtime, _, calls, _, _ = scenario(
        "cancel-password",
        env={"BW_STATUS": "unauthenticated", "BW_LOGIN_SESSION": "", "ROFI_CANCEL_PASSWORD": "1"},
    )
    successful(result)
    assert not any(call["args"][0] in ("unlock", "sync") for call in calls)
    assert not (runtime / "session").exists()

    # Alt+y sync neither prompts nor changes the session timestamp.
    timestamp = int(time.time()) - 600
    result, runtime, cache, calls, rofi_calls, _ = scenario(
        "sync-lifetime",
        session="sync-session",
        timestamp=timestamp,
        cached=True,
        env={"ROFI_MENU_CODES": "10,1"},
    )
    successful(result)
    assert [call["args"][0] for call in calls] == ["sync", "list"]
    assert (runtime / "session").read_text() == f"sync-session {timestamp}\n"
    assert not any(call["kind"] == "password" for call in rofi_calls)
    assert b"fixture-password" not in (cache / "logins.gpg").read_bytes()

    # A failed Alt+y sync leaves a usable encrypted cache/session and reports the failure in rofi.
    timestamp = int(time.time()) - 600
    result, runtime, cache, calls, rofi_calls, _ = scenario(
        "sync-failure",
        session="usable-session",
        timestamp=timestamp,
        cached=True,
        env={"ROFI_MENU_CODES": "10,1", "BW_FAIL_ACTION": "sync"},
    )
    successful(result)
    assert [call["args"][0] for call in calls] == ["sync"]
    assert (runtime / "session").read_text() == f"usable-session {timestamp}\n"
    assert (cache / "logins.gpg").read_bytes() == encrypted(fixture_json)
    assert any(call.get("message") == "Bitwarden sync failed; the cached vault was kept" for call in rofi_calls)
    assert not any(call["kind"] == "password" for call in rofi_calls)

    # A failed CLI lock still clears the local key before surfacing the error.
    result, runtime, _, calls, rofi_calls, _ = scenario(
        "lock-failure",
        session="lock-session",
        cached=True,
        env={"ROFI_MENU_CODES": "13", "BW_FAIL_ACTION": "lock"},
    )
    assert result.returncode != 0
    lock = next(call for call in calls if call["args"][0] == "lock")
    assert not lock["session_file_exists"]
    assert not (runtime / "session").exists()
    assert any(call.get("message") == "Bitwarden lock failed" for call in rofi_calls)

    # A wrong MFA token fails visibly in the native terminal and leaves no temporary key.
    result, runtime, _, calls, rofi_calls, _ = scenario(
        "sso-wrong-token",
        env={"BW_STATUS": "unauthenticated", "BW_LOGIN_SESSION": "must-not-cache", "ALACRITTY_MFA_RESPONSE": "wrong"},
    )
    assert result.returncode != 0
    assert any(call.get("message") == "Bitwarden SSO login failed" for call in rofi_calls)
    assert "Invalid authenticator code" in json.loads(alacritty_log.read_text().splitlines()[0])["transcript"]
    assert not (runtime / "session").exists()
    assert not list(runtime.glob(".sso.*")), "temporary SSO files survived failed login"
    assert not any(call["args"][0] in ("unlock", "sync") for call in calls)

    # Closing the terminal before the status file exists is a clean cancellation.
    result, runtime, _, calls, rofi_calls, _ = scenario(
        "sso-cancel-terminal",
        env={"BW_STATUS": "unauthenticated", "ALACRITTY_CLOSE": "1"},
    )
    successful(result)
    assert not any(call["args"][0] in ("login", "unlock", "sync") for call in calls)
    assert not rofi_calls
    assert not (runtime / "session").exists()
    assert not list(runtime.glob(".sso.*")), "temporary SSO files survived cancellation"

assert 'hl.bind("CTRL + J", hl.dsp.exec_cmd("bwmenu --auto-lock 86400"))' in BINDINGS
assert 'hl.bind(mod .. " + J", hl.dsp.exec_cmd("bwmenu --auto-lock 86400"))' in BINDINGS
print("PASS: fake-only Bitwarden auth, encrypted offline cache, fuzzy menu, 24h expiry, sync, cancellation, and visible failures")
