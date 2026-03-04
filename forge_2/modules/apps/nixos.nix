{
  lib,
  inputs,
  app,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      NixOS virtual machine using Nimi.
    '';

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          restart = lib.mkOption {
            type = lib.types.submodule {
              options = {
                mode = lib.mkOption {
                  type = lib.types.enum [
                    "never"
                    "up-to-count"
                    "always"
                  ];
                  default = "always";
                  description = "Restart policy mode.";
                };
                time = lib.mkOption {
                  type = lib.types.int;
                  default = 1000;
                  description = "Delay between restarts in milliseconds.";
                };
                count = lib.mkOption {
                  type = lib.types.int;
                  default = 5;
                  description = "Maximum restart attempts.";
                };
              };
            };
            default = { };
            description = "Restart policy settings.";
          };
          logging = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkEnableOption "Per-service log files.";
                logsDir = lib.mkOption {
                  type = lib.types.str;
                  default = "nimi_logs";
                  description = "Directory for per-service logs.";
                };
              };
            };
            default = { };
            description = "Logging behavior settings.";
          };
          bubblewrap = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = "Bubblewrap sandbox configuration.";
          };
        };
      };
      default = { };
      description = "Nimi settings for the NixOS VM.";
      example = lib.literalExpression ''
        {
          restart = {
            mode = "up-to-count";
            time = 2000;
            count = 3;
          };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Arbitrary additional NixOS system configuration.";
      example = lib.literalExpression ''
        {
          services.openssh.enable = true;
          users.users.root.password = "root";
        }
      '';
    };

    vm = lib.mkOption {
      type = lib.types.submodule {
        options = {
          cores = lib.mkOption {
            type = lib.types.int;
            default = 4;
            description = "Number of CPU cores available to VM.";
          };
          memorySize = lib.mkOption {
            type = lib.types.int;
            default = 2048;
            description = "VM memory size in MB.";
          };
          diskSize = lib.mkOption {
            type = lib.types.int;
            default = 4096;
            description = "VM disk size in MB.";
          };
          ports = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of ports to forward from host to VM.";
            example = [
              "10022:22"
              "8080:80"
            ];
          };
        };
      };
      default = {
        cores = 4;
        memorySize = 2048;
        diskSize = 4096;
        ports = [ ];
      };
      description = "Virtual machine hardware configuration.";
    };

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      description = "Built VM.";
    };
  };

  config = lib.mkIf app.nixos.enable {
    build =
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
                environment.systemPackages = [ ];
                networking.hostName = "${app.name}-vm";
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
  };
}
