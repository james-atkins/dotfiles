{ ... }:

{
  imports = [
    ./core.nix
    ./machine-id.nix
    ./persistence.nix
    ./users.nix
    ./tailscale.nix
    ./backup.nix
    ./databases.nix
    ./programs
    ./services
    ./desktop
    ./development
  ];
}

