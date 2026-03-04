{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "mox-app";
  version = "0.0.15";
  description = "Modern full-featured open source secure mail server";
  usage = ''
    Mox is a modern mail server that aims to be fully featured and easy to use.

    * Quickstart (first time setup):
    ```
    mox quickstart hostname user@domain
    ```

    * Serve mail:
    ```
    mox -config /var/lib/mox/config/mox.conf serve
    ```
  '';

  services = {
    mox = {
      process.argv = [
        (lib.getExe pkgs.mypkgs.mox)
        "-config"
        "/var/lib/mox/config/mox.conf"
        "serve"
      ];
      requirements = [ pkgs.mypkgs.mox ];
    };
  };

  containers = {
    enable = true;
    settings = {
      container = {
        name = "mox";
        copyToRoot = [ pkgs.mypkgs.mox ];
      };
    };
  };

  nixos = {
    enable = true;
    name = "mox-vm";
    requirements = [ pkgs.mypkgs.mox ];
    extraConfig = {
      services.mox = {
        imports = [ pkgs.mypkgs.mox.serviceModule ];
        mox = {
          package = pkgs.mypkgs.mox;
          hostname = "mail.example.com";
          user = "admin@example.com";
        };
      };
    };
  };
}
