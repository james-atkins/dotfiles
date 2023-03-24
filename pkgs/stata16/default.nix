{ lib
, stdenv
, fetchurl
, makeDesktopItem
, copyDesktopItems
, alsa-lib
, autoPatchelfHook
, cairo
, libpng
, libXtst
, gdk-pixbuf
, gtk2
, ncurses5
, pango
, zlib
}:

let
  pname = "stata16";
  description = "Perform statistical analyses using Stata.";
  version = "20220614";

  desktopItem = makeDesktopItem {
    name = pname;
    exec = "xstata16 %F";
    icon = "stata16";
    desktopName = "Stata SE";
    genericName = "IDE";
    comment = description;
    categories = [ "X-Scientific" ];
    mimeTypes = [
      "application/x-stata-dta"
      "application/x-stata-do"
      "application/x-stata-smcl"
      "application/x-stata-stpr"
      "application/x-stata-gph"
      "application/x-stata-stsem"
    ];
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://jdsa3.user.srcf.net/Stata16Linux64_${version}.tar.gz";
    sha256 = "sha256-Q2gQGQilcq0L0E3MEVJMhM+6tx+QnSS97ra6atuO4vg=";
  };
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir $out

    # cd to output directory and run the installer
    cd $out
    (yes || true) | /build/install

    # For purity, set file with installation date and time to the update version
    date -d '${version}' -u > installed.160

    # Tidy up leftover installation files
    rm inst2 setrwxp stinit

    # Remove unlicenced stata versions
    rm stata xstata stata-mp xstata-mp

    # Link to license
    ln -s /etc/stata16.lic stata.lic

    mkdir $out/bin
    ln -s $out/stata-se $out/bin/stata16
    ln -s $out/xstata-se $out/bin/xstata16

    mkdir -p $out/share/icons/hicolor/128x128/apps
    ln -s $out/stata16.png $out/share/icons/hicolor/128x128/apps

    runHook postInstall
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    cairo
    gdk-pixbuf
    gtk2
    libpng
    libXtst
    ncurses5
    pango
    stdenv.cc.cc
    zlib
  ];

  desktopItems = [ desktopItem ];

  meta = with lib; {
    inherit description;
    homepage = "https://www.stata.com/";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}

