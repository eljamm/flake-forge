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

  services.hello = {
    imports = [ pkgs.mypkgs.hello.services.default ];
  };

  oci = {
    hello-english = {
      enable = true;
      settings.container = {
        copyToRoot = [ pkgs.mypkgs.hello ];
        imageConfig.WorkingDir = "/";
      };
    };
    hello-italian = {
      enable = true;
      settings.container = {
        copyToRoot = [ pkgs.mypkgs.hello ];
        imageConfig.WorkingDir = "/";
      };
      extraConfig = {
        hello.hello.extraArgs = "--greeting Ciao";
      };
    };
    hello-spanish = {
      enable = true;
      settings.container = {
        copyToRoot = [ pkgs.mypkgs.hello ];
        imageConfig.WorkingDir = "/";
      };
      extraConfig = {
        hello.hello.extraArgs = "--greeting Hola";
      };
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
