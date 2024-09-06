self: super:
let
  firefox = builtins.fromJSON (builtins.readFile ./firefox.json);
in
{
  firefox-bin = super.stdenv.mkDerivation rec {
    pname = "Firefox";
    version = firefox.version;
    buildInputs = [ super.pkgs.undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p "$out/Applications"
      cp -r Firefox.app "$out/Applications/Firefox.app"
    '';
    src = super.fetchurl {
      name = "Firefox-${version}.dmg";
      inherit (firefox) url sha256;
    };
    meta = with super.stdenv.lib; {
      description = "The Firefox web browser";
      homepage = "https://www.mozilla.org/en-GB/firefox";
      platforms = super.lib.platforms.darwin;
    };
  };
}
