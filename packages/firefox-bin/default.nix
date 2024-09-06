{ stdenv, pkgs, fetchurl, lib, ... }:
let
  firefox = builtins.fromJSON (builtins.readFile ./firefox.json);
in
{
  firefox-bin = stdenv.mkDerivation rec {
    pname = "Firefox";
    version = firefox.version;
    buildInputs = [ pkgs.undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p "$out/Applications"
      cp -r Firefox.app "$out/Applications/Firefox.app"
    '';
    src = fetchurl {
      name = "Firefox-${version}.dmg";
      inherit (firefox) url sha256;
    };
    meta = with stdenv.lib; {
      description = "The Firefox web browser";
      homepage = "https://www.mozilla.org/en-GB/firefox";
      platforms = lib.platforms.darwin;
    };
  };
}
