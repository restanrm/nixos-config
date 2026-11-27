{pkgs, ...}: {
  home.packages = [
    pkgs.pinniped
    (pkgs.azure-cli.withExtensions (with pkgs.azure-cli.extensions; [
      vm-repair
    ]))
  ];
}
