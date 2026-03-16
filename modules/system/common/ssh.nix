{...}: {
  programs.ssh = {
    startAgent = true;
    agentPKCS11Whitelist = "/nix/store/*/lib/libykcs11.so*";
  };
}
