{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "hello-app";
  version = "1.0.0";
  description = "Hello application demonstrating the new forge_nimi interface.";

  services.hello = {
    process.argv = [
      (lib.getExe pkgs.mypkgs.hello)
      "--greeting"
      "Hello"
    ];
    configData."greetings.txt" = {
      text = "Hello from forge_nimi!\n";
    };
  };

  containers = {
    enable = true;
    settings = {
      container = {
        name = "hello-app";
        tag = "latest";
        copyToRoot = [ pkgs.mypkgs.hello ];
        imageConfig = {
          Cmd = [
            "hello"
            "--greeting"
            "Hello"
          ];
          Env = [ "GREETING=Hello" ];
          WorkingDir = "/root";
        };
      };
    };
    extraConfig = { };
  };

  nixos = {
    enable = true;
    settings = {
      restart = {
        mode = "up-to-count";
        time = 2000;
        count = 3;
      };
    };
    extraConfig = {
      services.openssh.enable = true;
    };
    vm = {
      cores = 2;
      memorySize = 1024;
      diskSize = 2048;
      ports = [ "10022:22" ];
    };
  };
}
