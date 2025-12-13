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
    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
