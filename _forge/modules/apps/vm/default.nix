{
  lib,
  inputs,

  app,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Virtual machine.
    '';
    name = lib.mkOption {
      type = lib.types.str;
      default = "nixos-vm";
    };
    requirements = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
    config = {
      system = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          NixOS system configuration.

          See: https://search.nixos.org/options
        '';
        example = lib.literalExpression ''
          {
            services.postgresql.enabled = true;
          }
        '';
      };
      ports = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "^[0-9]*:[0-9]*$");
        default = [ ];
        description = ''
          List of ports to forward from host system to VM.

          Format: HOST_PORT:VM_PORT
        '';
        example = lib.literalExpression ''
          [ "10022:22" "5432:5432" "8000:90" ]
        '';
      };
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
                  environment.systemPackages = app.vm.requirements;
                  networking.hostName = app.vm.name;
                  networking.useDHCP = lib.mkForce true;
                  networking.firewall.enable = lib.mkForce false;
                  virtualisation.graphics = false;
                  virtualisation.cores = app.vm.config.cores;
                  virtualisation.memorySize = app.vm.config.memorySize;
                  virtualisation.diskSize = app.vm.config.diskSize;
                  virtualisation.forwardPorts = forwardPortsAttrs app.vm.config.ports;
                  system.stateVersion = "25.11";
                } app.vm.config.system
              )
            ];
          };
        in
        vm.config.system.build.vm;
      description = ""; # TODO:
    };
  };
}
