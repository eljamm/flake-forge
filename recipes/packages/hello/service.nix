{
  lib,
  options,
  config,
  ...
}:
let
  cfg = config.hello;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [ ];

  options.hello = {
    package = lib.mkOption {
      description = "Package to use for hello";
      defaultText = "The hello package that provided this module.";
      type = lib.types.package;
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
      example = [
        "--greeting"
        "Hello"
      ];
      description = ''
        Extra arguments for hello.
      '';
    };
  };

  config = {
    process.argv = [
      (lib.getExe cfg.package)
    ]
    ++ cfg.extraArgs;
  };
}
