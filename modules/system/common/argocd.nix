{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    argocd
  ];
}
