{
  lib,
  options,
  config,
  ...
}:
let
  cfg = config.python-web;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [ ];

  options.python-web = {
    package = lib.mkOption {
      description = "Package to use for python-web";
      defaultText = "The python-web package that provided this module.";
      type = lib.types.package;
    };
  };

  config.process.argv = [
    (lib.getExe cfg.package)
  ];
}
