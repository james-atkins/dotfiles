{ ... }:

{
  imports = [
    ./core.nix
    ./persistence.nix
    ./users.nix
    ./tailscale.nix
    ./backup.nix
    ./postgres.nix
    ./services
    ./desktop
    ./development
  ];
}

