{
  description = "Nixos config flake";

  inputs = {
    # Unstable NixPkg channel
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable";

    # Home-Manager Flake
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hardware Flakes
    nixos-hardware.url = "git+https://github.com/NixOS/nixos-hardware?ref=master";
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs:
    let
      mkSystem = name: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${name}/configuration.nix
          inputs.home-manager.nixosModules.default
          { system.configurationRevision = self.rev or self.dirtyRev or "dirty"; }
        ];
      };
    in {
      nixosConfigurations = {
        lap-nix    = mkSystem "lap-nix";
        desk-nix   = mkSystem "desk-nix";
        server-nix = mkSystem "server-nix";
      };
    };
}
