{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };
  outputs = { nixpkgs, ... }:
    let
      systems = nixpkgs.lib.platforms.all;
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      darwin = nixpkgs.lib.platforms.darwin;
      eachDarwinSystem = f: nixpkgs.lib.genAttrs darwin (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = import ./overlays/firefox-bin.nix;
      formatter = eachSystem (pkgs: pkgs.nixpkgs-fmt);
      packages = eachDarwinSystem (pkgs: rec {
        default = firefox-bin;
        firefox-bin = pkgs.callPackage ./packages/firefox-bin { };
      });
      darwinModules.home-manager = import ./modules/home-manager.nix;
      devShells = eachSystem (pkgs:
        let
          latest-firefox-version = pkgs.writeShellScriptBin "latest-firefox-version" ''
            set -e
            version=$(curl -s 'https://product-details.mozilla.org/1.0/firefox_versions.json' | jq -r '.LATEST_FIREFOX_VERSION')
            echo "Last version of Firefox is $version" >&2
            name="Firefox-$version.dmg"
            url="https://download-installer.cdn.mozilla.net/pub/firefox/releases/$version/mac/en-GB/Firefox%20$version.dmg"
            sha256=$(nix-prefetch-url --name $version $url)
            echo "SHA256 of $name is $sha256" >&2
            jq -n -r \
              --arg version "$version" \
              --arg sha256 "$sha256" \
              --arg url "$url" \
              '{version: $version, url: $url, sha256: $sha256}'
          '';
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              jq
              curl
              latest-firefox-version
            ];
          };
        });
    };
}
