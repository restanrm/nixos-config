{...}: {
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--accept-routes=true" "--stateful-filtering"];
  };
}
