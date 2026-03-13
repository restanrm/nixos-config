{pkgs, ...}: {
  home.packages = with pkgs; [
    openstack-rs
  ];
}
