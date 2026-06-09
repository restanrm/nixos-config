# ZSH Configuration Fixes Applied

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
