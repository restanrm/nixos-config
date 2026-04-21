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

    # Noctalia
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
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
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/hp-ara

        sekoia-io-agent.nixosModules.default

        ({pkgs, ...}: {
          nixpkgs.overlays = [
            (final: prev: {
              sekoia-io-agent = sekoia-io-agent.packages.${prev.system}.default;
            })
          ];
        })

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.nrm = import ./users/nrm;
          home-manager.backupFileExtension = "hm-back";
        }
      ];
    };
  };
}
