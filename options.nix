{ lib, config, pkgs, ...}:

with lib;

rec {
  service = {config, name, ...}: {
    options = {
      name = mkOption {
        description = "Module name";
        type = types.str;
        default = name;
      };

      labels = mkOption {
        description = "Attribute set of module lables";
        type = types.attrsOf types.str;
        default = {};
      };

      image = mkOption {
        description = "Image of the service";
        type = types.nullOr types.str;
        default = null;
      };

      command = mkOption {
        description = "Command to start the service";
        type = types.nullOr (types.listOf types.str);
        default = null;
      };

      domains = mkOption {
        description = "Domains the app should be accessible from";
        default = [];
        type = types.listOf types.str;
      };

      port = mkOption {
        description = "Port the service listens on";
        type = types.nullOr (types.attrsOf types.ints.u16);
      };

      health = mkOption {
        description = "Healthcheck URL of the service";
        default = null;
        type = types.nullOr (
          types.either types.string (types.submodule healthCheck)
        );
      };

      scale = mkOption {
        description = "Scaling configuration of the service.";
        type = types.submodule scale;
      };

      environment = mkOption {
        description = "Required environment variables";
        type = types.listOf types.string;
        default = [];
      };

      environmentSecret = mkOption {
        description = "Secret which holds environment variables";
        default = name;
        type = types.string;
      };

      serviceAccount = mkOption {
        description = "Service account used by the service deployment";
        default = null;
        type = types.nullOr types.string;
      };
    };
  };

  healthCheck = {
    options = {
      path = mkOption {
        description = "Path of to use for health checking";
        default = "/";
        type = types.string;
      };
    };
  };

  scale = {
    options = {
      count = mkOption {
        description = "Number of replicas of the service";
        default = 1;
        type = types.int;
      };

      cpu = mkOption {
        description = "Quantity of CPU shares requested by the servicee";
        default = null;
        type = types.nullOr types.int;
      };

      memory = mkOption {
        description = "Quantity of memory requested by the service in mb";
        default = null;
        type = types.nullOr types.int;
      };
    };
  };

  timer = {config, name, ...}: {
    options = {
      name = mkOption {
        description = "Module name";
        type = types.str;
        default = name;
      };

      labels = mkOption {
        description = "Attribute set of module lables";
        type = types.attrsOf types.str;
        default = {};
      };

      schedule = mkOption {
        description = "Schedule of the timer in crontab format";
        type = types.str;
      };

      command = mkOption {
        description = "Command to run";
        type = types.nullOr (types.listOf types.str);
      };

      service = mkOption {
        description = "Service to run the command in";
        type = types.str;
      };

      serviceOpts = mkOption {
        description = "Service to run the command in";
        type = types.nullOr (types.submodule service);
        default = null;
      };
    };
  };

  manifest = {
    options = {
      environment = mkOption {
        description = "Common environment variables";
        type = types.listOf types.string;
        default = [];
      };

      services = mkOption {
        description = "Services";
        type = types.attrsOf (types.submodule service);
      };

      timers = mkOption {
        description = "Timers";
        type = types.attrsOf (types.submodule timer);
        default = {};
      };
    };
  };
}
