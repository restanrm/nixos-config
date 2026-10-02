{pkgs, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentityFile = "~/.ssh/id_ed25519";
        User = "adrien";
        ForwardAgent = true;
        PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.so";
        SetEnv.TERM = "xterm";
      };
      "delivery.sekoia.io" = {
        HostName = "51.91.142.101";
      };
      "web.delivery.sekoia.io" = {
        HostName = "146.59.202.224";
      };
      "fra1-symphony" = {
        HostName = "147.135.195.119";
      };
      "test-symphony" = {
        HostName = "51.210.185.126";
      };
      "mco1.app.sekoia.io" = {
        HostName = "185.243.3.206";
      };
      "uae1.app.sekoia.io" = {
        HostName = "74.162.88.150";
      };
      "fra2-production" = {
        HostName = "5.135.121.213";
      };
      "fra1-production" = {
        HostName = "54.37.23.139";
      };
      "fra1-test" = {
        HostName = "141.94.167.154";
      };
      "fra1-quickwit" = {
        HostName = "172.233.245.133";
      };
      "usa1-production" = {
        HostName = "135.148.232.200";
      };
      "uae1-production" = {
        HostName = "74.162.88.150";
      };
      "sgp1-production" = {
        HostName = "51.79.143.93";
      };
      "rie-lab" = {
        HostName = "57.128.57.82";
        User = "debian";
        LocalForward = [
          {
            bind.address = "127.0.0.1";
            bind.port = 6443;
            host.address = "10.0.0.100";
            host.port = 6443;
          }
        ];
      };
      "dev1" = {
        HostName = "57.128.58.30";
        User = "debian";
      };
      "dev1-quickwit" = {
        HostName = "172.233.247.243";
      };
      "shc-lab" = {
        HostName = "51.210.144.132";
        LocalForward = [
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
          {
            bind.address = "127.0.0.1";
            bind.port = 8003;
            host.address = "127.0.0.1";
            host.port = 8003;
          }
          {
            bind.address = "127.0.0.1";
            bind.port = 8004;
            host.address = "127.0.0.1";
            host.port = 8004;
          }
        ];
      };
    };
  };
}
