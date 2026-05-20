{ ... }:
{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    validateSopsFiles = false;
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";
  };
}
