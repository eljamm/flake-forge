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

  services.mox = {
    imports = [ pkgs.mypkgs.mox.services.default ];
    mox = {
      hostname = "mail";
      user = "admin@example.com";
    };
  };

  oci.mox =
    {
      config,
      ...
    }:
    let
      cfg = config.nimi.services.mox;
    in
    {
      enable = true;
      settings = {
        container.copyToRoot = [
          (pkgs.buildEnv {
            name = "runtime-bins";
            paths = with pkgs; [ mypkgs.mox ];
            pathsToLink = [ "/bin" ];
          })
        ];
        startup.runOnStartup = pkgs.writeShellScript "mox-setup" ''
          ${toString cfg.services.setup.process.argv}
        '';
      };
    };

  nixos = {
    enable = true;
    settings = { }; # Nimi settings
    extraConfig = {
      services.postgresql.enable = true;
    };
    vm = {
      cores = 4;
      diskSize = 4096;
      memorySize = 2048;
      ports = [ "9191:80" ];
    };
  };

  # programs = {
  #   enable = true;
  #   requirements = [
  #     pkgs.mypkgs.mox
  #   ];
  # };
}
