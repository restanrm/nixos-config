{...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "restanrm.fr" = {
        User = "nrm";
      };
    };
  };
}
