{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.tailscaleHosts;

  updateTailscaleHosts = pkgs.writeShellApplication {
    name = "update-tailscale-hosts";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.tailscale
    ];
    text = ''
      set -euo pipefail

      DEBUG=${if cfg.debug then "true" else "false"}
      BASE_HOSTS="/etc/static/hosts"
      FINAL_HOSTS="/etc/hosts"
      SUFFIX='${cfg.suffix}'
      SELF_HOST='${config.networking.hostName}${cfg.suffix}'
      USERS_JSON='${builtins.toJSON cfg.users}'
      TAGS_JSON='${builtins.toJSON (map (tag: "tag:${tag}") cfg.tags)}'

      STATUS_JSON="$(mktemp)"
      TMP_USERS="$(mktemp)"
      TMP_TAGS="$(mktemp)"
      TMP_FINAL="$(mktemp)"

      debug() {
        if [ "$DEBUG" = "true" ]; then
          printf 'DEBUG: %s\n' "$1" >&2
        fi
      }

      cleanup() {
        rm -f "$TMP_USERS" "$TMP_TAGS" "$TMP_FINAL"
        if [ "$DEBUG" = "false" ]; then
          rm -f "$STATUS_JSON"
        fi
      }

      wait_for_tailscale() {
        for i in $(seq 1 20); do
          if tailscale ip --4 >/dev/null 2>&1; then
            debug "Tailscale is ready"
            return 0
          fi
          debug "Waiting for Tailscale... ($i/20)"
          sleep 1
        done

        printf 'ERROR: Tailscale not ready after 20 attempts\n' >&2
        exit 1
      }

      fetch_tailscale_status() {
        if ! tailscale status --json > "$STATUS_JSON" 2>/dev/null; then
          printf 'ERROR: Failed to fetch Tailscale status\n' >&2
          exit 1
        fi

        if [ ! -s "$STATUS_JSON" ]; then
          printf 'ERROR: Tailscale status JSON is empty\n' >&2
          exit 1
        fi

        debug "Raw JSON saved to $STATUS_JSON"
      }

      filter_by_users() {
        if [ "$USERS_JSON" = "[]" ]; then
          : > "$TMP_USERS"
          return
        fi

        jq -r --argjson selectedUsers "$USERS_JSON" --arg suffix "$SUFFIX" '
          .User as $userMap
          | .Peer
          | to_entries[]
          | .value as $peer
          | ($userMap[($peer.UserID | tostring)].LoginName // empty) as $login
          | select($selectedUsers | index($login))
          | select(($peer.TailscaleIPs // []) | length > 0)
          | "\($peer.TailscaleIPs[0]) \($peer.HostName)\($suffix)"
        ' "$STATUS_JSON" > "$TMP_USERS"

        debug "Users filter generated $(wc -l < "$TMP_USERS") hosts"
      }

      filter_by_tags() {
        if [ "$TAGS_JSON" = "[]" ]; then
          : > "$TMP_TAGS"
          return
        fi

        jq -r --argjson selectedTags "$TAGS_JSON" --arg suffix "$SUFFIX" '
          .Peer
          | to_entries[]
          | .value as $peer
          | select(($peer.Tags // []) | any(. as $tag | $selectedTags | index($tag)))
          | select(($peer.TailscaleIPs // []) | length > 0)
          | "\($peer.TailscaleIPs[0]) \($peer.HostName)\($suffix)"
        ' "$STATUS_JSON" > "$TMP_TAGS"

        debug "Tags filter generated $(wc -l < "$TMP_TAGS") hosts"
      }

      combine_results() {
        if [ ! -s "$TMP_USERS" ] && [ ! -s "$TMP_TAGS" ]; then
          jq -r --arg suffix "$SUFFIX" '
            .Peer
            | to_entries[]
            | .value as $peer
            | select(($peer.TailscaleIPs // []) | length > 0)
            | "\($peer.TailscaleIPs[0]) \($peer.HostName)\($suffix)"
          ' "$STATUS_JSON" | sort -u > "$TMP_FINAL"
        elif [ ! -s "$TMP_USERS" ]; then
          sort -u "$TMP_TAGS" > "$TMP_FINAL"
        elif [ ! -s "$TMP_TAGS" ]; then
          sort -u "$TMP_USERS" > "$TMP_FINAL"
        else
          comm -12 <(sort -u "$TMP_USERS") <(sort -u "$TMP_TAGS") > "$TMP_FINAL"
        fi

        debug "Combined result has $(wc -l < "$TMP_FINAL") hosts"
      }

      update_hosts_file() {
        local selfIp
        selfIp=""
        while IFS= read -r line; do
          selfIp="$line"
          break
        done < <(tailscale ip --4 2>/dev/null || true)

        if [ -z "$selfIp" ]; then
          printf 'ERROR: No Tailscale IP available, cannot update hosts\n' >&2
          exit 1
        fi

        {
          printf '# Hosts managed by NixOS configuration\n'
          cat "$BASE_HOSTS"
          printf '# Tailscale hosts\n'
          printf '%s %s # Local Tailscale host\n' "$selfIp" "$SELF_HOST"
          if [ -s "$TMP_FINAL" ]; then
            cat "$TMP_FINAL"
          fi
        } > "$FINAL_HOSTS.tmp"

        mv "$FINAL_HOSTS.tmp" "$FINAL_HOSTS"
        chmod 0644 "$FINAL_HOSTS"
        debug "Updated $FINAL_HOSTS"
      }

      trap cleanup EXIT
      wait_for_tailscale
      fetch_tailscale_status
      filter_by_users
      filter_by_tags
      combine_results
      update_hosts_file
    '';
  };

in
{
  options.tailscaleHosts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to manage /etc/hosts with Tailscale peers.";
    };

    users = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "List of Tailscale users to include in /etc/hosts. If empty and tags is empty, all hosts are included.";
    };

    tags = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
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

  config = lib.mkIf cfg.enable {
    systemd.timers.tailscale-hosts = {
      description = "Timer for updating Tailscale hosts";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.timerInterval;
        Persistent = true;
      };
    };

    systemd.services =
      {
        tailscale-hosts = {
          enable = true;
          description = "Update /etc/hosts with Tailscale nodes";
          after = [
            "tailscaled.service"
            "network-online.target"
          ];
          wants = [
            "tailscaled.service"
            "network-online.target"
          ];
          wantedBy = [ "multi-user.target" ];
          unitConfig = {
            StartLimitIntervalSec = "300";
            StartLimitBurst = "5";
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${updateTailscaleHosts}/bin/update-tailscale-hosts";
            TimeoutStopSec = "5s";
          };
        };
      }
      // (lib.optionalAttrs config.virtualisation.incus.enable {
        incus = {
          after = [
            "tailscaled.service"
            "tailscale-hosts.service"
          ];
          requires = [
            "tailscaled.service"
            "tailscale-hosts.service"
          ];
          serviceConfig = {
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 15";
          };
        };
      });
  };
}
