{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "hello-app";
  version = "1.0.0";
  description = "Say hello in multiple languages.";

  services.hello = {
    imports = [ pkgs.mypkgs.hello.services.default ];
  };

  oci =
    let
      commonSettings = {
        copyToRoot = [
          (pkgs.buildEnv {
            name = "runtime-bins";
            paths = with pkgs; [
              mypkgs.hello
              coreutils
              bash
            ];
            pathsToLink = [ "/bin" ];
          })
        ];
        imageConfig.WorkingDir = "/";
      };
    in
    {
      hello-english = {
        enable = true;
        settings.container = commonSettings;
        extraConfig.services.hello.hello.extraArgs = [
          "--greeting"
          "Hello"
        ];
      };
      hello-italian = {
        enable = true;
        settings.container = commonSettings;
        extraConfig.services.hello.hello.extraArgs = [
          "--greeting"
          "Ciao"
        ];
      };
      hello-spanish = {
        enable = true;
        settings.container = commonSettings;
        extraConfig.services.hello.hello.extraArgs = [
          "--greeting"
          "Hola"
        ];
      };
    };

  # TODO: remove

  # programs = {
  #   enable = true;
  #   requirements = [
  #     pkgs.mypkgs.hello
  #   ];
  # };

  # containers = {
  #   enable = true;
  #   images = [
  #     {
  #       name = "hello-english";
  #       requirements = [ pkgs.mypkgs.hello ];
  #       config.CMD = [
  #         "hello"
  #         "--greeting"
  #         "Hello"
  #       ];
  #     }
  #     {
  #       name = "hello-italian";
  #       requirements = [ pkgs.mypkgs.hello ];
  #       config.CMD = [
  #         "hello"
  #         "--greeting"
  #         "Ciao"
  #       ];
  #     }
  #     {
  #       name = "hello-spanish";
  #       requirements = [ pkgs.mypkgs.hello ];
  #       config.CMD = [
  #         "hello"
  #         "--greeting"
  #         "Hola"
  #       ];
  #     }
  #   ];
  #   composeFile = ./compose.yaml;
  # };
}
