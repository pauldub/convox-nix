{ lib, k8s, config, pkgs, ...}:

with lib;
let
  convox-options = pkgs.callPackage ./options.nix {};
  mkDeployment = pkgs.callPackage ./mkDeployment.nix { k8s = k8s; };
in {
  config.kubernetes.moduleDefinitions.convox-timer.module = { name, config, ... }: {
    imports = [];
    options = (convox-options.timer { inherit name config; }).options;

    config =
      let
        name = config.name;
        labels = {
          system = "convox-nix";
          timer = name;
        } // config.labels;
      in {
        kubernetes.resources.cronJobs.${name} = {
          metadata.name = name;
          metadata.labels = labels;

          spec = {
            schedule = config.schedule;

            jobTemplate.spec.template = {
              metadata.labels = labels;

              spec.restartPolicy = "Never";
              spec.serviceAccountName = mkIf (config.serviceOpts.serviceAccount != null) config.serviceOpts.serviceAccount;
              spec.containers.${name} = (mkDeployment {
                name = config.service;
                config = config.serviceOpts;
                labels = labels;
              }).spec.template.spec.containers.${config.service} // {
                command = mkIf (config.command != null) config.command;
                ports = [];
                readinessProbe = null;
                livenessProbe = null;
              };
            };
          };
        };
      };
  };
}
