{
  lib,
  self,
  inputs,
  ...
}:

{
  imports = [
    ./modules/apps
  ];

  config = {
    _module.args.inputs = lib.mkForce inputs;

    perSystem =
      {
        config,
        lib,
        pkgs,
        ...
      }@args:

      let
        loadRecipes =
          dir:
          if dir == null then
            [ ]
          else
            let
              dirPath = self.outPath + "/${dir}";
              recipeFiles = (inputs.import-tree.withLib lib).leafs dirPath;
              pkgsExtended = pkgs // {
                mypkgs = config.packages;
              };
              callRecipes = map (file: import file (args // { pkgs = pkgsExtended; }));
            in
            callRecipes recipeFiles;

        packageRecipes = loadRecipes config.forge.recipeDirs.packages;
        appRecipes = loadRecipes config.forge.recipeDirs.apps;
      in
      {
        forge.packages = packageRecipes;
        forge.apps = appRecipes;
      };
  };
}
