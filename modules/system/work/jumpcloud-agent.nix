{...}: {
  services.jumpcloud-agent = {
    enable = true;
    connectKeyFile = "/var/src/secrets/jumpcloud-connect-key";
  };
}
