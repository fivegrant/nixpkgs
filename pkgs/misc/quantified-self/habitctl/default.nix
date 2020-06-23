{ rustPlatform, lib, fetchFromGitHub, pkgconfig }:

rustPlatform.buildRustPackage rec{
  pname   = "habitctl";
  name    = "habitctl";
  version = "0.1.0";
  
  src = fetchFromGitHub {
    owner  = "blinry";
    repo   = "habitctl";
    rev    = "77c2a9295ed9fbc0fdc36ddc47c68ac959005f71";
    sha256 = "0bim1a1m6s4ji6k1gj6llp3b61b6qz99ighicmm9ypbdhypfpfnx";
  };
  buildInputs = [ pkgconfig ];
  checkPhase = "";
  #cargoSha256 = "sha256:0nwavb6blrnp82fd1xhrqkgg6048181g58n7n34yq09h3mfb85q0";
  cargoSha256 = "sha256:1y27bpzvqx4xxvsi89d92yv4c7xfvcldwgfsanmj7w3clw8rpyav";
  meta = with lib; {
    description = "A minimalist command line tool you can use to track and examine your habits.";
    homepage = "https://github.com/blinry/habitctl";
    # maintainers = with maintainers; [ fivegrant ];
    license = licenses.gpl2;
    platform = platforms.all;
  };
}
