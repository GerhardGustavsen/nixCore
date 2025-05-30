{
  description = "Gerhard’s NixOS + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      # NixOS system configuration
      # NixOS system configuration
      nixosConfigurations = {
        nix = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix

            # Enable Home Manager as a NixOS module
            home-manager.nixosModules.home-manager

            # Configure Home Manager user 'gg' to import home.nix
            ({ config, lib, pkgs, ... }: {
              home-manager.users.gg = {
                # Load your home.nix as a Home Manager module
                imports = [ ./home.nix ];
              };
            })
          ];
        };
      };

      # Standalone Home Manager configuration (useful for non-NixOS or manual switches)
      homeConfigurations = {
        gg = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };
      };
    };
}
