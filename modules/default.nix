{ ... }:

{
  imports = [
    ./core.nix
    ./persistence.nix
    ./users.nix
    ./tailscale.nix
    ./backup.nix
    ./databases.nix
    ./services
    ./desktop
    ./development
  ];
}

