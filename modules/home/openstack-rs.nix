{pkgs, ...}: {
  home.packages = with pkgs; [
    openstack-rs
    python3Packages.python-openstackclient
  ];
}
