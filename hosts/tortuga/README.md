# tortuga

Personal family PC: GNOME, GDM, Firefox, Chromium, and PulseAudio Volume Control (for PipeWire). Home Manager manages
`nrm`'s Git, SSH, Zsh, Neovim, Alacritty, and CLI tools. The system includes Noto fonts, Noto Color Emoji, and Nerd Fonts. Add family members as Standard users in GNOME Settings → System → Users so they have separate files and
settings without admin access. Home Manager only manages `nrm`.

The work and Hyprland profiles from `hp-ara` are not used. `tortuga` omits Pinniped, Azure CLI, Sekoia services and SSH
settings. Git and Jujutsu use `Adrien Raffin <raffinadrien@gmail.com>`. Vault stays available for the personal Vault
instance, and `kubectl` is shared. `nrm` also gets age, bat, dig, jq, mcli, PDFtk, Pi (`pi`), SOPS, Stern, uv, Viddy,
Wget, and Zellij. Curl is already installed system-wide. Podman can run containers without a Docker daemon.
Unfree packages are allowed on `tortuga`, and Chromium includes Widevine for protected media playback.

## Gaming

`modules/system/gaming.nix` installs Steam, RetroArch (with NES, SNES, and Game Boy / Game Boy Advance cores),
Cemu (Wii U), and Dolphin (GameCube and Wii) for all users. Games, ROMs, and console firmware are not included.

## Before installing

1. Back up Windows. If BitLocker or Device Encryption is enabled, save the recovery key off the PC.
2. In Windows Disk Management, shrink C: to 250 GiB. The shrink amount is the displayed total size in MB minus
   `256000`. Leave the freed space unallocated and keep the Windows EFI, reserved, and recovery partitions intact.
3. Shut down fully and boot the NixOS USB in UEFI mode. Verify the new partition layout before making any disk changes.

Use the verified free space for a separate NixOS EFI partition and a Linux root partition. The firmware boot menu can
select either operating system without making NixOS depend on the Windows EFI partition. If Windows is removed later,
its old C: partition can become a Linux data volume without moving the NixOS root partition.

## Flake

Evaluate the configuration from the repository root:

```sh
nix eval --raw .#nixosConfigurations.tortuga.config.system.build.toplevel.drvPath
nix eval --impure --file scripts/check-host-profiles.nix
```

`hardware-configuration.nix` records `tortuga`'s filesystem UUIDs. For a reinstall, verify the mount points match the
config: mount the NixOS root at `/mnt` and the **NixOS** EFI partition at `/mnt/boot`, not the Windows EFI partition.
If the filesystems were recreated, regenerate the hardware config with
`nixos-generate-config --root /mnt --show-hardware-config`. From the repository root on the live system, run:

```sh
nixos-install --no-root-passwd --no-channel-copy --flake ".#tortuga"
nixos-enter --root /mnt -c 'passwd nrm'
```

Use a new password for `nrm`; do not reuse the live USB password.
Keep the repository in `/home/nrm/nixos` on the installed system for the `rebuild` shell function.

## After first boot

GDM automatically signs in as `nrm`. Anyone who can boot `tortuga` can access that session and its files.

Keep Ethernet connected until Wi-Fi works. In GNOME **Settings → Wi-Fi**, choose the home network,
and enter its password there. NetworkManager saves the connection locally; don't put the Wi-Fi password in this repo.
Disconnect Ethernet and check that the machine can still reach the internet. Pair Bluetooth devices later in GNOME
Settings as needed.

## SSH access

SSH allows only `nrm` from `192.168.1.0/24`, using the Ed25519 key for `nrm@thinkpad-ara`. Password and root login are
blocked. From `tortuga`'s console, with the updated repo in `~/nixos`, run
`sudo nixos-rebuild test --flake ~/nixos#tortuga` to try the configuration without changing the next boot.

Get the current IP with `hostname -I` and the server fingerprint with
`ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`. From the laptop, use
`ssh -o HostKeyAlias=tortuga-installed -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 nrm@<tortuga-ip>` and check the
fingerprint before accepting it. The live USB used a different host key. Do not forward port 22 from the router.

Once the key works, run `sudo nixos-rebuild switch --flake ~/nixos#tortuga` to keep SSH enabled across reboots.
