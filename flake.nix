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

    sops-nix.url = "github:Mic92/sops-nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote"; 
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, impermanence, sops-nix, lanzaboote, ... }@inputs: {
    nixosConfigurations.nixy = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        sops-nix.nixosModules.sops 
        lanzaboote.nixosModules.lanzaboote
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.alunity = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
        ./configuration.nix          # Your main logic
        ./disko-config.nix           # The drive layout we discussed
        ./hardware-configuration.nix # Generated on the machine
      ];
    };
  };
}
