{
  description = "My ephemeral NixOS configuration";

  inputs = {
    # 1. The main NixOS package source
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 2. Disko for partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # 3. Impermanence for 'Erase Your Darlings'
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, disko, impermanence, ... }@inputs: {
    # Replace 'my-laptop' with your actual desired hostname
    nixosConfigurations.my-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./configuration.nix          # Your main logic
        ./disko-config.nix           # The drive layout we discussed
        ./hardware-configuration.nix # Generated on the machine
      ];
    };
  };
}
