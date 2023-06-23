let
  athena-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRNxVS63eSd0mLphv+/zax+1cxnOXW7RoNLgCiV4Uf8";
  milan-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeCLpbqoSN3Pqd577PWCvJlFV8j7VsLTy++Bm5CDDM4";
  zeus-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjmqzCD+qRq9b2k0jIueEylQYLKD2E9k9Vo60kr4NQV";

  keys = [ athena-ssh milan-ssh zeus-ssh ];
in
{
  "password_root.age".publicKeys = keys;
  "password_james.age".publicKeys = keys;
  "stata16_licence.age".publicKeys = keys;
  "fastmail.age".publicKeys = keys;
  "borg.age".publicKeys = keys;
  "cloudflare.age".publicKeys = [ zeus-ssh ];
}
