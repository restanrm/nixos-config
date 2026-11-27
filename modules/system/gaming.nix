{pkgs, ...}: {
  programs.steam.enable = true;
  nixpkgs.config.allowUnfreePackages = ["steam" "steam-unwrapped"];

  environment.systemPackages = with pkgs; [
    (retroarch.withCores (cores: [cores.nestopia cores.bsnes cores.mgba]))
    cemu
    dolphin-emu
  ];

  services.udev.packages = [pkgs.dolphin-emu];
}
