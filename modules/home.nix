{ pkgs, localPkgs, ... }:

{
  programs.bash.enable = true;

  programs.fish = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    userName = "James Atkins";
    userEmail = "code@jamesatkins.net";
  };

  programs.helix = {
    enable = true;
    package = localPkgs.helix;
    settings = {
      theme = "tokyonight_storm";
    };
  };

  home.packages = with pkgs; [
    fossil
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };
}
