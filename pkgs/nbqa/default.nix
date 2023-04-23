{ lib
, buildPythonPackage
, fetchPypi
, autopep8
, ipython
, tomli
, tokenize-rt
}:

buildPythonPackage rec {
  pname = "nbqa";
  version = "1.7.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-EXESrW1hj/E6/FukHKD/IcI/CEpt94dfsEt/LAGhNsQ=";
  };

  # checkInputs = [ pytest ];
  propagatedBuildInputs = [
    autopep8
    ipython
    tomli
    tokenize-rt
  ];

  meta = with lib; {
    homepage = "https://github.com/nbQA-dev/nbQA";
    description = "Run ruff, isort, pyupgrade, mypy, pylint, flake8, and more on Jupyter Notebooks";
    license = licenses.mit;
  };
}

