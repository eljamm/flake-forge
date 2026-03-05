{
  config,
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
      type = lib.types.submodule ./nimi.nix;
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
        inherit (app) services;
        inherit (config) settings;
      };
      description = ""; # TODO:
    };
  };
}
