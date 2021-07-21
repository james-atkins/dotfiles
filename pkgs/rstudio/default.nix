{ lib, mkDerivation, fetchurl, fetchpatch, fetchFromGitHub, makeDesktopItem, cmake, boost, zlib
, openssl, R, rPackages, qtbase, qtxmlpatterns, qtsensors, qtwebengine, qtwebchannel
, libuuid, hunspellDicts, unzip, ant, openjdk8, gnumake, makeWrapper, pandoc
, llvmPackages, libyamlcpp, soci, postgresql, sqlite, nodejs, mkYarnPackage, qmake
}:

with lib;
mkDerivation rec {
  pname = "RStudio";
  RSTUDIO_VERSION_MAJOR = "1";
  RSTUDIO_VERSION_MINOR = "4";
  RSTUDIO_VERSION_PATCH = "1717";
  version = "${RSTUDIO_VERSION_MAJOR}.${RSTUDIO_VERSION_MINOR}.${RSTUDIO_VERSION_PATCH}";

  nativeBuildInputs = [ cmake unzip ant openjdk8 makeWrapper pandoc nodejs postgresql ];

  buildInputs = [ boost zlib openssl R qtbase qtxmlpatterns qtsensors
                  qtwebengine qtwebchannel libuuid libyamlcpp postgresql.lib sociRStudio ];

  src = fetchFromGitHub {
    owner = "rstudio";
    repo = "rstudio";
    rev = "v${version}";
    sha256 = "0lcnx5spcp5dypvdb7jf8515gnrwx5gk374xf7lri47wqwv5pkgm";
  };

  patches = [ ./r-location.patch ./clang-location.patch ./soci-cmake.patch ];
  postPatch = ''
    substituteInPlace src/cpp/core/libclang/LibClang.cpp \
      --replace '@libclang@' ${llvmPackages.libclang.lib} \
      --replace '@libclang.so@' ${llvmPackages.libclang.lib}/lib/libclang.so
    substituteInPlace src/cpp/CMakeLists.txt --replace '@SOCI_LIBRARY_DIR@' ${sociRStudio}/lib
    substituteInPlace src/gwt/build.xml \
      --replace '/opt/rstudio-tools/dependencies/common/node/''${node.version}/bin/node' ${nodejs}/bin/node
    substituteInPlace src/gwt/panmirror/src/editor/fuse.js \
      --replace 'return FuseBox.init({' 'return FuseBox.init({cache: false,'
  '';

  hunspellDictionaries = filter isDerivation (unique (attrValues hunspellDicts));
  # These dicts contain identically-named dict files, so we only keep the
  # -large versions in case of clashes
  largeDicts = filter (d: hasInfix "-large-wordlist" d) hunspellDictionaries;
  otherDicts = filter (d: !(hasAttr "dictFileName" d &&
                            elem d.dictFileName (map (d: d.dictFileName) largeDicts))) hunspellDictionaries;
  dictionaries = largeDicts ++ otherDicts;

  mathJaxSrc = fetchurl {
    url = "https://s3.amazonaws.com/rstudio-buildtools/mathjax-27.zip";
    sha256 = "0xj143xqijybf13jaq534rvgplhjqfimwazbpbyc20yfqjkblv65";
  };

  sociRStudio = soci.overrideAttrs (old: { 
    pname = "soci-rstudio";
    buildInputs = old.buildInputs ++ [ boost postgresql postgresql.lib ];
    nativeBuildInputs = old.nativeBuildInputs ++ [postgresql ];
    cmakeFlags = [
      "-DSOCI_TESTS=OFF"
      "-DSOCI_CXX11=ON"
      "-DSOCI_EMPTY=OFF"
      "-DWITH_BOOST=ON"
      "-DWITH_POSTGRESQL=ON"
      "-DWITH_SQLITE3=ON"
    ];
  });

  panmirror = mkYarnPackage { 
    src = "${src}/src/gwt/panmirror/src/editor";
    packageJson = "${src}/src/gwt/panmirror/src/editor/package.json";
    yarnLock = "${src}/src/gwt/panmirror/src/editor/yarn.lock";
  };

  preConfigure = ''
      mkdir dependencies/dictionaries
      for dict in ${builtins.concatStringsSep " " dictionaries}; do
        for i in "$dict/share/hunspell/"*; do
          ln -sv $i dependencies/dictionaries/
        done
      done

      unzip ${mathJaxSrc} -d dependencies/

      mkdir -p dependencies/pandoc/${pandoc.version}
      ln -sv ${pandoc}/bin/pandoc dependencies/pandoc/${pandoc.version}/pandoc

      ln -sv "${panmirror}/libexec/panmirror/node_modules" src/gwt/panmirror/src/editor/node_modules
    '';

    cmakeFlags = [
      "-DRSTUDIO_TARGET=Desktop"
      "-DQT_QMAKE_EXECUTABLE=${qmake}/bin/qmake"
      "-DRSTUDIO_USE_SYSTEM_YAML_CPP=YES"
      "-DRSTUDIO_USE_SYSTEM_SOCI=YES"
      "-DPANDOC_VERSION=${pandoc.version}"
    ];

  desktopItem = makeDesktopItem {
    name = "${pname}-${version}";
    exec = "rstudio %F";
    icon = "rstudio";
    desktopName = "RStudio";
    genericName = "IDE";
    comment = meta.description;
    categories = "Development;";
    mimeType = "text/x-r-source;text/x-r;text/x-R;text/x-r-doc;text/x-r-sweave;text/x-r-markdown;text/x-r-html;text/x-r-presentation;application/x-r-data;application/x-r-project;text/x-r-history;text/x-r-profile;";
  };

  qtWrapperArgs = [ "--suffix PATH : ${gnumake}/bin" ];

  postInstall = ''
      mkdir $out/share
      cp -r ${desktopItem}/share/applications $out/share
      mkdir $out/share/icons
      ln $out/rstudio.png $out/share/icons
  '';

  meta = with lib;
    { description = "Set of integrated tools for the R language";
      homepage = "https://www.rstudio.com/";
      license = licenses.agpl3;
      maintainers = [
        { 
          email = "code@jamesatkins.net";
          github = "james-atkins";
          name = "James Atkins";
        }
      ];
      platforms = platforms.linux;
    };
}
