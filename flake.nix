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

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: {
    nixosConfigurations.lap-nix = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/lap-nix/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };

    nixosConfigurations.desk-nix = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/desk-nix/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };

    nixosConfigurations.nix-server = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/nix-server/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
