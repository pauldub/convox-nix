{ lib, k8s, config, pkgs, ...}:

with lib;

let
  convox-options = pkgs.callPackage ./options.nix {};
  kaniko-builder = pkgs.callPackage ./kaniko-builder.nix {
    inherit k8s lib pkgs;
  };
in {
  config.kubernetes.moduleDefinitions.convox.module = { name, config, module, ... }: {
    imports = [];

    options = convox-options.manifest.options;

    config = let
      appName = name;
      services = mapAttrs (
        name: attrs: {
          module = "convox-service";

          configuration = attrs // {
            labels = {
              app = appName;
            };


            environmentSecret = appName;
            environment = config.environment ++ attrs.environment ++ [
              "VERSION=${config.version}"
            ];
          };
        }
      ) config.services;

      timers = mapAttrs (
        name: attrs: {
          module = "convox-timer";

          configuration = attrs // {
            labels = {
              app = appName;
            };

            serviceOpts = config.services.${attrs.service} // {
              environment = config.environment ++ [
                "VERSION=${config.version}"
              ];

              environmentSecret = appName;
            };
          };
        }
      ) config.timers;
    in (mkMerge [
      # (kaniko-builder { namespace = module.namespace; })
      {
        kubernetes.modules = services // timers;
      }
    ]);
  };
}
