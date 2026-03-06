{
  lib,
  options,
  config,
  ...
}:
let
  cfg = config.api;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [ ];

  options.api = {
    package = lib.mkOption {
      description = "Package to use for python-web";
      defaultText = "The python-web package that provided this module.";
      type = lib.types.package;
    };
  };

  config = {
    process.argv = [
      (lib.getExe cfg.package)
    ];
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.services.api = {
      wantedBy = [ "multi-user.target" ];
      script = "${toString config.process.argv}";
    };
  };
}
