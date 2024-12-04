{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };
  outputs =
    { nixpkgs, ... }:
    let
      systems = nixpkgs.lib.platforms.all;
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      darwin = nixpkgs.lib.platforms.darwin;
      eachDarwinSystem = f: nixpkgs.lib.genAttrs darwin (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = import ./overlays/default.nix;
      formatter = eachSystem (pkgs: pkgs.nixpkgs-fmt);
      packages = eachDarwinSystem (pkgs: rec {
        default = floorp-bin;
        floorp-bin = pkgs.callPackage ./packages/floorp-bin { };
        zen-browser-bin = pkgs.callPackage ./packages/zen-browser-bin { };
      });
      devShells = eachSystem (
        pkgs:
        let
          zen_manifest = "./packages/zen-browser-bin/zen-browser.json";
          floorp_manifest = "./packages/floorp-bin/floorp.json";
          latest-zen-version = pkgs.writeShellScriptBin "latest-zen-version" ''
            set -e
            version=$(curl -s 'https://api.github.com/repos/zen-browser/desktop/releases/latest' | jq -r '.tag_name')
            echo "Last version of zen-browser is $version" >&2
            name="Zen-$version.dmg"
            url="https://github.com/zen-browser/desktop/releases/download/$version/zen.macos-aarch64.dmg"
            sha256=$(nix-prefetch-url --name $version $url)
            echo "SHA256 of $name is $sha256" >&2
            jq -n -r \
              --arg version "$version" \
              --arg sha256 "$sha256" \
              --arg url "$url" \
              '{version: $version, url: $url, sha256: $sha256}'
          '';
          latest-floorp-version = pkgs.writeShellScriptBin "latest-floorp-version" ''
            set -e
            version=$(curl -s 'https://api.github.com/repos/Floorp-Projects/Floorp/releases/latest' | jq -r '.assets[].browser_download_url' | grep .floorp-macOS-*)
            echo "Last version of floorp is $version" >&2
            name="Floorp-$version.dmg"
            url="https://github.com/Floorp-Projects/Floorp/releases/download/v$version/floorp-macOS-universal.dmg"
            sha256=$(nix-prefetch-url --name $version $url)
            echo "SHA256 of $name is $sha256" >&2
            jq -n -r \
              --arg version "$version" \
              --arg sha256 "$sha256" \
              --arg url "$url" \
              '{version: $version, url: $url, sha256: $sha256}'
          '';
          ci = pkgs.writeShellScriptBin "ci" ''
            set -e
            latest-zen-version > ${zen_manifest}
            latest-floorp-version > ${floorp_manifest}
            zen_version=$(jq -r '.version' ${zen_manifest})
            floorp_version=$(jq -r '.version' ${floorp_manifest})
            git config --global user.name "github-actions"
            git config --global user.email "github-actions[bot]@users.noreply.github.com"
            git diff --quiet || (git add ${floorp_manifest} ${zen_manifest} && git commit -m "chore: bump floorp to $floorp_version, bump zen-browser to $zen_version")
            git push
          '';
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              _7zz
              jq
              curl
              git
              latest-floorp-version
              latest-zen-version
              ci
            ];
          };
        }
      );
    };
}
