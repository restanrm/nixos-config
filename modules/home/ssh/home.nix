{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "restanrm.fr" = {
        user = "nrm";
      };
    };
  };
}
