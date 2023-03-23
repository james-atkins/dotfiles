{ stdenvNoCC, fetchgit }:

stdenvNoCC.mkDerivation {
  name = "foot-themes";
  src = fetchgit {
    name = "foot-themes";
    url = "https://codeberg.org/dnkl/foot.git";
    rev = "1.13.1";
    sha256 = "sha256-XlFTnpS4qITRwhN1IwVWH82gzd2efqWSTynzpgxcH0w=";
  };

  installPhase = ''
      	mkdir $out
    		cp $src/themes/* $out
    	'';
}
	
