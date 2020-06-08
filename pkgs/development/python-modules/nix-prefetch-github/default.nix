{ fetchPypi
, lib
, buildPythonPackage
, pythonOlder
, attrs
, click
, effect
, jinja2
, git
, pytestCheckHook
, pytest-black
, pytestcov
, pytest-isort
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

  checkInputs = [ pytestCheckHook pytest-black pytestcov pytest-isort git ];

  # aiohttp is not supported on 3.8 yet
  doCheck = pythonOlder "3.8";

  # latest version of isort will cause tests to fail
  # ignore tests which are impure
  disabledTests = [ "isort" "life" "outputs" "fetch_submodules" ];

  meta = with lib; {
    description = "Prefetch sources from github";
    homepage = "https://github.com/seppeljordan/nix-prefetch-github";
    license = licenses.gpl3;
    maintainers = with maintainers; [ seppeljordan ];
  };
}
