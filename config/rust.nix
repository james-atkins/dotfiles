{ pkgs, rust-overlay, ... }:

let
  rustStable = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rls" "rustfmt" ];
  };
in
  {
    nixpkgs.overlays = [ rust-overlay ];

    primary-user.home-manager = {
      home.packages = with pkgs; [ rustStable gcc rust-analyzer ];

      home.sessionVariables = {
        RUST_SRC_PATH = "${rustStable}/lib/rustlib/src/rust";
      };
    };
  }
