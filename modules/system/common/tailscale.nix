{
  config,
  lib,
  ...
}: let
  username = lib.head (lib.attrNames config.home-manager.users);
in {
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--operator=${username}" "--accept-routes=true" "--stateful-filtering"];
  };
}
