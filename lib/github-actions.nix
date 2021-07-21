{ pkgs, lib ? pkgs.lib, ... }:

with lib;

let
  # linkFarmFromDrvs sometimes fails when there are two derivations with the same name so create
  # a link farm where the links are the full nix-store hash plus name.
  safeLinkFarm = name: drvs:
    let mkEntryFromDrv = drv: { name = pkgs.lib.removePrefix "/nix/store/" drv; path = drv; };
    in pkgs.linkFarm name (map mkEntryFromDrv drvs);

  canCachePackage = { meta, preferLocalBuild ? false, allowSubstitutes ? true, ... }:
    (attrByPath [ "license" "free" ] true meta);
in
# Make a derivation depending on all the system and home-manager packages of a nixosConfiguration,
# ignoring packages that should not be cached due to licence issues
{ config, ... }:
  let pkgsToBuild = filter canCachePackage (unique (config.environment.systemPackages ++ config.primary-user.home-manager.home.packages));
  in safeLinkFarm "${config.networking.hostName}-linkfarm" pkgsToBuild

