{
  lib,
  pkgs,
  inputs,

  app,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Container images output using Nimi.
    '';

    # Legacy: Old format with images list (backward compatibility)
    images = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "app-container";
            };
            requirements = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
            config = {
              CMD = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          };
        }
      );
      default = [ ];
      description = "List of container images to build (legacy format).";
    };

    # Legacy: Old compose file option (backward compatibility)
    composeFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Relative path to a container compose file (legacy format).";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          container = lib.mkOption {
            type = lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "nimi-container";
                  description = "The name of the generated image.";
                };
                tag = lib.mkOption {
                  type = lib.types.str;
                  default = "latest";
                  description = "The tag for the generated image.";
                };
                copyToRoot = lib.mkOption {
                  type = lib.types.listOf lib.types.package;
                  default = [ ];
                  description = "A list of derivations to copy to the image root directory.";
                };
                fromImage = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "An image that is used as base image.";
                };
                maxLayers = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                  description = "The maximum number of layers to create.";
                };
              };
            };
            default = { };
            description = "Nimi container settings.";
            example = lib.literalExpression ''
              {
                name = "my-container";
                tag = "v1.0";
                copyToRoot = [ pkgs.bash pkgs.coreutils ];
              }
            '';
          };
        };
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

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      default =
        let
          nimi = inputs.nimi;
          # Check if using legacy images format or new settings format
          useLegacyFormat = app.containers.images != [ ];
        in
        if useLegacyFormat then
          # Legacy format: use dockerTools
          let
            buildImage =
              image:
              pkgs.dockerTools.buildImage {
                name = image.name;
                tag = "latest";
                copyToRoot = pkgs.buildEnv {
                  name = "image-root";
                  paths = image.requirements;
                  pathsToLink = [ "/bin" ];
                };
                config = {
                  Cmd = image.config.CMD;
                };
              };
          in
          pkgs.linkFarm "${app.name}-${app.version}" (
            (map (image: {
              name = "${image.name}.tar.gz";
              path = buildImage image;
            }) app.containers.images)
            ++ lib.optionals (app.containers.composeFile != null) [
              {
                name = "compose.yaml";
                path = pkgs.writeTextFile {
                  name = "compose.yaml";
                  text = builtins.readFile app.containers.composeFile;
                };
              }
            ]
          )
        else
          # New Nimi-based format (placeholder for now)
          pkgs.runCommand "${app.name}-${app.version}-containers" { } ''
            echo "Nimi container output"
            mkdir -p $out
          '';
      description = ""; # TODO:
    };
  };
}
