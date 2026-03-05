{
  config,
  pkgs,
  lib,
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

  programs = {
    enable = true;
    requirements = [
      pkgs.mypkgs.mox
    ];
  };

  services.mox = {
    imports = [ pkgs.mypkgs.mox.services.default ];
    mox = {
      hostname = "mail";
      user = "admin@example.com";
    };
  };

  oci =
    { config, ... }:
    let
      cfg = config.debug.eval.services.mox;
    in
    {
      enable = true;
      settings = {
        container = {
          name = "mox";
          copyToRoot = [
            (pkgs.buildEnv {
              name = "runtime-bins";
              paths = [
                pkgs.mypkgs.mox
                pkgs.coreutils
                pkgs.bash
              ];
              pathsToLink = [ "/bin" ];
            })
          ];
        };
        startup.runOnStartup = pkgs.writeShellScript "mox-setup" ''
          USER_UID=0
          ${toString cfg.services.setup.process.argv} $USER_UID
        '';
      };
      extraConfig = { };
    };

  nixos = {
    enable = true;
    settings = { }; # Nimi settings
    extraConfig = {
      services.postgresql.enable = true;
      users.users.mox = {
        isSystemUser = true;
        name = "mox";
        group = "mox";
        home = "/var/lib/mox";
        createHome = true;
        description = "Mox Mail Server User";
      };
      users.groups.mox = { };
    };
    vm = {
      cores = 4;
      diskSize = 4096;
      memorySize = 2048;
      ports = [ "9191:80" ];
    };
  };
}
