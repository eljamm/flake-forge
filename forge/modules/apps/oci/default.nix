{
  name,

  config,
  pkgs,
  lib,

  app,
  nimi,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Container images output.
    '';

    settings = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./nimi.nix ];
        _module.args.container-name = name;
      };
      default = { };
      description = "Nimi settings for container generation.";
      example = lib.literalExpression ''
        {
          container = {
            name = "my-app";
            tag = "latest";
          };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Arbitrary additional configuration for the container.";
      example = lib.literalExpression ''
        {
          # Additional nix2container config
        }
      '';
    };

    # TODO: do we really not need this anymore?
    composeFile = lib.mkOption {
      internal = true;
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Relative path to a container compose file.";
      example = "./compose.yaml";
    };

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.nullOr lib.types.package;
      default = nimi.mkContainerImage {
        inherit (config) settings;
        services = lib.recursiveUpdate app.services config.extraConfig;
      };
      description = ""; # TODO:
    };

    build-image = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      default =
        let
          inherit (config.settings) container;
        in
        pkgs.writeShellScript "build-oci" ''
          ${config.build.copyTo}/bin/copy-to \
            oci-archive:${container.name}.tar:${container.name}:${container.tag}
        '';
      description = ""; # TODO:
    };

    debug = {
      eval = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "NixOS system evaluation.";
      };

      # HACK:
      # Prevent toJSON conversion from attempting to convert the `eval` option,
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
    debug.eval = nimi.passthru.evalNimiModule {
      inherit (config) settings;
      services = lib.recursiveUpdate app.services config.extraConfig;
    };
  };
}
