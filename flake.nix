{
  description = "Kernel builder for Samsung galaxy A05s";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-kernelsu-builder.url = "github:xddxdd/nix-kernelsu-builder";
    kernelsu = {
      url = "github:tiann/KernelSU/463afa7471b5a753d8bd989a5cb0dc781bfd986";
      flake = false;
    };
    sufs4ksu = {
      url = "gitlab:simonpunk/susfs4ksu/e27713beefb0fdec973c84004a2fb5f0738c75d2";
      flake = false;
    };
  };
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.nix-kernelsu-builder.flakeModules.default
      ];
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          pkgs,
          lib,
          ...
        }:
        {
          kernelsu =
            let
              arch = "arm64";
              clangVersion = "18";
              kernelPatches = [
                (pkgs.fetchpatch {
                  url = "https://github.com/cdpkp/android_kernel_tree_samsung_a05s/commit/72c67f9b85b492a8ba500ce2a03eff1bd78f6b9e.patch";
                  sha256 = "sha256-DXaih7kqe73nl6fT1dyMxT5IlSosYQTaPc/qENXn248=";
                })
                (pkgs.fetchpatch {
                  url = "https://github.com/cdpkp/android_kernel_tree_samsung_a05s/commit/9bd23082815e1c7b455d7384563a454023e0c202.patch";
                  sha256 = "sha256-/IrhIfDniqRZIvoAYmaCnaG9iWnWymKK4X0bmTHq0Ec";
                })
              ];

              kernelDefconfigs = [
                "gki_defconfig"
              ];
              kernelImageName = "Image";
              kernelSrc = ./.;
              oemBootImg = ./oem-boot.img;
            in
            rec {
              default = stock;
              stock = {
                inherit
                  arch
                  clangVersion
                  kernelPatches
                  kernelDefconfigs
                  kernelSrc
                  oemBootImg
                  kernelImageName
                  ;

                anyKernelVariant = "osm0sis";

                kernelSU.enable = false;
                susfs.enable = false;
              };
              kernelsu =
                let
                  patches = kernelPatches;
                in
                {
                  inherit
                    arch
                    clangVersion
                    kernelDefconfigs
                    kernelSrc
                    oemBootImg
                    kernelImageName
                    ;

                  kernelPatches = patches ++ [
                    ./kernelsu.patch
                    (pkgs.fetchpatch {
                      url = "https://raw.githubusercontent.com/WildKernels/kernel_patches/22a2d296b09c936ee11c7b9c2580b7275bf5b02a/69_hide_stuff.patch";
                      hash = "sha256-aPIHwwBdZzWxdUPUnHJjUB/h8kNoYNZsOryFMi89iLQ=";
                    })
                  ];

                  anyKernelVariant = "kernelsu";

                  kernelSU = {
                    enable = true;
                    src = lib.mkForce inputs.kernelsu;
                    variant = "official";
                  };

                  susfs = {
                    enable = true;
                    src = inputs.sufs4ksu;
                  };
                };
            };
        };
    };
}
