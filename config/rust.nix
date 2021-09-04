{ pkgs, rust-overlay, ... }:

let
  rustStable = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rls" ];
  };
in
  {
    nixpkgs.overlays = [ rust-overlay ];

    primary-user.home-manager = {
      home.packages = [ rustStable ];

      home.sessionVariables = {
        RUST_SRC_PATH = "${rustStable}/lib/rustlib/src/rust";
      };
    };
  }
