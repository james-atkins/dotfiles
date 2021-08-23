{ pkgs, ... }:

{
  primary-user.home-manager = { 
    home.packages = with pkgs; [
      (sqlite.override { interactive = true; })
    ];

    home.file.".sqliterc".text = ''
      .headers ON
      .mode columns
      .changes ON
    '';
  };
}
