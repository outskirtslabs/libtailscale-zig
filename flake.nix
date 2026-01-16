{
  description = "zig-based cross-compilation for libtailscale";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    devshell.url = "github:numtide/devshell";
    devenv.url = "https://flakehub.com/f/ramblurr/nix-devenv/*";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    zig.url = "github:mitchellh/zig-overlay";
  };
  outputs =
    inputs@{
      self,
      devenv,
      devshell,
      zig,
      ...
    }:
    devenv.lib.mkFlake ./. {
      inherit inputs;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      nixpkgs.config.allowUnsupportedSystem = true;
      legacyPackages = pkgs: pkgs;
      withOverlays = [
        devshell.overlays.default
        devenv.overlays.default
      ];
      packages = {
        apple-sdk =
          pkgs:
          pkgs.stdenv.mkDerivation {
            name = "apple-sdk_15.2";
            src = pkgs.fetchzip {
              url = "https://github.com/joseluisq/macosx-sdks/releases/download/15.2/MacOSX15.2.sdk.tar.xz";
              hash = "sha256:0fgj0pvjclq2pfsq3f3wjj39906xyj6bsgx1da933wyc918p4zi3";
            };
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p "$out"
              cp -r "$src"/* "$out"
            '';
          };
      };
      devShell =
        pkgs:
        let
          zigpkgs = zig.packages.${pkgs.system};
          apple-sdk = self.packages.${pkgs.system}.apple-sdk;
        in
        pkgs.devshell.mkShell {
          imports = [
            devenv.capsules.base
          ];
          commands = [
          ];
          packages = [
            zigpkgs."0.15.2"
            pkgs.git
            pkgs.go
          ];
          env = [
            {
              name = "APPLE_SDK_PATH";
              value = "${apple-sdk}";
            }
            {
              name = "ZIG_GLOBAL_CACHE_DIR";
              value = ".zig-cache";
            }
          ];
        };
    };
}
