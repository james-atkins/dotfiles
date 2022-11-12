{ ... }:

{
  users.users = {
    james = {
      isNormalUser = true;
      uid = 1000;
      home = "/home/james";
      description = "James Atkins";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBF2zwPXy8sRqpsHOTs0krU7RtGO0cSg5EDaGj4LOJ6/nL7wtOM8q/yxUpndMOKJFIKll9Bna4GS7Ft9UFEgmi3AAAAAEc3NoOg== Yubikey 5"
      ];
    };
  };
}

