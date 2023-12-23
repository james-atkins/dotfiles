{ ... }:

{
  imports = [
    ./core.nix
    ./machine-id.nix
    ./persistence.nix
    ./users.nix
    ./tailscale.nix
    ./backups
    ./databases.nix
    ./programs
    ./services
    ./desktop
    ./development
    ./virt_manager.nix
  ];
}

