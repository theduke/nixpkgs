{ stdenv
, lib
, fetchFromGitHub
, pkgconfig
, libelf
, libcap
, libseccomp
, rpcsvc-proto
, libtirpc
}:
let
  modp-ver = "450.57";
  nvidia-modprobe = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nvidia-modprobe";
    rev = modp-ver;
    sha256 = "0r4f6lpbbqqs9932xd2mr7bxn6a3xdalcwq332fc1amrrkgzfyv7";
  };
in
stdenv.mkDerivation rec {
  pname = "libnvidia-container";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "libnvidia-container";
    rev = "v${version}";
    sha256 = "1csxl2m7gwgf727gbpj58lppavnxn0n4ylf63lii6vfz0qswhv61";
  };

  patches = [
    # locations of nvidia-driver libraries are not resolved via ldconfig which
    # doesn't get used on NixOS. Additional support binaries like nvidia-smi
    # are not resolved via the environment PATH but via the derivation output
    # path.
    # ./libnvc-ldconfig-and-path-fixes.patch
    ./patches/libvnc-disable-ldconfig-update.patch

    # the libnvidia-container Makefile wants to build and install static
    # libtirpc libraries; this patch prevents that from happening
    ./patches/avoid-static-libtirpc-build.patch
  ];

  makeFlags = [
    "WITH_LIBELF=yes"
    "prefix=$(out)"
    # we can't use the WITH_TIRPC=yes flag that exists in the Makefile for the
    # same reason we patch out the static library use of libtirpc so we set the
    # define in CFLAGS
    "CFLAGS=-DWITH_TIRPC"
  ];

  postPatch = ''
    sed -i \
      -e 's/^REVISION :=.*/REVISION = ${src.rev}/' \
      -e 's/^COMPILER :=.*/COMPILER = $(CC)/' \
      mk/common.mk

    # Prepare nvidia-modprobe to prevent a download via curl.
    # The steps below are normally done by mk/nvidia-modprobe.mk
    mkdir -p deps/src/nvidia-modprobe-${modp-ver}
    cp -r ${nvidia-modprobe}/* deps/src/nvidia-modprobe-${modp-ver}
    chmod -R u+w deps/src
    patch -d deps/src/nvidia-modprobe-${modp-ver} -p1 < mk/nvidia-modprobe.patch
    touch deps/src/nvidia-modprobe-${modp-ver}/.download_stamp
  '';

  NIX_CFLAGS_COMPILE = [ "-I${libtirpc.dev}/include/tirpc" ];
  NIX_LDFLAGS = [ "-L${libtirpc.dev}/lib" "-ltirpc" ];

  nativeBuildInputs = [ pkgconfig rpcsvc-proto ];

  buildInputs = [ libelf libcap libseccomp libtirpc ];

  meta = with lib; {
    homepage = "https://github.com/NVIDIA/libnvidia-container";
    description = "NVIDIA container runtime library";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
