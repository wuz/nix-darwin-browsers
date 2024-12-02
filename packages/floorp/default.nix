{
  stdenv,
  pkgs,
  fetchurl,
  lib,
  policies ? { },
  ...
}:
let
  floorp = builtins.fromJSON (builtins.readFile ./floorp.json);
  isPoliciesEnabled = builtins.length (builtins.attrNames policies) > 0;
  policiesJson = builtins.toJSON { inherit policies; };
in
stdenv.mkDerivation rec {
  pname = "floorp";
  version = floorp.version;
  buildInputs = [ pkgs.undmg ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];
  installPhase =
    ''
      mkdir -p "$out/Applications"
      cp -r Floorp.app "$out/Applications/Floorp.app"
    ''
    + (
      if isPoliciesEnabled then
        ''
          mkdir -p "$out/Applications/Floorp.app/Contents/Resources/distribution"
          echo '${policiesJson}' > "$out/Applications/Floorp.app/Contents/Resources/distribution/policies.json"
        ''
      else
        ""
    );
  src = fetchurl {
    name = "floorp-${version}.dmg";
    inherit (floorp) url sha256;
  };
  meta = with stdenv.lib; {
    description = "The floorp web browser";
    homepage = "https://floorp.app/";
    platforms = lib.platforms.darwin;
  };
}
