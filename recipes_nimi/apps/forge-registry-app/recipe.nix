{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "forge-registry-app";
  version = "0.1.0";
  description = "OCI-compliant container registry for Nix Forge.";
  usage = ''
    This service provides a OCI-compliant container registry for Nix Forge
    and allows to load Nix Forge containers directly to Docker, Podman or
    Kubernetes.

    * Deploy registry in a shell environment (see instructions below)
       and launch it
    ```
      forge-registry
    ```

    * Launch example package container with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/packages/hello:latest
    ```

    * Launch example application with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/applications/python-web-app/api:latest
    ```

    * Launch example application with Kubernetes
    ```
      kubectl run python-web \
      --image=localhost:6443/applications/python-web-app/api:latest
    ```
  '';

  # Portable services configuration (new interface)
  services = {
    registry = {
      process.argv = [ (lib.getExe pkgs.mypkgs.forge-registry) ];
      configData = {
        "registry.conf" = {
          text = ''
            FLASK_HOST=0.0.0.0
            FLASK_PORT=6443
            GITHUB_REPO=github:imincik/nix-forge
            LOG_LEVEL=INFO
          '';
        };
      };
      requirements = [
        pkgs.mypkgs.forge-registry
      ];
    };
  };

  containers = {
    enable = true;
    settings = {
      container = {
        name = "forge-registry";
        copyToRoot = [
          pkgs.mypkgs.forge-registry
          pkgs.nix
        ];
      };
    };
  };

  nixos = {
    enable = true;
    name = "forge-registry";
    extraConfig = {
      systemd.services.forge-registry = {
        description = "Nix Forge container registry";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        environment = {
          FLASK_HOST = "0.0.0.0";
          FLASK_PORT = "6443";
          GITHUB_REPO = "github:imincik/nix-forge";
          LOG_LEVEL = "INFO";
        };
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.mypkgs.forge-registry}/bin/forge-registry";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        path = [ pkgs.nix ];
      };
      nix.settings = {
        trusted-users = [
          "root"
          "@wheel"
          "@trusted"
        ];
        experimental-features = [
          "flakes"
          "nix-command"
        ];
      };
    };
    vm = {
      ports = [ "6443:6443" ];
      memorySize = 1024 * 4;
      diskSize = 1024 * 10;
    };
  };
}
