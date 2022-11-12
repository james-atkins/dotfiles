{ self, config, pkgs, nixpkgs, ... }:
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
  };

  system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    registry.nixpkgs.flake = nixpkgs;
    nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];

    binaryCaches = [ "https://james-atkins.cachix.org" ];
    binaryCachePublicKeys = [ "james-atkins.cachix.org-1:Ljm14bKUUSXidZleVQejHDjDp1lrI7Rh/2WsY5ax280="];
  };

  nixpkgs.config.allowUnfree = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  users.users = {
    james = {
      isNormalUser = true;
      uid = 1000;
      home = "/home/james";
      description = "James Atkins";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBF2zwPXy8sRqpsHOTs0krU7RtGO0cSg5EDaGj4LOJ6/nL7wtOM8q/yxUpndMOKJFIKll9Bna4GS7Ft9UFEgmi3AAAAAEc3NoOg== Yubikey 5"
      ];
    };
  };
}
