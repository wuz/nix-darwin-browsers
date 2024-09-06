{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };
  outputs = { systems, nixpkgs, ... }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlay = import ./overlay.nix;
      formatter = eachSystem (pkgs: pkgs.nixpkgs-fmt);
      devShells = eachSystem (pkgs:
        let
          curl = "${pkgs.curl}/bin/curl";
          jq = "${pkgs.jq}/bin/jq";
          update-firefox-version = pkgs.writeShellScriptBin "update-firefox-version" ''
            set -e
            version=$(${curl} 'https://product-details.mozilla.org/1.0/firefox_versions.json' | ${jq} -r '.LATEST_FIREFOX_VERSION')
            echo "Last version of Firefox is $version"
            url="https://download-installer.cdn.mozilla.net/pub/firefox/releases/$version/mac/en-GB/Firefox%20$version.dmg"
            sha256=$(nix-prefetch-url --name "Firefox-$version.dmg" $url)
            ${jq} -n \
              --arg version "$version" \
              --arg sha256 "$sha256" \
              --arg url "$url" \
              '{version: $version, url: $url, sha256: $sha256}' > firefox.json
          '';
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              update-firefox-version
            ];
          };
        });
    };
}
