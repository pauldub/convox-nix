{ lib, k8s, config, pkgs, ...}:

with lib;

let
  convox-options = pkgs.callPackage ./options.nix {};
  mkDeployment = pkgs.callPackage ./mkDeployment.nix { k8s = k8s; };
in {
  config.kubernetes.moduleDefinitions.convox-service.prefixResources = true;
  config.kubernetes.moduleDefinitions.convox-service.module = { name, config, ... }: {
    imports = [];

    options = (convox-options.service {
      inherit name config;
    }).options;

    config =
      let
        name = config.name;
        labels = {
          system = "convox-nix";
          service = name;
        } // config.labels;
      in {
        kubernetes.resources.deployments.${name} = mkDeployment {
          inherit name labels config;
        };

        kubernetes.resources.services.${name} = {
          metadata.name = name;
          metadata.labels = labels;

          spec = {
            type = "ClusterIP";

            ports =
              genAttrs
              (map toString (toList config.port))
              (port: { targetPort = port; });

            selector = labels;
          };
        };

        kubernetes.resources.ingresses = mkIf (length config.domains > 0) {
          ${name} = {
            metadata.name = name;
            metadata.labels = labels;
            metadata.annotations = {
              "kubernetes.io/tls-acme" = "true";
            };

            spec = {
              tls = [
                {
                  secretName = "${name}-tls";
                  hosts = config.domains;
                }
              ];

              rules = map (domain: {
                host = domain;
                http.paths = [
                  {
                    path = "/";
                    backend.serviceName = name;
                    backend.servicePort = config.port;
                  }
                ];
              }) config.domains;
            };
          };
        };
      };
  };
}
