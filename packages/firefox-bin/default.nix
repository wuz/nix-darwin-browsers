{ stdenv, pkgs, fetchurl, lib, policies ? { }, ... }:
let
  firefox = builtins.fromJSON (builtins.readFile ./firefox.json);
  isPoliciesEnabled = builtins.length (builtins.attrNames policies) > 0;
  policiesJson = builtins.toJSON { inherit policies; };
in
stdenv.mkDerivation rec {
  pname = "Firefox";
  version = firefox.version;
  buildInputs = [ pkgs.undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r Firefox.app "$out/Applications/Firefox.app"
  ''
  + (if isPoliciesEnabled then ''
    mkdir -p "$out/Applications/Firefox.app/Contents/Resources/distribution"
    echo '${policiesJson}' > "$out/Applications/Firefox.app/Contents/Resources/distribution/policies.json"
  '' else "");
  src = fetchurl {
    name = "Firefox-${version}.dmg";
    inherit (firefox) url sha256;
  };
  meta = with stdenv.lib; {
    description = "The Firefox web browser";
    homepage = "https://www.mozilla.org/en-GB/firefox";
    platforms = lib.platforms.darwin;
  };
}
