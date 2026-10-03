{
  inputs = {
    # This is pointing to an unstable release.
    # If you prefer a stable release instead, you can this to the latest number shown here: https://nixos.org/download
    # i.e. nixos-24.11
    # Use `nix flake update` to update the flake to the latest revision of the chosen release channel.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sekoia-io-agent.url = "git+ssh://git@github.com/r1chev/flake-sekoia-io-agent.git";

    # Pin the latest upstream revision and compatible plugin code for rollout.
    noctalia = {
      url = "github:noctalia-dev/noctalia/064476d48818896ef0dd93f42ccb632dd8f52c55";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-plugins = {
      url = "github:noctalia-dev/community-plugins/01c3ad4fc2da5d1c1ef03bff7cbfe44b759f2ce6";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    sekoia-io-agent,
    home-manager,
    ...
  }: {
    # NOTE: 'nixos' is the default hostname
    nixosConfigurations.hp-ara = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/hp-ara

        {nixpkgs.hostPlatform = "x86_64-linux";}

        sekoia-io-agent.nixosModules.default

        ({pkgs, ...}: {
          nixpkgs.overlays = [
            (final: prev: {
              sekoia-io-agent = sekoia-io-agent.packages.${prev.stdenv.hostPlatform.system}.default;
            })
          ];
        })

        home-manager.nixosModules.home-manager
        ({...}: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit inputs;
            context = {
              work = true;
              hostType = "desktop";
            };
          };
          home-manager.users.nrm = import ./users/nrm;
          home-manager.backupFileExtension = "hm-back";
        })
      ];
    };
  };
}
