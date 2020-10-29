{ pkgs, stdenv, lib, fetchFromGitHub, fetchpatch, callPackage, makeWrapper
, buildGoPackage, buildGoModule, runc, glibc }:

with lib; let

  container-toolkit-version = "1.3.0";
  container-runtime-version = "3.4.0";

  libnvidia-container = callPackage ./libnvc.nix { };

  nvidia-container-runtime-src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nvidia-container-runtime";
    rev = "v${container-runtime-version}";
    sha256 = "095mks0r4079vawi50pk4zb5jk0g6s9idg2s1w55a0d27jkknldr";
  };

  nvidia-container-runtime = buildGoPackage {
    pname = "nvidia-container-runtime";
    version = "v3.4.0";
    goPackagePath = "nvidia-container-runtime";
    src = "${nvidia-container-runtime-src}/src";
  };

  nvidia-container-toolkit = buildGoModule {
    pname = "nvidia-container-toolkit";
    version = "v${container-toolkit-version}";
    src = fetchFromGitHub {
      owner = "NVIDIA";
      repo = "nvidia-container-toolkit";
      rev = "v${container-toolkit-version}";
      sha256 = "04284bhgx4j55vg9ifvbji2bvmfjfy3h1lq7q356ffgw3yr9n0hn";
    };
    vendorSha256 = "17zpiyvf22skfcisflsp6pn56y6a793jcx89kw976fq2x5br1bz7"; 
  };

  # nvidia-runc = runc.overrideAttrs (oldAttrs: rec {
  #   name = "nvidia-runc";
  #   version = "1.0.0-rc6";
  #   src = fetchFromGitHub {
  #     owner = "opencontainers";
  #     repo = "runc";
  #     rev = "v${version}";
  #     sha256 = "1jwacb8xnmx5fr86gximhbl9dlbdwj3rpf27hav9q1si86w5pb1j";
  #   };
  #   patches = [ "${nvidia-container-runtime}/runtime/runc/3f2f8b84a77f73d38244dd690525642a72156c64/0001-Add-prestart-hook-nvidia-container-runtime-hook-to-t.patch" ];
  # });

in stdenv.mkDerivation rec {
  pname = "nvidia-docker";
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nvidia-docker";
    rev = "v${version}";
    sha256 = "1n1k7fnimky67s12p2ycaq9mgk245fchq62vgd7bl3bzfcbg0z4h";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    mkdir bin
    cp nvidia-docker bin
    cp ${libnvidia-container}/bin/nvidia-container-cli bin
    cp ${nvidia-container-runtime}/bin/nvidia-container-runtime bin
    cp ${nvidia-container-toolkit}/bin/pkg bin/nvidia-container-toolkit
  '';

  installPhase = ''
    mkdir -p $out/{bin,etc}
    cp -r bin $out

    mkdir $out/lib

    # Generate a ldconfig cache file for nvidia-container-cli
    ${pkgs.glibc.bin}/bin/ldconfig -C $out/lib/ld.so.cache ${pkgs.linuxPackages.nvidia_x11}/lib 

    # Allow nvidia-container-runtime to find runc
    wrapProgram $out/bin/nvidia-container-runtime \
      --prefix PATH : "${runc}/bin:$out/bin"

    # Create a symlink since the old hook path seems to still be used somewhere
    ln -s $out/bin/nvidia-container-toolkit $out/bin/nvidia-container-runtime-hook 

    wrapProgram $out/bin/nvidia-container-cli \
      --prefix LD_LIBRARY_PATH : "${pkgs.linuxPackages.nvidia_x11}/lib" \
      --prefix PATH : "${pkgs.linuxPackages.nvidia_x11}/bin"

    cp ${./config.toml} $out/etc/config.toml
    substituteInPlace $out/etc/config.toml --subst-var-by glibcbin ${lib.getBin glibc}
    substituteInPlace $out/etc/config.toml --subst-var-by clipath "$out/bin/nvidia-container-cli"

    substituteInPlace $out/etc/config.toml --subst-var-by ldcachepath "$out/lib/ld.so.cache"
  '';

  meta = {
    homepage = "https://github.com/NVIDIA/nvidia-docker";
    description = "NVIDIA container runtime for Docker";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
