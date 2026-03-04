{
  inputs,
  nimi,
  mox,
}:

nimi.mkNimiBin {
  services.mox = {
    imports = [ mox.services.default ];
    mox = {
      hostname = "mail";
      user = "admin@example.com";
    };
  };

  settings.restart.mode = "up-to-count";
  settings.restart.time = 2000;
}
