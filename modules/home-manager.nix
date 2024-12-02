{
  pkgs,
  config,
  lib,
  ...
}:
let
  enabled = config.programs ? floorp && config.programs.floorp ? enable;
in
{
  config = lib.mkIf enabled {
    programs.floorp = {
      enable = true;
      package = pkgs.callPackage ../packages/floorp-bin {
        policies = config.programs.floorp.policies;
      };
    };
  };
}
