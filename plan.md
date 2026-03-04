# Nix Forge: Modular Services & Nimi Implementation Plan

## Objective

Re-implement current Nix Forge application configuration to use portable application configuration and implement containers output using [Nimi](https://github.com/weyl-ai/nimi).

## New `application` options design

### Portable options

- name
- version
- description
- usage
- services.\<name>: https://nixos.org/manual/nixos/unstable/#service-opt-services
  - process.argv: https://nixos.org/manual/nixos/unstable/#service-opt-process.argv
  - configData: https://nixos.org/manual/nixos/unstable/#service-opt-configData
  - requirements: list of Nix packages required by this service (used to build appDrv)

### Specific options

- containers:
  - enable
  - settings: https://weyl-ai.github.io/nimi/options.html#settingscontainer
  - extraConfig: arbitrary additional system specific configuration

- nixos (renamed from vm)
  - enable
  - settings: see https://weyl-ai.github.io/nimi/nixos-module.html
  - extraConfig: arbitrary additional system specific configuration
  - vm
    - cores
    - diskSize
    - memorySize
    - ports

### Notes

- For portable services configuration see https://weyl-ai.github.io/nimi/nixos-module.html
- Original `vm` option is renamed to `nixos`
- Original `containers.images.*` option is dropped
- `programs` option is replaced entirely by `services`

## Implementation Phases

### Phase 1: Add Nimi Input

Add `nimi` flake input to `flake.nix` pointing to `github:weyl-ai/nimi`

### Phase 2: Create New `forge_nimi` Directory Structure

```
forge_nimi/
├── flake-module.nix      # New flake module entry point
├── modules/
│   └── apps/
│       ├── default.nix  # Main apps config with build logic
│       ├── app.nix      # App item definition with new options
│       ├── containers.nix   # Nimi-based container config
│       └── nixos.nix    # NixOS/VM config
└── packages.nix         # (if needed)
```

### Phase 3: Implement New App Options (`forge_nimi/modules/apps/app.nix`)

**Portable services (replaces `programs`):**

```nix
services.<name> = {
  process.argv = [ (lib.getExe pkgs.mypkgs.some-package) "--flag" ];
  configData."config.conf" = { text = "port=8080"; };
  requirements = [ pkgs.mypkgs.some-package ];  # Nix packages to bundle in appDrv
};
```

**Containers:**

```nix
containers = {
  enable = true;
  settings = {
    # Nimi container settings per https://weyl-ai.github.io/nimi/options.html#settingscontainer
  };
  extraConfig = { };  # arbitrary additional config
};
```

**Nixos (replaces `vm`):**

```nix
nixos = {
  enable = true;
  settings = { };     # Nimi settings
  extraConfig = { }; # arbitrary NixOS config
  vm = {
    cores = 4;
    diskSize = 4096;
    memorySize = 2048;
    ports = [ "8080:80" ];
  };
};
```

### Phase 4: Implement Build Logic (`forge_nimi/modules/apps/default.nix`)

- Add `nimi` to module args
- Implement build logic using Nimi module outputs
- Aggregate all `services.*.requirements` from all services to build appDrv
- Update `appsFilter` for new option paths:
  - `services.*.process.argv`, `services.*.configData`, `services.*.requirements`
  - `containers.enable`, `containers.settings`, `containers.extraConfig`
  - `nixos.enable`, `nixos.settings`, `nixos.extraConfig`, `nixos.vm.*`

### Phase 5: Update Main Flake (`flake.nix`)

- Import `forge_nimi/flake-module.nix` alongside existing forge module
- This allows comparing both implementations during the spike
- The existing `programs` option remains functional for backward compatibility
- Decision on full migration will be made after spike goals are evaluated

## Backward Compatibility

- Existing recipes using `programs` continue to work unchanged
- New recipes can use either `programs` (legacy) or `services` (new portable design)
- Goal: Support both during transition period, then deprecate `programs`

## TODO

- Later phase: Migrate from `dockerTools` to `nix2container` (via Nimi)

## Resources

- Current Nix Forge application configuration: https://forge.imincik.app/options.html#option-apps.*.name
- Modular services docs: https://nixos.org/manual/nixos/unstable/#modular-services
- Nimi configuration options: https://weyl-ai.github.io/nimi/options.html#settingscontainer
