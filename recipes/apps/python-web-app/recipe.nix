{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "python-web-app";
  version = "1.0.0";
  description = "Simple web application with database backend.";
  usage = ''
    This is a simple example app which provides a web API to manage a list of
    users.

    * Initialize database
    ```
      curl -X POST localhost:5000/init
    ```

    * Add a new user
    ```
      curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"name":"username"}' \
      localhost:5000/users
    ```

    * Get list of all users
    ```
      curl localhost:5000/users
    ```
  '';

  services.api = {
    imports = [ pkgs.mypkgs.python-web.services.default ];
  };

  oci = {
    enable = true;
    settings.container = {
      name = "api";
      copyToRoot = [
        (pkgs.buildEnv {
          name = "runtime-bins";
          paths = with pkgs; [
            mypkgs.python-web
            coreutils
            bash
          ];
          pathsToLink = [ "/bin" ];
        })
      ];
      imageConfig.WorkingDir = "/";
    };
    composeFile = ./compose.yaml;
  };

  nixos = {
    enable = true;
    name = "database";
    extraConfig = {
      # database service
      services.postgresql.enable = true;
      services.postgresql.enableTCPIP = true;
      services.postgresql.authentication = ''
        local all all trust
        host all all 0.0.0.0/0 trust
        host all all ::0/0 trust
      '';
    };
    vm.ports = [
      "5000:5000"
    ];
  };

  # TODO: remove

  # programs = {
  #   enable = true;
  #   requirements = [
  #     pkgs.curl
  #   ];
  # };

  # containers = {
  #   enable = true;
  #   images = [
  #     {
  #       name = "api";
  #       requirements = [ pkgs.mypkgs.python-web ];
  #       config.CMD = [
  #         "python-web"
  #       ];
  #     }
  #   ];
  #   composeFile = ./compose.yaml;
  # };

}
