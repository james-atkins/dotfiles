# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, pkgs-local, global, ... }:

{
  imports = [
    ./private-services.nix
    ./cran.nix
    ./miniflux.nix
    ./paperless.nix
    ./photoprism.nix
    ./vikunja.nix
    ./zrepl.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/enc/root@blank
  '';
  boot.zfs.extraPools = [ "tank" ];

  boot.supportedFilesystems = [ "zfs" ];

  # Remote unlock over tailscale
  boot.initrd = {
    kernelModules = [ "e1000e" "igb" "tun" ];
    extraUtilsCommands = ''
      for BIN in ${pkgs.iproute2}/{s,}bin/*; do
        copy_bin_and_libs $BIN
      done

      for BIN in ${pkgs.iptables-legacy}/{s,}bin/*; do
        copy_bin_and_libs $BIN
      done

      copy_bin_and_libs ${config.services.tailscale.package}/bin/.tailscale-wrapped
      copy_bin_and_libs ${config.services.tailscale.package}/bin/.tailscaled-wrapped

      mkdir -p $out/secrets/etc/ssl/certs
      cp ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/secrets/etc/ssl/certs/ca-bundle.crt
    '';
    secrets = {
      "/etc/tailscale.secret" = "/persist/etc/tailscale.secret";
    };
    network.enable = true;
    network.ssh.enable = true;
    network.ssh.hostKeys = [
      "/persist/etc/secrets/initrd/ssh_host_rsa_key"
      "/persist/etc/secrets/initrd/ssh_host_ed25519_key"
    ];
    network.ssh.authorizedKeys = config.users.users.james.openssh.authorizedKeys.keys;
    network.postCommands = lib.mkBefore ''
      mkdir -p /var/lib/tailscale
      nohup /bin/.tailscaled-wrapped -verbose=1 -state=/var/lib/tailscale/tailscaled.state -no-logs-no-support -socket ./tailscaled.socket &
      /bin/.tailscale-wrapped --socket=./tailscaled.socket up --hostname=zeus-boot --auth-key=file:/etc/tailscale.secret

      echo "zpool import tank; zfs load-key -a; killall zfs; exit" >> /root/.profile
    '';
    postMountCommands = ''
      /bin/.tailscale-wrapped logout
    '';
  };

  time.timeZone = "America/Chicago";

  networking = {
    hostId = "508fcc6d";
    useNetworkd = true;
    useDHCP = false;
    interfaces.eno1.useDHCP = true;
  };

  users.groups.photos.members = [
    config.users.users.james.name
    config.users.users.syncthing.name
  ];

  services.tailscale.useRoutingFeatures = "server";

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver intel-compute-runtime ];
  };

  services.openssh.enable = true;

  ja.services.syncthing = {
    enable = true;
    tailscaleReverseProxy = true;
  };

  ja.backups = {
    enable = true;
    paths = [ "/tank" ];
    zfs_snapshots = [ "rpool/enc/home" "tank" ];
    extra_repositories = [ "ssh://borg@athena.${global.tailscaleDomain}/./" ];
  };

  environment.etc."aliases".text = ''
    root: zeus@jamesatkins.net
  '';

  age.secrets.fastmail.file = ../../secrets/fastmail.age;
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      auth = true;
      aliases = "/etc/aliases";
      tls = true;
      tls_starttls = false;
      port = 465;
    };
    accounts.default = {
      host = "smtp.fastmail.com";
      user = with lib; concatStrings (
        reverseList [ "s" "e" "m" "a" "j" ] ++
        reverseList [ "s" "n" "i" "k" "t" "a" ] ++
        singleton "@" ++
        reverseList [ "l" "i" "a" "m" "t" "s" "a" "f" ] ++
        singleton "." ++
        reverseList [ "k" "u" "." "o" "c" ]
      );
      passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.fastmail.path}";
      from = "${config.networking.hostName}@jamesatkins.net";
    };
  };

  services.zfs.autoScrub.enable = true;
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";
    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;
  };

  virtualisation.containers.storage.settings.storage = {
    driver = "zfs";
    graphroot = "/persist/var/lib/containers/storage";
    runroot = "/run/containers/storage";
  };

  ja.persistence.directories = [ "/var/lib/acme" ];
  age.secrets.cloudflare.file = ../../secrets/cloudflare.age;
  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults = {
      dnsResolver = "1.1.1.1:53";
      email = global.email;
      reloadServices = [ "caddy" ];
    };

    certs."jamesatkins.io" = {
      domain = "jamesatkins.io";
      extraDomainNames = [ "*.jamesatkins.io" ];
      dnsProvider = "cloudflare";
      credentialsFile = config.age.secrets.cloudflare.path;
    };
  };

  users.users.caddy.extraGroups = [ "acme" ];

  # Allow Caddy to get HTTPS certificates from tailscale
  services.tailscale.permitCertUid = config.services.caddy.user;

  services.smartd = {
    enable = true;
    notifications.mail = {
      enable = true;
      mailer = "${pkgs.msmtp}/bin/msmtp";
    };
    # Short self-test every day between 1-2am, and an extended self test weekly on Mondays between 2-3am:
    # Ignore tracking of normalised temperature attributes - instead log temperatures of 40 degrees
    # or higher, and warn on temperatures of 45 degrees or higher.
    defaults.autodetected = "-a  -s (S/../.././01|L/../../1/02) -I 194 -W 0,40,45";
    devices = [
      # Special settings for the NVME SSD
      # Don't use -a because that implies -l error which yields lots of error log entries
      # Warn on higher temperatures than the HDDs
      { device = "/dev/nvme0"; options = "-H -f -t -l selftest -s (S/../.././01|L/../../1/02) -W 0,60,70"; }
    ];
  };

  services.mysql.package = pkgs.mariadb_1011;

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.jellyfin.persist.state = true;
  systemd.services.jellyfin.persist.cache = true;

  ja.private-services.jellyfin.caddy-config = ''
    reverse_proxy http://127.0.0.1:8096
  '';

  services.changedetection-io = {
    enable = true;
    baseURL = "https://changedetection.jamesatkins.io/";
    port = 65500;
  };
  systemd.services.changedetection-io = {
    # Restart daily to mitigate a playwright memory leak
    # https://github.com/dgtlmoon/changedetection.io/wiki/Playwright-content-fetcher#playwright-memory-leak
    serviceConfig.RuntimeMaxSec = "1d";
    persist.state = true;
  };

  ja.private-services.changedetection.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.services.changedetection-io.port} {
      header_up Host localhost
    }
  '';

  services.gollum = {
    enable = true;
    mathjax = true;
    stateDir = "/persist/var/lib/gollum";
    address = "127.0.0.1";
    port = 65501;
    extraConfig = ''
      module Precious
        class App
          private

          def commit_message
            return commit_options
          end

          def commit_options
            name = request.env['HTTP_TAILSCALE_NAME']
            email = request.env['HTTP_TAILSCALE_USER']

            msg = (params[:message].nil? or params[:message].empty?) ? "[no message]" : params[:message]

            commit_message = {
              message: msg,
              name: name,
              email: email
            }

            return commit_message
          end
        end
      end
    '';
  };

  ja.private-services.wiki.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.services.gollum.port} {
      header_up Host localhost
    }
  '';

  ja.services.fossil = {
    enable = true;
    base-url = "https://fossil.jamesatkins.io";
    museum = "/tank/fossil";
    package = pkgs-local.fossil-tailscale;
    local-auth = true;
    localhost = true;
  };
  ja.private-services.fossil.caddy-config = ''
    reverse_proxy http://127.0.0.1:${toString config.ja.services.fossil.port}
  '';

  nuzulip.enable = true;

  age.secrets.nuzulip-calendar-bot.file = ../../secrets/nuzulip_calendar_bot.age;
  nuzulip.zuliprc.calendar-bot = config.age.secrets.nuzulip-calendar-bot.path;

  age.secrets.nuzulip-econ-bot.file = ../../secrets/nuzulip_econ_bot.age;
  nuzulip.zuliprc.welcome-bot = config.age.secrets.nuzulip-econ-bot.path;
  nuzulip.zuliprc.working-papers-bot = config.age.secrets.nuzulip-econ-bot.path;

  home-manager.users.james.home.stateVersion = "22.11";
  system.stateVersion = "22.11"; # Did you read the comment?
}
