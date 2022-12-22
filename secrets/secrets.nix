let
  milan-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeCLpbqoSN3Pqd577PWCvJlFV8j7VsLTy++Bm5CDDM4";
  zeus-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjmqzCD+qRq9b2k0jIueEylQYLKD2E9k9Vo60kr4NQV";

  keys = [ milan-ssh zeus-ssh ];
in {
  "password_root.age".publicKeys = keys;
  "password_james.age".publicKeys = keys;
  "stata_licence.age".publicKeys = keys;
  "fastmail.age".publicKeys = keys;
}
