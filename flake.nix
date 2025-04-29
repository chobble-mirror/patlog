{
  description = "PAT Inspection Logger - patlog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ruby_3_4
            rubyPackages_3_4.railties
            rubyPackages_3_4.ruby-vips
            sqlite
            nodejs
            imagemagick
          ];

          shellHook = ''
            echo "Ruby $(ruby --version) with Rails $(rails --version)"
          '';
        };

        packages = {
          default = pkgs.buildEnv {
            name = "patlog-env";
            paths = with pkgs; [
              ruby_3_4
              rubyPackages_3_4.railties
              rubyPackages_3_4.ruby-vips
              sqlite
              nodejs
              imagemagick
            ];
          };
        };
      }
    ))
    // {
      nixosModules.default =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          cfg = config.services.patlog;
          makeBaseServiceConfig = name: {
            User = "patlog-${name}";
            Group = "patlog-${name}";
            StandardOutput = "journal";
            StandardError = "journal";

            # Security settings
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            PrivateUsers = true;
            ProtectClock = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = [
              "AF_UNIX"
              "AF_INET"
              "AF_INET6"
              "AF_NETLINK"
            ];
            RestrictNamespaces = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = false;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            RemoveIPC = true;
            PrivateMounts = true;
          };

          instanceOpts =
            { name, config, ... }:
            {
              options = {
                enable = lib.mkEnableOption "Patlog instance ${name}";
                port = lib.mkOption {
                  type = lib.types.port;
                  default = 3000;
                  description = "Port on which the Rails server will listen";
                };
                environment = lib.mkOption {
                  type = lib.types.attrs;
                  default = { };
                  description = "Environment variables for this instance";
                };
              };
            };

          defaultEnvironment = {
            RAILS_ENV = "production";
            RAILS_LOG_TO_STDOUT = "1";
            RAILS_SERVE_STATIC_FILES = "1";
            SECRET_KEY_BASE = "secret_key_base";
          };

          makeSetupScript =
            name:
            pkgs.writeShellScriptBin "patlog-setup" ''
              set -e
              set -x

              rm -rf "/run/patlog-${name}"
              mkdir "/run/patlog-${name}"

              # copy repo
              cp -r "${./.}/." "/run/patlog-${name}"

              # asset builds
              rm -rf "/run/patlog-${name}/app/assets/builds"
              mkdir -p "/var/lib/patlog-${name}/app/assets/builds"
              mkdir -p "/run/patlog-${name}/app/assets"
              ln -s "/var/lib/patlog-${name}/app/assets/builds" "/run/patlog-${name}/app/assets/builds"

              # clear storage
              rm -rf "/run/patlog-${name}/storage"
              mkdir -p "/var/lib/patlog-${name}/storage"
              ln -s "/var/lib/patlog-${name}/storage" "/run/patlog-${name}/storage"

              # clear log
              rm -rf "/run/patlog-${name}/log"
              mkdir -p "/var/lib/patlog-${name}/log"
              ln -s "/var/lib/patlog-${name}/log" "/run/patlog-${name}/log"

              # clear tmp
              rm -rf "/run/patlog-${name}/tmp"
              mkdir -p "/var/lib/patlog-${name}/tmp"
              ln -s "/var/lib/patlog-${name}/tmp" "/run/patlog-${name}/tmp"

              # link env
              rm -f "/run/patlog-${name}/.env"
              ln -s "/var/lib/patlog-${name}/.env" "/run/patlog-${name}/.env"

              chown -R patlog-${name}:patlog-${name} /var/lib/patlog-${name}
            '';
        in
        {
          options.services.patlog = {
            instances = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule instanceOpts);
              default = { };
              description = "Patlog service instances";
            };
          };

          config = lib.mkIf (cfg.instances != { }) {
            systemd.services = lib.mkMerge [
              # Main services
              (lib.mapAttrs' (
                name: instanceCfg:
                lib.nameValuePair "patlog-${name}" {
                  description = "patlog instance ${name}";
                  environment = defaultEnvironment // instanceCfg.environment;
                  enable = instanceCfg.enable;
                  wantedBy = [ "multi-user.target" ];
                  after = [ "patlog-${name}-setup.service" ];
                  requires = [ "patlog-${name}-setup.service" ];
                  serviceConfig = makeBaseServiceConfig name // {
                    Type = "simple";
                    CacheDirectory = "patlog-${name}";
                    RuntimeDirectory = "patlog-${name}";
                    StateDirectory = "patlog-${name}";
                    WorkingDirectory = "/run/patlog-${name}";
                    ExecStart = "+${pkgs.ruby_3_4}/bin/bundle exec rails server -p ${toString instanceCfg.port}";
                  };
                }
              ) cfg.instances)

              # Setup services
              (lib.mapAttrs' (
                name: instanceCfg:
                lib.nameValuePair "patlog-${name}-setup" {
                  description = "Setup for patlog-${name}";
                  environment = defaultEnvironment // instanceCfg.environment;
                  after = [ "users.target" ];
                  before = [ "patlog-${name}.service" ];
                  requiredBy = [ "patlog-${name}.service" ];
                  serviceConfig = makeBaseServiceConfig name // {
                    Type = "oneshot";
                    ExecStart = "+${makeSetupScript name}/bin/patlog-setup";
                  };
                }
              ) cfg.instances)

              # Migration services
              (lib.mapAttrs' (
                name: instanceCfg:
                lib.nameValuePair "patlog-${name}-migrate" {
                  description = "Database migrations for patlog-${name}";
                  environment = defaultEnvironment // instanceCfg.environment;
                  after = [ "patlog-${name}-setup.service" ];
                  requires = [ "patlog-${name}-setup.service" ];
                  before = [ "patlog-${name}.service" ];
                  requiredBy = [ "patlog-${name}.service" ];
                  serviceConfig = makeBaseServiceConfig name // {
                    Type = "oneshot";
                    WorkingDirectory = "/run/patlog-${name}";
                    ExecStart = "+${pkgs.ruby_3_4}/bin/bundle exec rails db:migrate";
                  };
                }
              ) cfg.instances)
            ];

            users.users = lib.mapAttrs' (
              name: instanceCfg:
              lib.nameValuePair "patlog-${name}" {
                isSystemUser = true;
                group = "patlog-${name}";
              }
            ) cfg.instances;

            users.groups = lib.mapAttrs' (
              name: instanceCfg: lib.nameValuePair "patlog-${name}" { }
            ) cfg.instances;
          };
        };
    };
}
