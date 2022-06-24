{ pkgs, ... }:

{
  primary-user.home-manager = { 
    programs.bash.enable = true;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.git = {
      enable = true;
      userName = "James Atkins";
      userEmail = "code@jamesatkins.net";
    };

    home.packages = with pkgs; [
      ranger atool

      texlive.combined.scheme-medium

      borgmatic borgbackup
    ];
  };
}
