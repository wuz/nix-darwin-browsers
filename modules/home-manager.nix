{
  pkgs,
  config,
  lib,
  ...
}:
let
  enabled = config.programs ? firefox && config.programs.firefox ? enable;
in
{
  config = lib.mkIf enabled {
    programs.firefox = {
      enable = true;
      package = pkgs.callPackage ../packages/zen-browser-bin {
        policies = config.programs.firefox.policies;
      };
    };
  };
}
