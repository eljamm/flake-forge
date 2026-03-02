{
  inputs,
  pkgs,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  imports = [
    ../assertions-warnings.nix
  ];

  options = {
    perSystem = mkPerSystemOption (
      { config, pkgs, ... }:
      let
        nixosVm =
          app:
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

        cfg = config.forge;
      in
      {
        options = {
          forge = {
            appsFilter = lib.mkOption {
              internal = true;
              type = lib.types.attrsOf (lib.types.listOf lib.types.str);
              default = { };
              description = "Defines which options are relevant for each app output type.";
            };

            apps = lib.mkOption {
              default = [ ];
              description = "List of applications.";
              type = lib.types.listOf (
                lib.types.submodule {
                  imports = [ ./app.nix ];
                  _module.args.pkgs = pkgs;
                }
              );
              apply =
                apps:
                let
                  shellBundle =
                    app:
                    let
                      appPassthru =
                        app: _finalApp:
                        { }
                        // lib.optionalAttrs app.containers.enable { containers = app.containers.build; }
                        // lib.optionalAttrs app.vm.enable { vm = nixosVm app; };

                      appDrv = pkgs.symlinkJoin {
                        name = "${app.name}-${app.version}";
                        paths = app.programs.requirements;
                      };
                    in
                    appDrv.overrideAttrs (oldAttrs: {
                      passthru = oldAttrs.passthru or { } // appPassthru app appDrv;
                    });
                in
                lib.listToAttrs (
                  map (app: {
                    name = "${app.name}";
                    value = shellBundle app;
                  }) apps
                );
            };
          };
        };

        config = {
          packages = cfg.apps;

          forge.appsFilter = lib.mkDefault {
            programs = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.programs.enable"
              "apps.*.programs.requirements"
            ];
            containers = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.containers.enable"
              "apps.*.containers.images"
              "apps.*.containers.composeFile"
            ];
            vm = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.vm.enable"
              "apps.*.vm.name"
              "apps.*.vm.requirements"
              "apps.*.vm.config.system"
              "apps.*.vm.config.ports"
              "apps.*.vm.config.cores"
              "apps.*.vm.config.memorySize"
              "apps.*.vm.config.diskSize"
            ];
          };
        };
      }
    );
  };
}
