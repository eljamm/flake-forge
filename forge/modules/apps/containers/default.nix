{
  lib,
  pkgs,

  app,
  config,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Container images output.
    '';
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
      description = "List of container images to build.";
      example = lib.literalExpression ''
        [
          {
            name = "api";
            requirements = [ mypkgs.my-package ];
            config.CMD = [ "my-command" ];
          }
        ]
      '';
    };
    composeFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Relative path to a container compose file.";
      example = "./compose.yaml";
    };

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      default =
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
          # Container images
          (map (image: {
            name = "${image.name}.tar.gz";
            path = buildImage image;
          }) app.containers.images)
          # Compose file (optional)
          ++ lib.optionals (app.containers.composeFile != null) [
            {
              name = "compose.yaml";
              path = pkgs.writeTextFile {
                name = "compose.yaml";
                text = builtins.readFile app.containers.composeFile;
              };
            }
          ]
        );
      description = ""; # TODO:
    };
  };
}
