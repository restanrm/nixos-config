# ZSH Configuration Fixes - Quick Guide

## Issues Fixed

### 1. ✅ Custom PATH Variables Not Working

**Problem**: Binaries in `$GOPATH/bin`, `~/.cargo/bin`, `~/.krew/bin`, etc. were not accessible.

**Root Cause**: The PATH variable was being set in `sessionVariables` at build-time, but it contained shell variable expansions like `$GOPATH` that only exist at runtime.

**Solution**: Moved PATH setup from `sessionVariables` to `initExtra` where it's evaluated at shell startup. This allows proper runtime expansion of variables.

**What's now included in PATH**:
- `$GOPATH/bin` - Go binaries
- `/opt/shadow-tech/` - Custom tools
- `$HOME/bin` - User binaries
- `$HOME/.local/bin` - Local installations
- `/usr/local/bin` - System binaries
- `${KREW_ROOT:-$HOME/.krew}/bin` - Kubernetes plugin manager
- `$HOME/.arkade/bin` - Arkade tools
- `$HOME/.cargo/bin` - Rust binaries
- `$HOME/.nix-profile/bin` - Nix profile binaries

### 2. ✅ Need to Logout to Apply Configuration Changes

**Problem**: After running `nixos-rebuild switch`, you had to logout from TTY1 for changes to take effect.

**Solution**: Added two convenient helper functions to reload your shell:

#### Option A: Just Reload Config (Recommended for Testing)
```bash
zreload
```
This restarts your zsh shell with the new configuration applied, keeping your current directory and history.

#### Option B: Rebuild + Auto-reload (Best for Full Updates)
```bash
rebuild
```
This:
1. Runs `sudo nixos-rebuild switch`
2. Automatically reloads your zsh shell when done
3. Shows you emoji feedback at each step

#### Option C: Manual Rebuild (If You Prefer)
```bash
nixos-rebuild switch --flake /home/nrm/nixos#hp-ara
# Then run:
exec zsh    # or just: zreload
```

## How to Use

### Scenario 1: You've Updated Your Nix Configuration

```bash
# Edit your zsh.nix or other configs
vim /home/nrm/nixos/modules/home/zsh/work.nix

# Quick rebuild with auto-reload
rebuild
```

### Scenario 2: You're Testing Zsh Interactively

```bash
# Manually add a function or alias
alias mynewcmd='something'

# Test it out
mynewcmd

# Want to reload from disk config?
zreload
```

### Scenario 3: You're in a TTY and Need to Apply System Changes

```bash
# Just use the rebuild function
rebuild

# It will:
# 1. Rebuild your system ✓
# 2. Auto-reload zsh when done ✓
# 3. Keep you in the same shell without logging out ✓
```

## Verifying the Fix

### Test that PATH is Working

After rebuilding, verify your PATH contains the custom directories:

```bash
# Show your PATH
echo $PATH

# Verify specific tools are found
which go    # Should find Go binary if installed
which kubectl  # Should find kubectl if installed
which krew  # Should find krew if installed
```

### Test Helper Functions

```bash
# These should now be available:
zreload     # Reload zsh
rebuild     # Rebuild + reload
archive     # Archive files
kex         # Kubernetes exec
work        # Git worktree
endwork     # End git worktree
# ... and all other functions
```

## What Changed in the Configuration

### File: `modules/home/zsh.nix`

**Before** (broken):
```nix
sessionVariables = {
  PATH = "$GOPATH/bin:...";  # Build-time evaluation - doesn't work!
};
```

**After** (fixed):
```nix
initExtra = ''
  # Setup PATH with all custom directories at runtime
  export PATH="$GOPATH/bin:..."  # Runtime evaluation - works!
''
```

### New Helper Functions

Added two new functions to your shell:

1. **`zreload`** - Quick reload without logging out
   ```bash
   function zreload() {
     echo "🔄 Reloading zsh configuration..."
     exec zsh
   }
   ```

2. **`rebuild`** - Rebuild + auto-reload in one command
   ```bash
   function rebuild() {
     echo "🔨 Rebuilding NixOS configuration..."
     sudo nixos-rebuild switch --flake /home/nrm/nixos#hp-ara "$@" && {
       echo "✅ Rebuild successful!"
       echo "🔄 Reloading zsh..."
       sleep 1
       exec zsh
     } || echo "❌ Rebuild failed"
   }
   ```

## Troubleshooting

### PATH still not working after rebuild?

1. Make sure you ran `rebuild` or `nixos-rebuild switch`
2. Restart your shell: `exec zsh`
3. Check PATH: `echo $PATH`
4. If still broken, verify GOPATH is set: `echo $GOPATH`

### Can't use `rebuild` function?

You need to reload your shell first:
```bash
# If rebuild doesn't exist yet:
exec zsh
# Then try again:
rebuild
```

### Getting "command not found" for custom tools?

Check if the tool is actually installed in that path:
```bash
ls $GOPATH/bin/
ls ~/.cargo/bin/
ls ~/.krew/bin/
```

If the directory is empty, install the tools first, then reload:
```bash
# Install something
go install github.com/some/tool@latest

# Reload shell to get new PATH
zreload
```

## Next Steps

1. **Rebuild your system**:
   ```bash
   rebuild
   ```

2. **Test that everything works**:
   ```bash
   echo $PATH
   which kubectl  # or any binary you expect to be available
   ```

3. **Enjoy faster iteration**:
   - Edit configs: `vim modules/home/zsh/work.nix`
   - Rebuild & reload: `rebuild`
   - No more TTY logout needed!

## Notes

- The `rebuild` function uses hardcoded path `/home/nrm/nixos#hp-ara` - this is intentional for convenience
- Both `zreload` and `rebuild` use `exec zsh` which restarts the shell but keeps your history and current directory
- The deprecation warning about `initExtra` is harmless and expected for home-manager
- All custom PATH additions now happen at shell startup, so they're always available

Enjoy your improved workflow! 🚀
