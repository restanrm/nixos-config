let
  flake = builtins.getFlake ("path:" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  work = flake.nixosConfigurations.hp-ara.config;
  family = flake.nixosConfigurations.tortuga.config;
  workHome = work.home-manager.users.nrm;
  personalHome = family.home-manager.users.nrm;
  names = hm: map lib.getName hm.home.packages;
  workOnly = ["pinniped" "azure-cli"];
  systemPackages = map lib.getName family.environment.systemPackages;
  chromiumWidevine = flake.nixosConfigurations.tortuga.pkgs.chromium.override {enableWideVine = true;};
  personalTools = ["age" "alacritty" "bat" "jq" "kubectl" "mcli" "pdftk" "pi-coding-agent" "sops" "stern" "uv" "vault" "viddy" "wget" "zellij"];
in
  assert builtins.attrNames family.home-manager.users == ["nrm"];
  assert family.services.displayManager.gdm.enable && family.services.desktopManager.gnome.enable;
  assert family.services.displayManager.autoLogin.enable && family.services.displayManager.autoLogin.user == "nrm";
  assert family.services.openssh.enable && builtins.elem 22 family.networking.firewall.allowedTCPPorts;
  assert family.services.openssh.settings.AllowUsers == ["nrm@192.168.1.0/24"];
  assert family.services.openssh.settings.PermitRootLogin == "no";
  assert family.services.openssh.settings.PubkeyAuthentication;
  assert !family.services.openssh.settings.PasswordAuthentication && !family.services.openssh.settings.KbdInteractiveAuthentication;
  assert family.users.users.nrm.openssh.authorizedKeys.keys != [];
  assert family.programs.steam.enable && family.hardware.graphics.enable32Bit && !work.programs.steam.enable;
  assert lib.all (name: builtins.elem name systemPackages) ["retroarch-with-cores" "cemu" "dolphin-emu" "chromium" "pavucontrol" "curl" "podman"];
  assert family.nixpkgs.config.allowUnfree;
  assert builtins.elem chromiumWidevine.drvPath (map (pkg: pkg.drvPath) (builtins.filter (pkg: lib.getName pkg == "chromium") family.environment.systemPackages));
  assert family.virtualisation.podman.enable && !family.virtualisation.docker.enable;
  assert family.networking.networkmanager.enable && family.hardware.enableRedistributableFirmware;
  assert builtins.elem "networkmanager" family.users.users.nrm.extraGroups;
  assert workHome.wayland.windowManager.hyprland.enable && !personalHome.wayland.windowManager.hyprland.enable;
  assert work.services.sekoia-agent.enable && !(family.services ? sekoia-agent);
  assert lib.all (name: builtins.elem name (names workHome) && !builtins.elem name (names personalHome)) workOnly;
  assert lib.all (name: builtins.elem name (names personalHome)) personalTools;
  assert lib.all (hm: builtins.elem "direnv" (names hm) && builtins.elem "direnv" hm.programs.zsh.oh-my-zsh.plugins) [workHome personalHome];
  assert workHome.programs.zsh.oh-my-zsh.theme == "robbyrussell";
  assert personalHome.programs.zsh.oh-my-zsh.theme == "gallifrey";
  assert builtins.elem (toString flake.nixosConfigurations.tortuga.pkgs.dig) (map toString personalHome.home.packages);
  assert !(lib.hasInfix "function pdftk()" personalHome.programs.zsh.initContent);
  assert workHome.programs.ssh.settings ? "delivery.sekoia.io";
  assert builtins.attrNames personalHome.programs.ssh.settings == ["restanrm.fr"];
  assert workHome.programs.git.settings.user.email == "adrien.raffin@sekoia.io";
  assert personalHome.programs.git.settings.user
  == {
    name = "Adrien Raffin";
    email = "raffinadrien@gmail.com";
  };
  assert personalHome.programs.jujutsu.settings.user == personalHome.programs.git.settings.user;
  assert lib.hasInfix "/home/nrm/nixos#hp-ara" workHome.programs.zsh.initContent;
  assert lib.hasInfix "/home/nrm/nixos#tortuga" personalHome.programs.zsh.initContent; "PASS: work and family host profiles"
