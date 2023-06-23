{ ... }:

{
  imports = [
    ./core.nix
    ./persistence.nix
    ./users.nix
    ./tailscale.nix
    ./backup.nix
    ./services
    ./desktop
    ./development
  ];
}

