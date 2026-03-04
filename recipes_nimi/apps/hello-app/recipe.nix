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

  services = {
    hello-english = {
      process.argv = [
        (lib.getExe pkgs.mypkgs.hello)
        "--greeting"
        "Hello"
      ];
      requirements = [ pkgs.mypkgs.hello ];
    };
    hello-italian = {
      process.argv = [
        (lib.getExe pkgs.mypkgs.hello)
        "--greeting"
        "Ciao"
      ];
      requirements = [ pkgs.mypkgs.hello ];
    };
    hello-spanish = {
      process.argv = [
        (lib.getExe pkgs.mypkgs.hello)
        "--greeting"
        "Hola"
      ];
      requirements = [ pkgs.mypkgs.hello ];
    };
  };

  containers = {
    enable = true;
    settings = {
      container = {
        name = "hello-app";
        copyToRoot = [ pkgs.mypkgs.hello ];
      };
    };
  };
}
