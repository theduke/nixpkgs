{ fetchPypi
, lib
, buildPythonPackage
, attrs
, click
, effect
, jinja2
}:

buildPythonPackage rec {
  pname = "nix-prefetch-github";
  version = "2.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "3d507f70bd0d541e691f144c8e0f132dab6f22f1e37c2bda45605a9d51d84fe1";
  };

  propagatedBuildInputs = [
    attrs
    click
    effect
    jinja2
  ];

  meta = with lib; {
    description = "Prefetch sources from github";
    homepage = "https://github.com/seppeljordan/nix-prefetch-github";
    license = licenses.gpl3;
    maintainers = with maintainers; [ seppeljordan ];
  };
}
