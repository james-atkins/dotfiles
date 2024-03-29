let
  athena-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRNxVS63eSd0mLphv+/zax+1cxnOXW7RoNLgCiV4Uf8";
  milan-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeCLpbqoSN3Pqd577PWCvJlFV8j7VsLTy++Bm5CDDM4";
  rome-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ69QL3WSungfZXf5YdJsqi2QfHmYICcmgnhcgkCdKjT";
  zeus-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjmqzCD+qRq9b2k0jIueEylQYLKD2E9k9Vo60kr4NQV";

  keys = [ athena-ssh milan-ssh rome-ssh zeus-ssh ];
in
{
  "password_root.age".publicKeys = keys;
  "password_james.age".publicKeys = keys;
  "stata16_licence.age".publicKeys = keys;
  "fastmail.age".publicKeys = keys;
  "fastmail_athena.age".publicKeys = [ athena-ssh ];
  "borg.age".publicKeys = keys;
  "borg_athena.age".publicKeys = keys;
  "cctv.age".publicKeys = keys;
  "cloudflare.age".publicKeys = [ zeus-ssh ];
  "miniflux.age".publicKeys = [ zeus-ssh ];
  "paperless.age".publicKeys = [ zeus-ssh ];
  "james_smb.age".publicKeys = [ milan-ssh ];
  "nextdns_bg.age".publicKeys = [ athena-ssh ];
  "nextdns_evanston.age".publicKeys = [ zeus-ssh ];
  "vikunja_jwt.age".publicKeys = [ zeus-ssh ];

  "nuzulip_econ_bot.age".publicKeys = [ zeus-ssh ];
}
