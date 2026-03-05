{
  lib,
  inputs,

  app,
  config,
  pkgs,
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

    system = lib.mkOption {
      type = with lib.types; lazyAttrsOf (either attrs anything);
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

    # TODO: wouldn't it be better to expose this at the top-level as `nimi` or something?
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

      eval = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "NixOS system evaluation.";
      };

      build = lib.mkOption {
        internal = true;
        readOnly = true;
        type = lib.types.package;
        default = config.vm.eval.config.system.build.vm;
        description = "NixOS Virtual Machine.";
      };

      # HACK:
      # Prevent toJSON conversion from attempting to convert `nixos.vm.eval`,
      # which won't work because it's a whole NixOS evaluation.
      __toString = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; functionTo str;
        default = self: "nixos-vm-config";
      };
    };
  };

  config = {
    vm.eval =
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

        system = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (
              { modulesPath, ... }:
              {
                imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
                virtualisation.graphics = false;
                virtualisation.cores = app.vm.config.cores;
                virtualisation.memorySize = app.vm.config.memorySize;
                virtualisation.diskSize = app.vm.config.diskSize;
                virtualisation.forwardPorts = forwardPortsAttrs app.vm.config.ports;
              }
            )
            {
              users.users.root.password = "root";
              services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
              services.openssh.settings.PasswordAuthentication = lib.mkForce true;
              services.getty.autologinUser = "root";
              environment.systemPackages = app.vm.requirements;
              networking.hostName = app.vm.name;
              networking.useDHCP = lib.mkForce true;
              networking.firewall.enable = lib.mkForce false;
              system.stateVersion = "25.11";
            }
            {
              # modular services
              system = { inherit (app) services; };
            }
            config.system
          ];
        };
      in
      system;
  };
}
