{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.calagopus-panel;
in {
  options.services.calagopus-panel = {
    enable = lib.mkEnableOption "Calagopus Panel";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.panel;
      description = "The panel package to use. Override with pkgs.panel-nightly for nightly builds.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing secret environment variables. Must include APP_ENCRYPTION_KEY.";
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
    };

    appPrimary = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    appDebug = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    appLogDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    useDecryptionCache = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    useInternalCache = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    trustedProxies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    sentryUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    serverName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    database = {
      createLocally = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      migrate = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

    redis = {
      createLocally = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.appLogDirectory == null || lib.hasPrefix "/var/log/calagopus-panel" (toString cfg.appLogDirectory);
        message = "services.calagopus-panel.appLogDirectory must be under /var/log/calagopus-panel";
      }
    ];

    systemd.services.calagopus-panel = let
      generatedEnv = pkgs.writeText "calagopus-panel-env" ''
        BIND=${cfg.bind}
        PORT=${toString cfg.port}
        APP_PRIMARY=${if cfg.appPrimary then "true" else "false"}
        APP_DEBUG=${if cfg.appDebug then "true" else "false"}
        APP_USE_DECRYPTION_CACHE=${if cfg.useDecryptionCache then "true" else "false"}
        APP_USE_INTERNAL_CACHE=${if cfg.useInternalCache then "true" else "false"}
        DATABASE_MIGRATE=${if cfg.database.migrate then "true" else "false"}
        ${lib.optionalString cfg.database.createLocally "DATABASE_URL=postgresql:///calagopus-panel?host=/run/postgresql"}
        ${lib.optionalString (cfg.appLogDirectory != null) "APP_LOG_DIRECTORY=${toString cfg.appLogDirectory}"}
        ${lib.optionalString (cfg.trustedProxies != []) "APP_TRUSTED_PROXIES=${lib.concatStringsSep "," cfg.trustedProxies}"}
        ${lib.optionalString (cfg.sentryUrl != null) "SENTRY_URL=${cfg.sentryUrl}"}
        ${lib.optionalString (cfg.serverName != null) "SERVER_NAME=${cfg.serverName}"}
        ${lib.optionalString cfg.redis.createLocally
          "REDIS_URL=unix://${config.services.redis.servers.calagopus-panel.unixSocket}"}
      '';
    in {
      description = "Calagopus Panel";
      wantedBy = ["multi-user.target"];

      after = lib.optional cfg.database.createLocally "postgresql.service"
            ++ lib.optional cfg.redis.createLocally "redis-calagopus-panel.service";
      requires = lib.optional cfg.database.createLocally "postgresql.service"
               ++ lib.optional cfg.redis.createLocally "redis-calagopus-panel.service";

      startLimitBurst = 30;
      startLimitIntervalSec = 180;

      serviceConfig = {
        User = "calagopus-panel";
        DynamicUser = true;
        StateDirectory = "calagopus-panel";
        WorkingDirectory = "/var/lib/calagopus-panel";
        EnvironmentFile = [generatedEnv cfg.environmentFile];
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = "5s";
        LimitNOFILE = 65536;

        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        RestrictNamespaces = true;
        LockPersonality = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        SystemCallFilter = ["@system-service"];
        SystemCallErrorNumber = "EPERM";
      } // lib.optionalAttrs (cfg.appLogDirectory != null) {
        LogsDirectory = "calagopus-panel";
      };
    };

    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      ensureUsers = [{
        name = "calagopus-panel";
        ensureDBOwnership = true;
      }];
      ensureDatabases = ["calagopus-panel"];
    };

    services.redis.servers.calagopus-panel = lib.mkIf cfg.redis.createLocally {
      enable = true;
    };
  };
}
