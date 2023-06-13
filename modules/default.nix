{ ... }:

{
  imports = [
    ./core.nix
    ./persistence.nix
    ./users.nix
    ./tailscale.nix
    ./syncthing.nix
    ./backup.nix
    ./desktop
    ./development
  ];
}

