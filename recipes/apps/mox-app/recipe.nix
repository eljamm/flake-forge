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

  # usage = ''
  #   Mox is a modern mail server that aims to be fully featured and easy to use.
  #
  #   * Quickstart (first time setup):
  #   ```
  #   mox quickstart hostname user@domain
  #   ```
  #
  #   * Serve mail:
  #   ```
  #   mox -config /var/lib/mox/config/mox.conf serve
  #   ```
  # '';

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

  # containers = {
  #   enable = true;
  #   settings = {
  #     container = {
  #       name = "mox";
  #       copyToRoot = [ pkgs.mypkgs.mox ];
  #     };
  #   };
  #   extraConfig = { };
  # };

  # nixos = {
  #   enable = true;
  #   settings = { };
  #   extraConfig = {
  #     services.mox = {
  #       imports = [ pkgs.mypkgs.mox.serviceModule ];
  #       mox = {
  #         package = pkgs.mypkgs.mox;
  #         hostname = "mail.example.com";
  #         user = "admin@example.com";
  #       };
  #     };
  #   };
  #   vm = { };
  #
  #   name = "mox-vm";
  #   requirements = [ pkgs.mypkgs.mox ];
  # };
}
