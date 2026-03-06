{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "hello-app";
  version = "1.0.0";
  description = "Say hello in multiple languages.";

  programs = {
    enable = true;
    requirements = [
      pkgs.mypkgs.hello
    ];
  };

  oci = {
    hello-english = {
      enable = true;
      settings.container = {
        # name = "hello-english";
        copyToRoot = [ pkgs.mypkgs.hello ];
        imageConfig.WorkingDir = "/";
      };
      composeFile = ./compose.yaml;
    };
  };

  containers = {
    enable = true;
    images = [
      {
        name = "hello-english";
        requirements = [ pkgs.mypkgs.hello ];
        config.CMD = [
          "hello"
          "--greeting"
          "Hello"
        ];
      }
      {
        name = "hello-italian";
        requirements = [ pkgs.mypkgs.hello ];
        config.CMD = [
          "hello"
          "--greeting"
          "Ciao"
        ];
      }
      {
        name = "hello-spanish";
        requirements = [ pkgs.mypkgs.hello ];
        config.CMD = [
          "hello"
          "--greeting"
          "Hola"
        ];
      }
    ];
    composeFile = ./compose.yaml;
  };
}
