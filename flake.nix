{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
      overlays.default = import ./overlays/floorp.nix;
      formatter = eachSystem (pkgs: pkgs.nixpkgs-fmt);
      packages = eachDarwinSystem (pkgs: rec {
        default = floorp;
        floorp = pkgs.callPackage ./packages/floorp { };
      });
      darwinModules.home-manager = import ./modules/home-manager.nix;
      devShells = eachSystem (
        pkgs:
        let
          manifest = "./packages/floorp/floorp.json";
          latest-floorp-version = pkgs.writeShellScriptBin "latest-floorp-version" ''
            set -e
            version=$(curl -s 'https://raw.githubusercontent.com/Floorp-Projects/Floorp-Updates/refs/heads/main/browser/latest.json' | jq -r '.mac.version')
            echo "Last version of floorp is $version" >&2
            name="floorp-$version.dmg"
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
            latest-floorp-version > ${manifest}
            version=$(jq -r '.version' ${manifest})
            git config --global user.name "github-actions"
            git config --global user.email "github-actions[bot]@users.noreply.github.com"
            git diff --quiet || (git add ${manifest} && git commit -m "chore: bump floorp to $version")
            git push
          '';
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              jq
              curl
              git
              latest-floorp-version
              ci
            ];
          };
        }
      );
    };
}
