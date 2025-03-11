{
  stdenv,
  pkgs,
  fetchurl,
  lib,
  policies ? {
    AppAutoUpdate = false;
    DisableAppUpdate = true;
  },
  ...
}:
let
  zen-browser = builtins.fromJSON (builtins.readFile ./zen-browser.json);
  isPoliciesEnabled = builtins.length (builtins.attrNames policies) > 0;
  policiesJson = builtins.toJSON { inherit policies; };
in
stdenv.mkDerivation rec {
  pname = "Zen Browser";
  version = zen-browser.version;
  buildInputs = [
    pkgs._7zz
    pkgs.undmg
  ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  unpackPhase = ''
    runHook preUnpack

    undmg $src || 7zz x -snld $src

    runHook postUnpack
  '';

  installPhase =
    ''
      runHook preInstall

       mkdir -p "$out/Applications/${sourceRoot}"
       cp -R . "$out/Applications/${sourceRoot}"

        if [[ -e "$out/Applications/${sourceRoot}/Contents/MacOS/Zen.app" ]]; then
          makeWrapper "$out/Applications/${sourceRoot}/Contents/MacOS/Zen.app" $out/bin/Zen.app
        elif [[ -e "$out/Applications/${sourceRoot}/Contents/MacOS/${lib.removeSuffix ".app" sourceRoot}" ]]; then
          makeWrapper "$out/Applications/${sourceRoot}/Contents/MacOS/${lib.removeSuffix ".app" sourceRoot}" $out/bin/Zen.app
        fi
        runHook postInstall
    ''
    + (
      if isPoliciesEnabled then
        ''
          mkdir -p "$out/Applications/Zen.app/Contents/Resources/distribution"
          echo '${policiesJson}' > "$out/Applications/Zen.app/Contents/Resources/distribution/policies.json"

          runHook postInstall
        ''
      else
        "runHook postInstall"
    );
  src = fetchurl {
    name = "Zen Browser-${version}.dmg";
    inherit (zen-browser) url sha256;
  };
  meta = {
    description = "";
    homepage = "";
    platforms = lib.platforms.darwin;
  };
}
