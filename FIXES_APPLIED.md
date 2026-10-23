# ZSH Configuration Fixes Applied

## Nixpkgs update: Fabric rebuild failure

Azure CLI depends on Fabric 3.2.3, which is incompatible with Invoke 3.
The Python package overlay in `flake.nix` pins Invoke to 2.2.0, including
transitive users such as Paramiko, without allowing broken packages.
Remove this override when nixpkgs provides compatible versions.

Validation: Fabric builds with 317 tests passing (6 skipped, 85 deselected by
upstream packaging).

## MinIO client replacement

`minio-client`, marked insecure because upstream abandoned maintenance, is replaced
by PGSTY's maintained [`mcli`](https://github.com/pgsty/mc) release
`RELEASE.2026-10-18T00-00-00Z`. The local package in
`modules/home/applications/mcli.nix` installs the checksummed official Linux amd64
binary for `hp-ara`; update its release URL, version and hash together.

Both `mcli` and the compatibility symlink `mc` are available. Existing `~/.mc`
configuration is retained; no configuration files or credentials are migrated.
The package checks both executable names with `--version` during installation.
No insecure-package allowance or Silo server is added.

Validation: the package builds and both executable version checks pass.
Full `hp-ara` system evaluation and build succeed. Activation has not been
performed because interactive sudo authentication is required.

## SEKOIA agent repository migration

`flake.nix` now uses `git+ssh://git@github.com/SekoiaLab/nixpkgs.git`, locked at
`8bd568cdb8518346fcfdc712a9c88a9dff455a87`, with nixpkgs following this system's
input. SSH access to the repository is required for future input updates.
Only `nixosModules.sekoia-agent` is imported; JumpCloud is not enabled.
The service configuration now uses `services.sekoia-agent`, preserving its
existing settings and both `SEKOIAEndpointAgent` systemd service names.

The new upstream still declares version 1.11.0 with a stale checksum for
`agent-latest`, which now serves v1.12.0. The `package` override in
`modules/system/work/sekoia-io-agent.nix` pins the verified download hash and
checks the embedded version without running the agent. Remove the override
when upstream fixes its checksum. The binary was fetched from the official HTTPS
endpoint; no independent publisher signature was verified. The mutable URL will
fail checksum verification again if its contents change.

The new module seeds its binary and configuration in `/var/lib/endpoint-agent`
only when absent, preserving existing runtime files. Subsequent declarative
package/settings changes do not automatically overwrite that existing state.
Validation: the migrated agent package builds, and evaluation checks confirm
version 1.12.0, both enabled services, and no imported JumpCloud service.
Activation requires interactive sudo authentication; run `./rebuild.sh` locally.

## Load-sensitive HTTP/2 build test

The full build failed in `httpcore2`'s `test_h2_timeout_during_request`, a 10 ms
cancellation-timing test. All other failures in that build were dependency
failures. Retrying the unchanged package alone with `--max-jobs 1 --cores 2`
passed all 244 tests. No package code or test exclusions were changed.

For a lower-contention system build, use:

```bash
nix build --no-link --max-jobs 4 --cores 2 .#nixosConfigurations.hp-ara.config.system.build.toplevel
```

The full system build completed successfully with these limits, and an offline
repeat confirmed all outputs are available. `./rebuild.sh` can now reuse those
outputs and activate the system with interactive sudo authentication.
The upstream SEKOIA module emits non-fatal `StartLimitInterval` deprecation
warnings; these do not block the build.

## Summary

Two critical issues from the zsh migration have been fixed:

1. **Custom PATH variables not working** - Binaries from `$GOPATH/bin`, `~/.cargo/bin`, `~/.krew/bin` were not accessible
2. **TTY1 logout required** - Needed to logout and login for configuration changes to take effect

## Root Causes

### Issue #1: PATH Not Working
- **Problem**: PATH was set in `sessionVariables` with shell variable expansions (`$GOPATH`)
- **Why**: `sessionVariables` are evaluated at BUILD-TIME, but shell variables only exist at RUNTIME
- **Result**: Variables expanded to empty strings, breaking PATH

### Issue #2: TTY1 Logout Required
- **Problem**: After `nixos-rebuild switch`, running zsh shell kept old config in memory
- **Why**: File changes on disk don't affect already-running processes
- **Result**: Had to logout (kill shell) and login (start new shell) to pick up changes

## Solutions Implemented

### Fix #1: Move PATH to initExtra
```nix
# BEFORE (broken)
sessionVariables = {
  PATH = "$GOPATH/bin:...";  # Evaluated at build-time ❌
};

# AFTER (fixed)
initExtra = ''
  export PATH="$GOPATH/bin:..."  # Evaluated at runtime ✅
'';
```

**Benefits**:
- Variables expand properly at shell startup
- All custom paths now work: Go, Rust, Kubernetes, Nix, Arkade, etc.
- Same approach as original chezmoi config

### Fix #2: Helper Functions
Added two new shell functions to eliminate logout requirement:

#### `zreload()`
- Quick shell reload without rebuild
- Restarts zsh with `exec zsh`
- Preserves: current directory, history, environment
- Use case: Testing config changes quickly

#### `rebuild()`
- Complete workflow: rebuild + auto-reload
- Runs: `sudo nixos-rebuild switch --flake /home/nrm/nixos#hp-ara`
- Then: automatically reloads zsh
- Use case: Applying system configuration changes
- Result: **No logout needed!**

## Files Changed

### Modified
- `modules/home/zsh.nix`
  - Moved PATH from `sessionVariables` to `initExtra`
  - Added `zreload()` function
  - Added `rebuild()` function

### Added
- `ZSH_FIXES.md` - Comprehensive troubleshooting guide
- `qrebuild` - Helper script for quick rebuilds

## PATH Now Includes

```
$GOPATH/bin                    # Go binaries
/opt/shadow-tech/              # Custom tools
$HOME/bin                      # User binaries
$HOME/.local/bin               # Local packages
/usr/local/bin                 # System binaries
${KREW_ROOT:-$HOME/.krew}/bin  # Kubernetes plugins
$HOME/.arkade/bin              # Arkade tools
$HOME/.cargo/bin               # Rust binaries
$HOME/.nix-profile/bin         # Nix profile packages
(plus original system paths)
```

## How to Apply

```bash
cd /home/nrm/nixos

# Step 1: Rebuild
sudo nixos-rebuild switch --flake .#hp-ara

# Step 2: Reload shell
exec zsh

# Step 3: Verify
which kubectl  # Should find it
echo $PATH     # Should show custom paths
```

## New Workflow

### Before (tedious)
```bash
vim modules/home/zsh/work.nix     # Edit config
nixos-rebuild switch --flake .#hp-ara
# ... wait for rebuild ...
logout                            # Or press Ctrl+D
# ... login again ...
```

### After (simple)
```bash
vim modules/home/zsh/work.nix     # Edit config
rebuild                           # Rebuilds + auto-reloads!
# All done, no logout needed
```

## Testing

After applying fixes, test with:

```bash
# Test 1: PATH includes custom directories
echo $PATH | tr ':' '\n' | grep -E "(go/bin|cargo|krew)"

# Test 2: Tools are findable
which kubectl
which go
which krew

# Test 3: Helper functions work
type rebuild    # Should show "is a shell function"
type zreload    # Should show "is a shell function"

# Test 4: Rebuild function works
rebuild --help  # Should show usage
```

## Migration Notes

This fix builds on the original chezmoi-to-NixOS migration:
- All functionality from chezmoi is preserved
- PATH handling now matches original behavior
- Workflow is actually faster than chezmoi (no need to init)

## Technical Details

### Why sessionVariables Don't Work for Dynamic Paths

home-manager's `programs.zsh.sessionVariables` generates:
```nix
# This is generated and evaluated at BUILD-TIME
export VARIABLE="value"
```

If you set:
```nix
sessionVariables = {
  PATH = "$GOPATH/bin:...";  # Nix tries to find $GOPATH variable
}
```

Nix evaluates this at build-time, not runtime, so:
- `$GOPATH` is treated as a Nix variable (not shell variable)
- Nix doesn't find it
- It becomes empty
- PATH breaks

### Solution: Use initExtra for Runtime Code

```nix
initExtra = ''
  export PATH="$GOPATH/bin:..."  # Stored as literal string
  # When zsh starts, this line runs and $GOPATH is expanded properly
''
```

## References

- **Original Migration**: `MIGRATION_ZSH.md`
- **Full Guide**: `ZSH_FIXES.md`
- **Implementation**: `modules/home/zsh.nix`

## Commit

```
commit 4753d7a
Author: Adrien Raffin <adrien.raffin@sekoia.io>
Date:   Tue Jun 9 15:49:55 2026 +0200

    fix: resolve custom PATH not working and improve rebuild workflow

    - Moved PATH from sessionVariables to initExtra (enables runtime expansion)
    - Added zreload() function for quick config reload
    - Added rebuild() function for rebuild + auto-reload workflow
    - Both preserve current directory and shell history
```

---

**Status**: ✅ All changes committed and ready to apply

**Next Step**: Run `sudo nixos-rebuild switch --flake .#hp-ara` and enjoy the improved workflow!
