# `floorp-nix-darwin`

`floorp-nix-darwin` is simple home-manager module/overlay for Floorp browser with [policy][floorp-policies] support.

## How to use it

Minimal configuration example using flakes, nix-darwin and home-manager. For more information about [Floorp policies official support page from Mozilla][floorp-policies] and [home-manager options for Floorp][home-manager-floorp].

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    home-manager.url = "github:nix-community/home-manager";
    floorp-nix-darwin.url = "github:wuz/floorp-nix-darwin";
  };
  outputs = { self, darwin, home-manager, nixpkgs, floorp-darwin, ... }@inputs:
    let
      # replace this with your username and hostname obviously
      hostname = "spellbook";
      username = "wuz";
    in
    {
      darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
        system = "aarch64-darwin"; # or "x86_64-darwin" both are supported
        modules = [
          home-manager.darwinModules.home-manager
          {
            imports = [
              # Importing `floorp-darwin` module will setup the nixpkgs floorp package
              floorp-darwin.darwinModules.home-manager
            ];
            home-manager.users.${username} = {
              programs.floorp = {
                # This will install the floorp package from `floorp-nix-darwin` module
                enable = true;
                policies = {
                  # This will enable the policies.json file for floorp
                  # These will disable auto updates for floorp since it's managed by Nix
                  AppAutoUpdate = false;
                  DisableAppUpdate = true;
                };
              };
            };
          }
        ];
      };
    };
}
```

## How it works

The entire overlay is controlled by `latest-floorp-version` script in the devShell that fetches release information from Mozilla and puts the version, URL and SHA256 in [`floorp.json`](./packages/floorp-bin/floorp.json). The JSON gets imported by a Nix expression and the values are used to build a derivation. A GitHub action runs `ci` script in the devShell to update `floorp.json` and commit it to the repository.

[home-manager]: https://home-manager-options.extranix.com/?query=programs.floorp.policies
