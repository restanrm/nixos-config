{pkgs, ...}: {
  home.packages = [
    (pkgs.azure-cli.withExtensions (with pkgs.azure-cli.extensions; [
      vm-repair
    ]))
  ];
}
