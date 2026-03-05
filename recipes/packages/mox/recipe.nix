{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "mox";
  version = "0.0.15";
  description = "Modern full-featured open source secure mail server for low-maintenance self-hosted email";
  homePage = "https://github.com/mjl-/mox";
  mainProgram = "mox";

  source = {
    git = "github:mjl-/mox/v0.0.15";
    hash = "sha256-apIV+nClXTUbmCssnvgG9UwpTNTHTe6FgLCxp14/s0A=";
    patches = [
      ./version.patch
    ];
  };

  build.standardBuilder = {
    enable = true;
    requirements.native = [
      pkgs.go
    ];
  };

  build.extraDrvAttrs = {
    preConfigure = ''
      export HOME=$(mktemp -d)
    '';

    buildPhase = ''
      runHook preBuild
      CGO_ENABLED=0 go build -o mox -ldflags "-s -w -X github.com/mjl-/mox/moxvar.Version=0.0.15 -X github.com/mjl-/mox/moxvar.VersionBare=0.0.15" .
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 mox $out/bin/mox
      runHook postInstall
    '';

    passthru = {
      services.default = {
        imports = [
          (
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
                configData."config/mox.conf" = {
                }
                // lib.optionalAttrs (options ? systemd) {
                  source = "/var/lib/mox/config/mox.conf";
                };

                process.argv = [
                  (lib.getExe cfg.package)
                  "-config"
                  config.configData."config/mox.conf".path
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
                      StateDirectory = "mox";
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
                    StateDirectory = "mox";
                    WorkingDirectory = "/var/lib/mox";
                    Restart = "always";
                  };
                };
              };
            }
          )
        ];
        mox.package = pkgs.mox;
      };
    };
  };

  test.script = ''
    mox version
  '';
}
