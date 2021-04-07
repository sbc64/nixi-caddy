{ pkgs ? import (import ./nix/sources.nix).nixpkgs {} }:
with pkgs;
let
  version = "2.4.0-beta.2";
in
rec {
  cloudflare-dns-caddy = buildGoPackage rec {
    name = "caddy";
    rev = "v${version}";
    goPackagePath = "caddy";
    src = ./.;
    goDeps = ./deps.nix;
    buildPhase = ''
      runHook preBuild
       (
         cd go/src/${goPackagePath}
         go build -o caddy -ldflags=-s -ldflags=-w -trimpath
       )
       runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -D go/src/${goPackagePath}/caddy $out/bin/caddy
      runHook postInstall
    '';
  };
  docker = dockerTools.buildLayeredImage {
    name = cloudflare-dns-caddy.name;
    created = "now";
    config = {
      Env = [
        "XDG_CONFIG_HOME=/config"
        "XDG_DATA_HOME=/data"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "CADDY_VERSION=${version}"
      ];
      Cmd = [ 
        "${cloudflare-dns-caddy}/bin/caddy"
        "run"
        "-watch"
        "-environ"
        "--adapter"
        "caddyfile"
        "--config"
        "/Caddyfile"
      ];
    };
  };
}
