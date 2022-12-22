{ lib
, stdenv
, mkDerivation
, fetchurl
, fetchFromGitHub
, makeDesktopItem
, copyDesktopItems
, cmake
, boost
, zlib
, openssl
, R
, qtbase
, qtxmlpatterns
, qtsensors
, qtwebengine
, qtwebchannel
, libuuid
, hunspellDicts
, unzip
, ant
, openjdk8
, gnumake
, pandoc
, llvmPackages
, libyamlcpp
, soci
, postgresql
, nodejs
, mkYarnPackage
, qmake
}:

let
  pname = "RStudio";
  RSTUDIO_VERSION_MAJOR = "2022";
  RSTUDIO_VERSION_MINOR = "02";
  RSTUDIO_VERSION_PATCH = "3";
  RSTUDIO_VERSION_SUFFIX = "+492";
  version = "${RSTUDIO_VERSION_MAJOR}.${RSTUDIO_VERSION_MINOR}.${RSTUDIO_VERSION_PATCH}${RSTUDIO_VERSION_SUFFIX}";

  src = fetchFromGitHub {
    owner = "rstudio";
    repo = "rstudio";
    rev = "v${version}";
    sha256 = "1pgbk5rpy47h9ihdrplbfhfc49hrc6242j9099bclq7rqif049wi";
  };

  mathJaxSrc = fetchurl {
    url = "https://s3.amazonaws.com/rstudio-buildtools/mathjax-27.zip";
    sha256 = "sha256-xWy6psTOA8H8uusrXqPDEtL7diajYCVHcMvLiPsgQXY=";
  };

  rsconnectSrc = fetchFromGitHub {
    owner = "rstudio";
    repo = "rsconnect";
    rev = "e287b586e7da03105de3faa8774c63f08984eb3c";
    sha256 = "sha256-ULyWdSgGPSAwMt0t4QPuzeUE6Bo6IJh+5BMgW1bFN+Y=";
  };

  panmirrorModules = mkYarnPackage {
    name = "rstudio-panmirror";
    version = version;
    src = "${src}/src/gwt/panmirror/src/editor";
    packageJson = "${src}/src/gwt/panmirror/src/editor/package.json";
    yarnLock = "${src}/src/gwt/panmirror/src/editor/yarn.lock";
  };

  description = "Set of integrated tools for the R language";

  desktopItem = makeDesktopItem {
    name = pname;
    exec = "rstudio %F";
    icon = "rstudio";
    desktopName = "RStudio";
    genericName = "IDE";
    comment = description;
    categories = [ "Development" ];
    mimeTypes = [
      "text/x-r-source"
      "text/x-r"
      "text/x-R"
      "text/x-r-doc"
      "text/x-r-sweave"
      "text/x-r-markdown"
      "text/x-r-html"
      "text/x-r-presentation"
      "application/x-r-data"
      "application/x-r-project"
      "text/x-r-history"
      "text/x-r-profile"
    ];
  };
in
mkDerivation rec {
  inherit pname version src RSTUDIO_VERSION_MAJOR RSTUDIO_VERSION_MINOR RSTUDIO_VERSION_PATCH RSTUDIO_VERSION_SUFFIX;

  nativeBuildInputs = [
    cmake
    unzip
    ant
    openjdk8
    pandoc
    nodejs
    copyDesktopItems
  ];

  buildInputs = [
    boost
    zlib
    openssl
    R
    libuuid
    libyamlcpp
    soci
    postgresql
    qtbase
    qtxmlpatterns
    qtsensors
    qtwebengine
    qtwebchannel
  ];

  cmakeFlags = [
    "-DRSTUDIO_TARGET=Desktop"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DRSTUDIO_USE_SYSTEM_SOCI=ON"
    "-DRSTUDIO_USE_SYSTEM_BOOST=ON"
    "-DRSTUDIO_USE_SYSTEM_YAML_CPP=ON"
    "-DPANDOC_VERSION=${pandoc.version}"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}/lib/rstudio"
    "-DQT_QMAKE_EXECUTABLE=${qmake}/bin/qmake"
    "-DQUARTO_ENABLED=OFF"
  ];

  # Hack RStudio to only use the input R and provided libclang.
  patches = [
    ./r-location.patch
    ./clang-location.patch
  ];

  postPatch = ''
    substituteInPlace src/cpp/core/libclang/LibClang.cpp \
      --replace '@libclang@' ${llvmPackages.libclang.lib} \
      --replace '@libclang.so@' ${llvmPackages.libclang.lib}/lib/libclang.so

    substituteInPlace src/cpp/CMakeLists.txt \
      --replace 'SOCI_LIBRARY_DIR "/usr/lib"' 'SOCI_LIBRARY_DIR "${soci}/lib"'

    substituteInPlace src/gwt/build.xml \
      --replace '/opt/rstudio-tools/dependencies/common/node/''${node.version}/bin/node' ${nodejs}/bin/node

    substituteInPlace src/gwt/panmirror/src/editor/fuse.js \
      --replace 'return FuseBox.init({' 'return FuseBox.init({cache: false,'

    substituteInPlace src/cpp/session/include/session/SessionConstants.hpp \
      --replace "bin/pandoc" "${pandoc}/bin/pandoc"
  '';

  hunspellDictionaries = with lib; filter isDerivation (unique (attrValues hunspellDicts));
  # These dicts contain identically-named dict files, so we only keep the
  # -large versions in case of clashes
  largeDicts = with lib; filter (d: hasInfix "-large-wordlist" d.name) hunspellDictionaries;
  otherDicts = with lib; filter
    (d: !(hasAttr "dictFileName" d &&
      elem d.dictFileName (map (d: d.dictFileName) largeDicts)))
    hunspellDictionaries;
  dictionaries = largeDicts ++ otherDicts;

  preConfigure = ''
    mkdir dependencies/dictionaries
    for dict in ${builtins.concatStringsSep " " dictionaries}; do
      for i in "$dict/share/hunspell/"*; do
        ln -s $i dependencies/dictionaries/
      done
    done

    unzip -q ${mathJaxSrc} -d dependencies/mathjax-27

    mkdir -p dependencies/pandoc/${pandoc.version}
    cp ${pandoc}/bin/pandoc dependencies/pandoc/${pandoc.version}/pandoc

    cp -r ${rsconnectSrc} dependencies/rsconnect
    ( cd dependencies && ${R}/bin/R CMD build -d --no-build-vignettes rsconnect )

    cp -r "${panmirrorModules}" src/gwt/panmirror/src/editor/node_modules
  '';

  postInstall = ''
    mkdir -p $out/bin $out/share

    mkdir -p $out/share/icons/hicolor/48x48/apps
    ln $out/lib/rstudio/rstudio.png $out/share/icons/hicolor/48x48/apps

    ln -s $out/lib/rstudio/bin/rstudio $out/bin

    # for f in diagnostics rpostback rstudio
    #   ln -s $out/lib/rstudio/bin/$f $out/bin
    # done

    for f in .gitignore .Rbuildignore LICENSE README; do
      find . -name $f -delete
    done

    rm -r $out/lib/rstudio/{INSTALL,COPYING,NOTICE,README.md,SOURCE,VERSION}
    rm -r $out/lib/rstudio/bin/{pandoc/pandoc,pandoc}
  '';

  meta = with lib; {
    inherit description;
    homepage = "https://www.rstudio.com/";
    license = licenses.agpl3Only;
    mainProgram = "rstudio";
    platforms = platforms.linux;
  };

  qtWrapperArgs = [
    "--suffix PATH : ${lib.makeBinPath [ gnumake ]}"
  ];

  desktopItems = [ desktopItem ];

}

