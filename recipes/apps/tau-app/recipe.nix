{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "tau-app";
  version = "0.2.101";
  description = "Web radio streaming system - tau-tower server and tau-radio client";

  usage = ''
    ## Tau Radio Streaming System

    This app provides both the tau-tower server and tau-radio client.

    ### tau-tower (Server)
    Run as a service to broadcast audio to clients:
    - Listens on port 3001 by default
    - Broadcasts on port 3002 by default
    - Configuration: ~/.config/tau/config.toml

    ### tau-radio (Client)
    Capture audio from your device and stream to tau-tower:
    ```
    tau-radio --username <user> --password <pass> --host <server-ip>
    ```

    ### Default Ports
    - Server listen: 3001
    - Broadcast: 3002
  '';

  services.tau-tower = {
    command = pkgs.mypkgs.tau-tower;
  };

  programs = {
    enable = true;
    requirements = [
      pkgs.mypkgs.tau-radio
      pkgs.mypkgs.tau-tower
    ];
  };

  container = {
    enable = true;
    name = "tau-tower";
    requirements = [ pkgs.mypkgs.tau-tower ];
    composeFile = ./compose.yaml;
  };

  nixos = {
    enable = true;
    name = "tau-tower";
    extraConfig = {
      system.services.tau-tower = {
        imports = [ pkgs.mypkgs.tau-tower.services.default ];
        tau-tower = {
          settings.username = "alice";
          # WARN: Don't use this in production as it will copy the file to the
          # Nix store. Instead, provide a string that contains an absolute path
          # to a file that already exists on disk.
          passwordFile = pkgs.writeText "password.txt" "superSecretPassword";
        };
      };

      environment.systemPackages = [
        pkgs.mypkgs.tau-radio
        pkgs.mypkgs.tau-tower
      ];
    };
    vm.forwardPorts = [
      "3001:3001"
      "3002:3002"
    ];
  };
}
