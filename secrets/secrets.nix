let
  james-age = "age1r207lntm00wmdv8cwuj8sun0rt0xcjqqz2hcphke8r3aaa789fvszfu2zs";
  milan-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJciYDocjD+D/injAAs7mVIXuQ1tNLIFtQ8plSh5wGVX";
  zeus-ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjmqzCD+qRq9b2k0jIueEylQYLKD2E9k9Vo60kr4NQV";

  keys = [ james-age milan-ssh zeus-ssh ];
in {
  "password_root.age".publicKeys = keys;
  "password_james.age".publicKeys = keys;
  "stata_licence.age".publicKeys = keys;
}
