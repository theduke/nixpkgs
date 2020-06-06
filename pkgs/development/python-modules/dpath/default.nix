{ stdenv, fetchPypi, buildPythonPackage
, mock, nose
}:

buildPythonPackage rec {
  pname = "dpath";
  version = "2.0.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "bea06b5f4ff620a28dfc9848cf4d6b2bfeed34238edeb8ebe815c433b54eb1fa";
  };

  checkInputs = [ mock nose ];
  checkPhase = ''
    nosetests
  '';

  meta = with stdenv.lib; {
    homepage = "https://github.com/akesterson/dpath-python";
    license = [ licenses.mit ];
    description = "A python library for accessing and searching dictionaries via /slashed/paths ala xpath";
    maintainers = [ maintainers.mmlb ];
  };
}
