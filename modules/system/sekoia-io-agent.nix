{...}: {
  services.sekoia-io-agent = {
    enable = true;
    settings = {
      intakekey = "yGhWnczn1F9BH575xkUGif7pywQoSoGZ";
      roles = [
        "event-collector"
      ];
    };
  };
}
