{ pkgs
, lib
, fetchurl
, rPackages
}:

let
  mkCranDerive = { snapshot }: { name, version, md5, depends }:
    rPackages.buildRPackage {
      name = "${name}-${version}";
      src = fetchurl {
        outputHash = md5;
        outputHashAlgo = "md5";
        url = "https://mran.revolutionanalytics.com/snapshot/${snapshot}/src/contrib/${name}_${version}.tar.gz";
      };
      propagatedBuildInputs = depends;
      nativeBuildInputs = depends;
    };

  overrides = new: old:
    let
      withNativeBuildInputs = what: inputs:
        what.overrideAttrs (attrs: {
          nativeBuildInputs = attrs.nativeBuildInputs ++ inputs;
        });
    in
    old // {
      curl = withNativeBuildInputs old.curl [ pkgs.curl.dev ];

      data_table = old.data_table.overrideAttrs (attrs: {
        NIX_CFLAGS_COMPILE = attrs.NIX_CFLAGS_COMPILE + " -fopenmp";
        nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.zlib.dev ];
        patchPhase = "patchShebangs configure";
      });

      gert = withNativeBuildInputs old.gert [ pkgs.libgit2 ];

      haven = with pkgs; withNativeBuildInputs old.haven [ libiconv zlib.dev ];
      httpuv = withNativeBuildInputs old.httpuv [ pkgs.zlib.dev ];

      openssl = old.openssl.overrideAttrs (attrs: {
        PKGCONFIG_CFLAGS = "-I${pkgs.openssl.dev}/include";
        PKGCONFIG_LIBS = "-Wl,-rpath,${lib.getLib pkgs.openssl}/lib -L${lib.getLib pkgs.openssl}/lib -lssl -lcrypto";
      });

      png = withNativeBuildInputs old.png [ pkgs.libpng.dev ];

      ps = old.ps.overrideAttrs (attrs: {
        patchPhase = "patchShebangs configure";
      });

      purrr = old.purrr.overrideAttrs (attrs: {
        patchPhase = "patchShebangs configure";
      });

      ragg = withNativeBuildInputs old.ragg [ pkgs.freetype.dev pkgs.libtiff.dev ];

      systemfonts = withNativeBuildInputs old.systemfonts [ pkgs.fontconfig ];

      stringi = withNativeBuildInputs old.stringi [ pkgs.icu.dev ];

      textshaping = withNativeBuildInputs old.textshaping [ pkgs.pkg-config pkgs.harfbuzz.dev pkgs.freetype.dev pkgs.fribidi ];

      xml2 = withNativeBuildInputs old.xml2 [ pkgs.libxml2.dev ];
    };

  self = (overrides self _self);
  _self = { inherit (rPackages) buildRPackage; } // import ./cran.nix { inherit self; inherit mkCranDerive; };
in
self

