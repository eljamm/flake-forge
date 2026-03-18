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

    configData."credstore/tau.PASSWORD" = {
      source = lib.mkDefault "/etc/credstore/tau.PASSWORD";
      path = lib.mkDefault "/etc/tau/password";
    };
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
    requirements = [
      pkgs.mypkgs.tau-tower
      pkgs.bash
      pkgs.coreutils
      pkgs.gnused
    ];
    imageConfig.WorkingDir = "/";
    imageConfig.Env = [ "XDG_CONFIG_HOME=/" ];
    startup = pkgs.writeShellScript "mox-setup" ''
      install -Dm600 /tau/tower-host.toml /tau/tower.toml
      sed -i "s/@password@/$(cat /etc/credstore/tau.PASSWORD)/" /tau/tower.toml
    '';
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
          passwordFile = "/etc/credstore/tau.PASSWORD";
        };
      };

      # WARN: !! Don't use this in production !!
      # Instead, put the secrets directly in the systemd credentials store (`/etc/credstore/`, `/run/credstore/`, ...)
      # For more information on this topic, see: <https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#ImportCredential=GLOB>
      environment.etc."credstore/tau.PASSWORD".text = "superSecretPassword";

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
