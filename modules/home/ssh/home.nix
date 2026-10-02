{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    settings = {
      "restanrm.fr" = {
        User = "nrm";
      };
    };
  };
}
