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
        imports = [ ./service.nix ];
        mox.package = pkgs.mypkgs.mox;
      };
    };
  };

  test.script = ''
    mox version
  '';
}
