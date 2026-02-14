{
  description = "Hetzner cluster development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "2.4.5";

        platformMap = {
          x86_64-linux = { suffix = "linux-amd64"; hash = "sha256-GLv+PQZlOalnQZ0FKsD4tK1GkfL3b58i10M8EO8o/qU="; };
          aarch64-linux = { suffix = "linux-arm64"; hash = "sha256-C2DAGIQv1/bFMRbkOfXiXsiwxdfQRxDIH31QVJ5vsZQ="; };
          x86_64-darwin = { suffix = "macos-amd64"; hash = "sha256-gDslA6m60Pnb6tzI96sjhE4dAn2mqyfdYnzNU6YACBg="; };
          aarch64-darwin = { suffix = "macos-arm64"; hash = "sha256-MdacVmbD5KljCcp3DIDgPYRtHIN1T0lnl2WxWIgGwb0="; };
        };

        platform = platformMap.${system} or (throw "Unsupported system: ${system}");

        hetzner-k3s = pkgs.stdenv.mkDerivation {
          pname = "hetzner-k3s";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/vitobotta/hetzner-k3s/releases/download/v${version}/hetzner-k3s-${platform.suffix}";
            hash = platform.hash;
          };

          dontUnpack = true;

          installPhase = ''
            install -Dm755 $src $out/bin/hetzner-k3s
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            hetzner-k3s
            pkgs.kubectl
            pkgs.k9s
            pkgs.kubernetes-helm
          ];

          shellHook = ''
            echo "Hetzner cluster dev environment loaded"
            echo "Tools: hetzner-k3s, kubectl, k9s, helm"
          '';
        };
      });
}
