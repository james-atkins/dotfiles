let
  james-age = "age1r207lntm00wmdv8cwuj8sun0rt0xcjqqz2hcphke8r3aaa789fvszfu2zs";
in {
  "password_root.age".publicKeys = [ james-age ];
  "password_james.age".publicKeys = [ james-age ];
}
