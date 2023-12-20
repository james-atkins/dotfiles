{ config, pkgs, ... }:

{
  services.gitolite = {
    enable = true;
    user = "git";
    group = "git";
    dataDir = "/tank/code/git";
    adminPubkey = builtins.head config.users.users.james.openssh.authorizedKeys.keys;
  };
}
