# `firefox-nix-darwin`

`firefox-nix-darwin` is simple home-manager module/overlay for Firefox browser with [policy][firefox-policies] support.

## How to use it

Minimal configuration example using flakes, nix-darwin and home-manager. For more information about [Firefox policies official support page from Mozilla][firefox-policies] and [home-manager options for Firefox][home-manager-firefox].

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    home-manager.url = "github:nix-community/home-manager";
    firefox-nix-darwin.url = "github:atahanyorganci/firefox-nix-darwin";
  };
  outputs = { self, darwin, home-manager, nixpkgs, firefox-darwin, ... }@inputs:
    let
      # replace this with your username and hostname obviously
      hostname = "Atahan-Macbook-Pro";
      username = "atahan";
    in
    {
      darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
        system = "aarch64-darwin"; # or "x86_64-darwin" both are supported
        modules = [
          home-manager.darwinModules.home-manager
          {
            imports = [
              # Importing `firefox-darwin` module will setup the nixpkgs Firefox package
              firefox-darwin.darwinModules.home-manager
            ];
            home-manager.users.${username} = {
              programs.firefox = {
                # This will install the Firefox package from `firefox-nix-darwin` module
                enable = true;
                policies = {
                  # This will enable the policies.json file for Firefox
                  # These will disable auto updates for Firefox since it's managed by Nix
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

The entire overlay is controlled by `latest-firefox-version` script in the devShell that fetches release information from Mozilla and puts the version, URL and SHA256 in [`firefox.json`](./packages/firefox-bin/firefox.json). The JSON gets imported by a Nix expression and the values are used to build a derivation. A GitHub action runs `ci` script in the devShell to update `firefox.json` and commit it to the repository.

[firefox-policies]: https://support.mozilla.org/en-US/kb/customizing-firefox-using-policiesjson
[home-manager]: https://home-manager-options.extranix.com/?query=programs.firefox.policies
