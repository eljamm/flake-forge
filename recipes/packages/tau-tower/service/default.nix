{ pkgs }:

{
  options,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.tau-tower;
  settingsFormat = pkgs.formats.toml { };
  configFile = settingsFormat.generate "tower.toml" cfg.settings;

  passwordData = config.configData."credstore/tau.PASSWORD";
in
{
  _class = "service";

  meta.maintainers = lib.teams.ngi.members;

  options.tau-tower = {
    package = mkPackageOption pkgs "tau-tower" { };

    passwordFile = mkOption {
      type = with types; nullOr path;
      description = "Path that points to a file that contains the webradio password.";
      default = null;
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = {
          username = mkOption {
            type = types.str;
            description = "Webradio username.";
          };
          password = mkOption {
            type = types.str;
            # will be replaced with the contents of passwordFile, at runtime
            default = "@password@";
            description = "Webradio password.";
            readOnly = true;
            internal = true;
          };
          ip = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Host IP address.";
          };
          listen_port = mkOption {
            type = types.port;
            default = 3001;
            description = "Listen port.";
          };
          mount_port = mkOption {
            type = types.port;
            default = 3002;
            description = "Broadcast port.";
          };
          mount = mkOption {
            type = types.str;
            default = "tau.ogg";
            description = "Name for OGG file that contains captured audio.";
          };
        };
      };
      default = { };
      description = "Tau-tower config settings.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.settings.password == "@password@";
        message = ''
          It's insecure to enter your password as cleartext.
          Use `services.tau-tower.passwordFile`, instead.
        '';
      }
      {
        assertion = cfg.passwordFile != null;
        message = ''
          `services.tau-tower.passwordFile` must be set.
        '';
      }
    ];

    # TODO: handle password file with configData
    tau-tower.passwordFile = lib.mkDefault passwordData.path or null;
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.service = {
      description = "Tau Webradio Server";
      serviceConfig = {
        DynamicUser = true;
        User = "tau-tower";
        Group = "tau-tower";
        Restart = "on-failure";
        RestartSec = 5;
        StateDirectory = "tau-tower";
        LoadCredential = [
          "password_file:${toString cfg.passwordFile}"
        ];
      };
      unitConfig = {
        StartLimitBurst = 5;
        StartLimitInterval = 100;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.XDG_CONFIG_HOME = "/var/lib/tau-tower";
      preStart = ''
        install -Dm600 ${configFile} $XDG_CONFIG_HOME/tau/tower.toml
        sed -i "s/@password@/$(cat $CREDENTIALS_DIRECTORY/password_file)/" $XDG_CONFIG_HOME/tau/tower.toml
      '';
      postStop = ''
        rm -f $XDG_CONFIG_HOME/tau/tower.toml
      '';
    };
  };
}
