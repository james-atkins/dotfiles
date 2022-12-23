{ pkgs, ... }:

{
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

  programs.helix = {
    enable = true;
    settings = {
      theme = "tokyonight";
    };
  };

  home.sessionVariables = {
    EDITOR = "hx";
  };
}
