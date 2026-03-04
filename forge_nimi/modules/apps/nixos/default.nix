{
  lib,
  inputs,

  app,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      NixOS/VM output.
    '';

    name = lib.mkOption {
      type = lib.types.str;
      default = "nixos-vm";
      description = "Hostname for the VM.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Nimi settings for the NixOS configuration.";
      example = lib.literalExpression ''
        {
          restart.mode = "always";
          restart.time = 1000;
          logging.enable = true;
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Arbitrary additional NixOS system configuration.";
      example = lib.literalExpression ''
        {
          services.postgresql.enable = true;
          services.openssh.enable = true;
        }
      '';
    };

    vm = {
      cores = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of CPU cores available to VM.";
        example = 8;
      };
      memorySize = lib.mkOption {
        type = lib.types.int;
        default = 1024 * 2;
        description = "VM memory size in MB.";
        example = 1024 * 4;
      };
      diskSize = lib.mkOption {
        type = lib.types.int;
        default = 1024 * 4;
        description = "VM disk size in MB.";
        example = 1024 * 10;
      };
      ports = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "^[0-9]*:[0-9]*$");
        default = [ ];
        description = ''
          List of ports to forward from host system to VM.

          Format: HOST_PORT:VM_PORT
        '';
        example = lib.literalExpression ''
          [ "10022:22" "5432:5432" "8000:80" ]
        '';
      };
    };

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      default =
        let
          forwardPortsAttrs =
            ports:
            map (
              port:
              let
                portSplit = lib.splitString ":" port;
              in
              {
                from = "host";
                host.port = lib.toInt (lib.elemAt portSplit 0);
                guest.port = lib.toInt (lib.elemAt portSplit 1);
              }
            ) ports;

          vm = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              (
                { pkgs, ... }:
                lib.recursiveUpdate {
                  imports = [ "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix" ];
                  users.users.root.password = "root";
                  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
                  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
                  services.getty.autologinUser = "root";
                  networking.hostName = app.nixos.name;
                  networking.useDHCP = lib.mkForce true;
                  networking.firewall.enable = lib.mkForce false;
                  virtualisation.graphics = false;
                  virtualisation.cores = app.nixos.vm.cores;
                  virtualisation.memorySize = app.nixos.vm.memorySize;
                  virtualisation.diskSize = app.nixos.vm.diskSize;
                  virtualisation.forwardPorts = forwardPortsAttrs app.nixos.vm.ports;
                  system.stateVersion = "25.11";
                } app.nixos.extraConfig
              )
            ];
          };
        in
        vm.config.system.build.vm;
      description = ""; # TODO:
    };
  };
}
