{ config, lib, ... }: {
  options.my.core = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "alunity";
      description = "The primary username for the system.";
    };
  };
}
