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
      default = nimi.mkContainerImage config.debug.nimi-config;
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
      nimi-config = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "NixOS system evaluation.";
      };

      eval = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        default = nimi.passthru.evalNimiModule config.debug.nimi-config;
        description = "NixOS system evaluation.";
      };

      # HACK:
      # Prevent toJSON conversion from attempting to convert the `eval` option,
      # which won't work because it's a whole NixOS evaluation.
      __toString = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; functionTo str;
        default = self: "oci-config";
      };
    };
  };

  config = {
    debug.nimi-config = {
      config = {
        inherit (config) settings;
        services =
          lib.mapAttrs (serviceName: service: {
            imports = [
              service
              (config.extraConfig.services.${serviceName} or { })
            ];
            options.nimi = lib.mkOption {
              type = with lib.types; lazyAttrsOf (attrsOf anything);
              default = { };
              description = ''
                Let the modular service know that it's evaluated for nimi,
                by testing `options ? nimi`.
              '';
            };
          }) app.services
          // lib.removeAttrs (config.extraConfig.services or { }) (lib.attrNames app.services);
      };
    };
  };
}
