{
  stdenv,
  pkgs,
  fetchurl,
  lib,
  ...
}:
let
  zen-browser = builtins.fromJSON (builtins.readFile ./zen-browser.json);
in
stdenv.mkDerivation rec {
  pname = "Zen";
  version = zen-browser.version;
  buildInputs = [ pkgs.undmg ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r Zen.app "$out/Applications/Zen.app"
  '';
  src = fetchurl {
    name = "Zen-${version}.dmg";
    inherit (zen-browser) url sha256;
  };
  meta = {
    description = "";
    homepage = "";
    platforms = lib.platforms.darwin;
  };
}
