{
  lib,

  container-name,
  ...
}:
{
  freeformType = with lib.types; lazyAttrsOf (attrsOf anything);

  options = {
    container = lib.mkOption {
      type = lib.types.submodule {
        freeformType = with lib.types; lazyAttrsOf (attrsOf anything);
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = container-name;
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
}
