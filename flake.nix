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

    # Keep the legacy shell and its dependencies frozen during the base upgrade.
    noctalia-nixpkgs.url = "github:NixOS/nixpkgs/549bd84d6279f9852cae6225e372cc67fb91a4c1";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/eb2b53ddaa7564f5c93031cbe65cd5b6ef3c12a9";
      inputs.nixpkgs.follows = "noctalia-nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs/d3e26ccd9eecde9139be00caf5dc2d4260fb31ee";
      inputs.nixpkgs.follows = "noctalia-nixpkgs";
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
