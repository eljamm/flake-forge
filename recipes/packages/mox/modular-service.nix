{
  lib,
  options,
  config,
  ...
}:
let
  cfg = config.mox;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [ prince213 ];

  options.mox = {
    package = lib.mkOption {
      description = "Package to use for mox";
      defaultText = "The mox package that provided this module.";
      type = lib.types.package;
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "mail";
      description = "Hostname for the Mox Mail Server";
    };
    user = lib.mkOption {
      type = lib.types.str;
      description = "*Required* Email user as (user@domain) to be created.";
    };
  };

  config = {
    process.argv = [
      (lib.getExe cfg.package)
      "-config"
      # TODO: use configData
      "/var/lib/mox/config/mox.conf"
      "serve"
    ];

    services.setup = {
      process.argv = [
        (lib.getExe cfg.package)
        "quickstart"
        "-hostname"
        cfg.hostname
        cfg.user
      ];
    }
    // lib.optionalAttrs (options ? systemd) {
      systemd.service = {
        description = "Mox Setup";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
        # TODO: name of the service varies depending on the user?
        before = [ "mox.service" ];
        serviceConfig = {
          WorkingDirectory = "/var/lib/mox";
          Type = "oneshot";
          RemainAfterExit = true;
          User = "mox";
          Group = "mox";
          # TODO: no idea who set it to always
          Restart = "no";
        };
      };
    };
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.service = {
      wantedBy = [ "multi-user.target" ];
      # TODO: name of the service varies depending on the user?
      after = [ "mox-setup.service" ];
      requires = [ "mox-setup.service" ];
      serviceConfig = {
        WorkingDirectory = "/var/lib/mox";
        Restart = "always";
      };
    };
  };
}
