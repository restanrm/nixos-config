{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        user = "adrien";
        forwardAgent = true;
        extraOptions = {
          PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.so";
          SetEnv = "TERM=xterm";
        };
      };
      "delivery.sekoia.io" = {
        hostname = "51.91.142.101";
      };
      "web.delivery.sekoia.io" = {
        hostname = "146.59.202.224";
      };
      "fra1-symphony" = {
        hostname = "147.135.195.119";
      };
      "test-symphony" = {
        hostname = "51.210.185.126";
      };
      "mco1.app.sekoia.io" = {
        hostname = "185.243.3.206";
      };
      "uae1.app.sekoia.io" = {
        hostname = "74.162.88.150";
      };
      "fra2-production" = {
        hostname = "5.135.121.213";
      };
      "fra1-production" = {
        hostname = "54.37.23.139";
      };
      "fra1-test" = {
        hostname = "141.94.167.154";
      };
      "usa1-production" = {
        hostname = "135.148.232.200";
      };
      "rie-lab" = {
        hostname = "57.128.57.82";
        user = "debian";
        localForwards = [
          {
            bind.address = "127.0.0.1";
            bind.port = 6443;
            host.address = "10.0.0.100";
            host.port = 6443;
          }
        ];
      };
      "dev1" = {
        hostname = "57.128.58.30";
        user = "debian";
      };
      "dev1-quickwit" = {
        hostname = "172.233.247.243";
      };
      "shc-lab" = {
        hostname = "51.210.144.132";
        localForwards = [
          {
            bind.address = "127.0.0.1";
            bind.port = 8001;
            host.address = "10.0.0.11";
            host.port = 443;
          }
          {
            bind.address = "127.0.0.1";
            bind.port = 8002;
            host.address = "10.0.0.12";
            host.port = 80;
          }
        ];
      };
    };
  };
}
