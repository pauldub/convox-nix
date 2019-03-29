{ lib, k8s, config, pkgs, ...}:

with lib;

{ name, labels, config, ... }: let
  buildEnvVar = var: if (strings.hasInfix "=" var)
  then let parts = splitString "=" var; in {
    name = head parts;
    value = toString (tail parts);
  } else {
    name = var;
    valueFrom.secretKeyRef = {
      name = config.environmentSecret; key = var;
    };
  };
  buildEnvVars = vars: (map buildEnvVar vars);
in {
  metadata.name = name;
  metadata.labels = labels;

  spec = {
    replicas = config.scale.count;
    selector.matchLabels = labels;

    template = {
      metadata.name = name;
      metadata.labels = labels;

      spec.containers."${name}" = {
        image = mkIf (config.image != null) config.image;
        command = mkIf (config.command != null) config.command;
        ports =
          map
          (port: { containerPort = port; })
          (toList config.port);
        resources = {
          requests = {
            memory = mkIf (config.scale.memory != null)
            "${toString config.scale.memory}Mi";
            cpu = mkIf (config.scale.cpu != null)
            "${toString config.scale.cpu}m";
          };
        };

        readinessProbe.httpGet = mkIf (config.health != null) {
          path = if isString config.health
          then config.health
          else config.health.path;
          port = config.port;
        };

        livenessProbe.httpGet = mkIf (config.health != null) {
          path = if isString config.health
          then config.health
          else config.health.path;
          port = config.port;
        };

        env = (buildEnvVars config.environment);
      };
    };
  };
}
