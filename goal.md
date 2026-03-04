### Objective

Re-implement current Nix Forge application configuration to use portable application configuration and implement containers output using [Nimi](https://github.com/weyl-ai/nimi).

### New `application` options design

**Portable options**:

- name
- version
- description
- usage
- services.\<name>: <https://nixos.org/manual/nixos/unstable/#service-opt-services>
  - process.argv: <https://nixos.org/manual/nixos/unstable/#service-opt-process.argv>
  - configData: <https://nixos.org/manual/nixos/unstable/#service-opt-configData>

**Specific options:**

- containers:
  - enable
  - settings: <https://weyl-ai.github.io/nimi/options.html#settingscontainer>
  - extraConfig: arbitrary additional system specific configuration

- nixos (renamed from vm)
  - enable
  - settings: see <https://weyl-ai.github.io/nimi/nixos-module.html>
  - extraConfig: arbitrary additional system specific configuration
  - vm
    - cores
    - diskSize
    - memorySize
    - ports

**Notes:**

- For portable services configuration see <https://weyl-ai.github.io/nimi/nixos-module.html>
- Original `vm` option is renamed to `nixos`
- Original `containers.images.*` option is dropped

### Spike goals

- Test new application services design
- Get more practical experience with Nix Forge to support decision whether to start a new NGIpkgs App Store as Nix Forge fork

### Resources
- Current Nix Forge application configuration: <https://forge.imincik.app/options.html#option-apps.*.name>
- Modular services docs: <https://nixos.org/manual/nixos/unstable/#modular-services>
- Nimi configuration options: <https://weyl-ai.github.io/nimi/options.html#settingscontainer>
