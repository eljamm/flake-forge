# Forge_2 Example: Hello App

This example demonstrates the new forge_2 interface with modular services and Nimi containers.

## Recipe Location

`recipes_2/apps/hello-app/recipe.nix`

## What's Included

- **services.hello** - Portable service using modular services
- **containers** - Nimi-based container configuration  
- **nixos** - NixOS VM configuration

## Running the Application

### Build the app bundle:

```bash
nix build .#hello-app
```

### Run the service:

```bash
./result/bin/nimi
```

Note: The service implementation is a stub - actual Nimi runtime integration is TODO.

### Build container image:

```bash
nix build .#hello-app.containers
```

Note: Container build is a stub placeholder - full Nimi nix2container integration is TODO.

### Build VM:

```bash
nix build .#hello-app.vm
```

Note: VM build requires the nixos module to be properly configured.

## Comparing with Original Forge

To compare with the original forge interface:

```bash
# Original forge app
nix build .#hello-app

# New forge_2 app  
nix build .#hello-app
```

Both should produce similar outputs, but with different internal implementations.

## Key Differences

| Old (forge) | New (forge_2) |
|-------------|---------------|
| `programs.enable` | (implicit when services defined) |
| `programs.requirements` | `services.<name>.process.argv` |
| `containers.images[]` | `containers.settings.container.copyToRoot` |
| `vm.enable` | `nixos.enable` |
| `vm.config.system` | `nixos.extraConfig` |

## Notes

- This is a proof-of-concept implementation
- Container build uses stub - full Nimi nix2container integration is marked as TODO
- VM build requires proper nixpkgs/NixOS module configuration
