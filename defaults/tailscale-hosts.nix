{ config, pkgs, lib, ... }:

let
  cfg = config.tailscaleHosts;

  updateTailscaleHosts = pkgs.writeShellScript "update-tailscale-hosts" ''
    set -e

    # Configuration variables
    DEBUG=${if cfg.debug then "true" else "false"}
    BASE_HOSTS="/etc/static/hosts"
    FINAL_HOSTS="/etc/hosts"
    JSON_TMP="/tmp/tailscale-status-$(date +%s).json"

    # Temporary files
    TMP_USERS=$(mktemp)
    TMP_TAGS=$(mktemp)
    TMP_FINAL=$(mktemp)

    # Utility functions
    debug() {
      if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: $1"
      fi
    }

    cleanup() {
      rm -f "$TMP_USERS" "$TMP_TAGS" "$TMP_FINAL"
      [ "$DEBUG" = "false" ] && rm -f "$JSON_TMP"
    }

    wait_for_tailscale() {
      for i in {1..20}; do
        ${pkgs.tailscale}/bin/tailscale ip && return 0
        debug "Waiting for Tailscale... ($i/20)"
        sleep 1
      done
      echo "ERROR: Tailscale not ready after 20 attempts"
      exit 1
    }

    fetch_tailscale_status() {
      ${pkgs.tailscale}/bin/tailscale status --self=false --json > "$JSON_TMP" 2>/dev/null
      debug "Raw JSON saved to $JSON_TMP"
    }

    filter_by_users() {
      ${if builtins.length cfg.users == 0 then "echo '' > \"$TMP_USERS\"" else ''
        ${pkgs.jq}/bin/jq -r '
          .User as $users |
          .Peer | to_entries[] |
          select(.value.UserID as $uid | $users[$uid | tostring].LoginName | IN(${builtins.concatStringsSep "," (map (x: "\"${x}\"") cfg.users)})) |
          "\(.value.TailscaleIPs[0]) \(.value.HostName)${cfg.suffix}"
        ' "$JSON_TMP" > "$TMP_USERS" || {
          echo "ERROR: jq failed to filter users"
          cat "$JSON_TMP"
          exit 1
        }
        debug "Users filter applied: $(cat "$TMP_USERS")"
      ''}
    }

    filter_by_tags() {
      ${if builtins.length cfg.tags == 0 then "echo '' > \"$TMP_TAGS\"" else ''
        ${pkgs.jq}/bin/jq -r '
          .Peer | to_entries[] |
          select(.value.Tags // [] | any(IN(${builtins.concatStringsSep "," (map (x: "\"tag:${x}\"") cfg.tags)}))) |
          "\(.value.TailscaleIPs[0]) \(.value.HostName)${cfg.suffix}"
        ' "$JSON_TMP" > "$TMP_TAGS" || {
          echo "ERROR: jq failed to filter tags"
          cat "$JSON_TMP"
          exit 1
        }
        debug "Tags filter applied: $(cat "$TMP_TAGS")"
      ''}
    }

    combine_results() {
      if [ -z "$(cat "$TMP_USERS")" ] && [ -z "$(cat "$TMP_TAGS")" ]; then
        ${pkgs.jq}/bin/jq -r '
          .Peer | to_entries[] |
          "\(.value.TailscaleIPs[0]) \(.value.HostName)${cfg.suffix}"
        ' "$JSON_TMP" > "$TMP_FINAL" || {
          echo "ERROR: jq failed to process all peers"
          cat "$JSON_TMP"
          exit 1
        }
      elif [ -z "$(cat "$TMP_USERS")" ]; then
        cat "$TMP_TAGS" > "$TMP_FINAL"
      elif [ -z "$(cat "$TMP_TAGS")" ]; then
        cat "$TMP_USERS" > "$TMP_FINAL"
      else
        comm -12 <(sort "$TMP_USERS") <(sort "$TMP_TAGS") > "$TMP_FINAL"
      fi
      debug "Combined results: $(cat "$TMP_FINAL")"
    }

    update_hosts_file() {
      if [ -s "$TMP_FINAL" ]; then
        {
          echo "# Hosts managed by NixOS configuration"
          cat "$BASE_HOSTS"
          echo "# Tailscale hosts"
          cat "$TMP_FINAL"
        } > "$FINAL_HOSTS.tmp"
        mv "$FINAL_HOSTS.tmp" "$FINAL_HOSTS"
        chmod 644 "$FINAL_HOSTS"
        debug "Updated $FINAL_HOSTS with Tailscale entries"
      else
        debug "No Tailscale entries found, skipping update"
      fi
    }

    # Main execution
    trap cleanup EXIT
    find /tmp -name "tailscale-status-*.json" -type f -mmin +60 -exec rm -f {} \;
    debug "Cleaned up old JSON files"
    wait_for_tailscale
    fetch_tailscale_status
    filter_by_users
    filter_by_tags
    combine_results
    update_hosts_file
  '';

in {
  options.tailscaleHosts = {
    users = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "List of Tailscale users to include in /etc/hosts. If empty and tags is empty, all hosts are included.";
    };

    tags = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "List of Tailscale tags to include in /etc/hosts. Combined with users using AND logic if both are specified.";
    };

    suffix = lib.mkOption {
      type = with lib.types; strMatching "\\..*";
      default = ".ts";
      description = "Suffix for hostnames in /etc/hosts (must start with a dot, e.g., '.ts').";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable debug output and retain the last JSON file.";
    };

    timerInterval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      description = ''
        Systemd timer interval for updating Tailscale hosts. Uses systemd OnCalendar syntax (e.g., "*:0/5" for every 5 minutes, "hourly", "daily"). See systemd.time(7) for details.
      '';
      example = "hourly";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.tailscale pkgs.jq ];

    systemd.services.tailscale-hosts = {
      enable = true;
      description = "Update /etc/hosts with Tailscale nodes";
      after = [ "tailscaled.service" "network-online.target" ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${updateTailscaleHosts}";
      };
    };

    systemd.timers.tailscale-hosts = {
      description = "Timer for updating Tailscale hosts";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.timerInterval;
        Persistent = true;
      };
    };
  };
}