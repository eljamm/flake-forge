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

    # Legacy: requirements option for backward compatibility
    requirements = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Nix packages to include in the VM.";
    };

    config = {
      system = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = ''
          NixOS system configuration (legacy format).

          See: https://search.nixos.org/options
        '';
        example = lib.literalExpression ''
          {
            services.postgresql.enable = true;
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
          # Handle both app.nixos and app.vm for backward compatibility
          nixosConfig = app.nixos or app.vm or { };

          # Check if using legacy config format or new vm.* format
          useLegacyConfig = nixosConfig.config.system != { };
          vmConfig = if useLegacyConfig then { } else (nixosConfig.vm or { });

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
                let
                  # Use legacy config.system if available, otherwise use extraConfig
                  systemConfig = if useLegacyConfig then nixosConfig.config.system else { };
                  # Use legacy config.ports or new vm.ports
                  portsList = if useLegacyConfig then (nixosConfig.config.ports or [ ]) else (vmConfig.ports or [ ]);
                  # Add packages to system config if using legacy format
                  systemConfigWithPkgs =
                    if useLegacyConfig then
                      {
                        environment.systemPackages = nixosConfig.requirements or [ ];
                      }
                      // systemConfig
                    else
                      systemConfig;
                in
                lib.recursiveUpdate {
                  imports = [ "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix" ];
                  users.users.root.password = "root";
                  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
                  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
                  services.getty.autologinUser = "root";
                  networking.hostName = nixosConfig.name;
                  networking.useDHCP = lib.mkForce true;
                  networking.firewall.enable = lib.mkForce false;
                  virtualisation.graphics = false;
                  virtualisation.cores = vmConfig.cores or 4;
                  virtualisation.memorySize = vmConfig.memorySize or (1024 * 2);
                  virtualisation.diskSize = vmConfig.diskSize or (1024 * 4);
                  virtualisation.forwardPorts = forwardPortsAttrs portsList;
                  system.stateVersion = "25.11";
                } systemConfigWithPkgs
              )
            ];
          };
        in
        vm.config.system.build.vm;
      description = ""; # TODO:
    };
  };
}
