{ lib
, buildPythonPackage
, fetchPypi
, numpy
, patsy
, pytest
, scipy
, sympy
}:

let
  pyhdfe = buildPythonPackage rec {
    pname = "pyhdfe";
    version = "0.1.0";

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-ggpAci1w6UzsHc0UDWxIDwJXj+6WZgtyKi5yLCIi43c=";
    };

    checkInputs = [ pytest ];
    propagatedBuildInputs = [
      numpy
      scipy
    ];

    meta = with lib; {
      homepage = "https://github.com/jeffgortmaker/pyhdfe";
      description = " High dimensional fixed effect absorption with Python 3";
      license = licenses.mit;
    };
  };
in
buildPythonPackage rec {
  pname = "pyblp";
  version = "0.13.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-jePgbP0yqR+Agz1wv95CEnRQ5HV40VHTL7yPGTa5kg4=";
  };

  checkInputs = [ pytest ];
  propagatedBuildInputs = [
    numpy
    patsy
    pyhdfe
    scipy
    sympy
  ];

  meta = with lib; {
    homepage = "https://github.com/jeffgortmaker/pyblp";
    description = "BLP Demand Estimation with Python";
    license = licenses.mit;
  };
}

