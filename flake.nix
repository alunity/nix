{
  description = "Ephemeral NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
  let
    system = "x86_64-linux";
    # We define pkgs here to ensure Home Manager uses the exact same nixpkgs as the system
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # 1. System Configuration (nixos-rebuild switch)
    nixosConfigurations.nixy = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops 
        inputs.lanzaboote.nixosModules.lanzaboote
        
        # Keep this if you want HM to be part of the system build, 
        # or remove it to keep them 100% isolated.
        inputs.home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.alunity = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }

        ./configuration.nix
        ./disko-config.nix
        ./hardware-configuration.nix
      ];
    };

    # 2. Standalone Home Manager (home-manager switch)
    homeConfigurations."alunity" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [ 
        ./home.nix 
      ];
    };
  };
}
