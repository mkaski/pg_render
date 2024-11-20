{
  description = "pg_render";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {

        packages.pg_render = pkgs.buildPgrxExtension rec {
          pname = "pg_render";
          version = "0.1";
          inherit system;
          postgresql = pkgs.postgresql_16;

          src = ./.;
          cargoHash = "sha256-IyOIeYnZNaEVtgon3kPMhTPdpONxNv+/wHVGzQMu/uM=";
        };

        devenv.shells.default = {
          name = "pg_render";

          imports = [
          ];

          # https://devenv.sh/reference/options/
          packages = with pkgs; [
            postgresql_16
            cargo cargo-pgrx rustc rust-analyzer openssl.dev pkg-config
          ];

          services.postgres = {
            enable = true;
            package = pkgs.postgresql_16;
            initialDatabases = [{
              name = "pg_render";
            }];
            extensions = extensions: [
              self'.packages.pg_render
            ];
            settings = {
              # "wal_level" = "logical";
              "shared_preload_libraries" = "auto_explain";
              "auto_explain.log_min_duration" = "0ms";
              "auto_explain.log_nested_statements" = true;
              "auto_explain.log_timing" = true;
              "auto_explain.log_analyze" = true;
              "auto_explain.log_triggers" = true;
            };
          };
        };
      };
    };
}


