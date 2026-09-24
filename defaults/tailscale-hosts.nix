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
      CACHE_ENABLED=${if cfg.bootCache then "true" else "false"}
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

      # Returns 0 once tailscaled answers, 1 after $1 seconds. Callers decide
      # what a timeout means (cache fallback vs. hard error) — the old version
      # exited hard after 20s, which on cold boot turned into a systemd
      # start-limit and took incus down with it (han-inc02, 2026-09-24).
      wait_for_tailscale() {
        local attempts="$1"
        for i in $(seq 1 "$attempts"); do
          if tailscale ip --4 >/dev/null 2>&1; then
            debug "Tailscale is ready"
            return 0
          fi
          debug "Waiting for Tailscale... ($i/$attempts)"
          sleep 1
        done
        return 1
      }

      # Last known good ".ts" section (self line + peers). Rendering it at
      # boot BEFORE tailscaled has network turns "name does not resolve"
      # (fatal, crash-loops incusd/containers into systemd limits) into
      # "host briefly unreachable" (transient, every consumer retries).
      # Tailnet IPs are pinned in Headscale, and the 5-minute timer plus the
      # next live run repair any drift.
      CACHE_FILE="/var/lib/tailscale-hosts/peers"

      render_from_cache() {
        {
          printf '# Hosts managed by NixOS configuration\n'
          cat "$BASE_HOSTS"
          printf '# Tailscale hosts (cached, tailscaled not ready yet)\n'
          cat "$CACHE_FILE"
        } > "$FINAL_HOSTS.tmp"
        mv "$FINAL_HOSTS.tmp" "$FINAL_HOSTS"
        chmod 0644 "$FINAL_HOSTS"
        debug "Rendered $FINAL_HOSTS from cache"
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

        # Refresh the boot cache only after a fully successful live run —
        # atomically, so a crash never leaves a truncated cache behind.
        if [ "$CACHE_ENABLED" = "true" ]; then
          {
            printf '%s %s # Local Tailscale host\n' "$selfIp" "$SELF_HOST"
            if [ -s "$TMP_FINAL" ]; then
              cat "$TMP_FINAL"
            fi
          } > "$CACHE_FILE.tmp"
          mv "$CACHE_FILE.tmp" "$CACHE_FILE"
          debug "Updated $CACHE_FILE"
        fi
      }

      live_run() {
        fetch_tailscale_status
        filter_by_users
        filter_by_tags
        combine_results
        update_hosts_file
      }

      trap cleanup EXIT
      if [ "$CACHE_ENABLED" != "true" ]; then
        # Legacy behavior (bootCache = false): identical to the pre-cache
        # module — 20s hard wait, then error out.
        if ! wait_for_tailscale 20; then
          printf 'ERROR: Tailscale not ready after 20 attempts\n' >&2
          exit 1
        fi
        live_run
      elif wait_for_tailscale 15; then
        live_run
      elif [ -s "$CACHE_FILE" ]; then
        printf 'WARN: tailscaled not ready after 15s — rendering last known peers from cache\n' >&2
        render_from_cache
      else
        # First boot ever (no cache): nothing sensible to render, so give
        # tailscaled a real cold-boot window before failing.
        printf 'WARN: tailscaled not ready and no cache — extending wait\n' >&2
        if wait_for_tailscale 105; then
          live_run
        else
          printf 'ERROR: Tailscale not ready after 120s and no cache available\n' >&2
          exit 1
        fi
      fi
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

    bootCache = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Persist the last known peer list under /var/lib/tailscale-hosts and
        render it into /etc/hosts at boot when tailscaled is not ready yet
        (15s grace). Turns fatal "hostname does not resolve" failures of
        early-starting consumers (incus, containers) into transient
        "host not reachable yet" conditions that resolve themselves once
        the VPN is up. Default false for backward compatibility: without it
        the unit behaves exactly like before (20s hard wait, then failure).
      '';
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
        # Early cache-only render, BEFORE sockets.target (bootCache only):
        # DefaultDependencies=no, needs no network, silently skipped when no
        # cache exists yet. Exists so incus.socket can order behind it
        # cycle-free — ordering behind the late full service created a
        # systemd ordering cycle via basic.target (inc04, 2026-09-24) that
        # systemd broke by deleting sockets.target from the transaction.
        tailscale-hosts-boot = lib.mkIf cfg.bootCache {
          description = "Render /etc/hosts from cached Tailscale peers (early boot)";
          unitConfig = {
            DefaultDependencies = false;
            ConditionPathExists = "/var/lib/tailscale-hosts/peers";
          };
          after = [ "local-fs.target" ];
          wants = [ "local-fs.target" ];
          before = [
            "sockets.target"
            "basic.target"
          ];
          wantedBy = [ "sysinit.target" ];
          path = [ pkgs.coreutils ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "tailscale-hosts-boot" ''
              set -eu
              {
                printf '# Hosts managed by NixOS configuration\n'
                cat /etc/static/hosts
                printf '# Tailscale hosts (boot cache)\n'
                cat /var/lib/tailscale-hosts/peers
              } > /etc/hosts.tmp
              mv /etc/hosts.tmp /etc/hosts
              chmod 0644 /etc/hosts
            '';
          };
        };

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
          }
          # Peer cache for the boot-time fallback path (render before
          # tailscaled has network). Survives reboots by design.
          // lib.optionalAttrs cfg.bootCache {
            StateDirectory = "tailscale-hosts";
          };
        };
      }
      // (lib.optionalAttrs config.virtualisation.incus.enable {
        incus = {
          after = [
            "tailscaled.service"
            "tailscale-hosts.service"
          ];
          # wants, not requires (2026-09-24, han-inc02): with requires a
          # failed tailscale-hosts run took incus down permanently (start
          # limits on both sides). The cache path above makes the unit
          # succeed in milliseconds at boot, so the ordering is cheap.
          wants = [
            "tailscaled.service"
            "tailscale-hosts.service"
          ];
          serviceConfig = {
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 15";
          };
        };
      });

    # Socket activation bypasses the ordering on incus.service: on cold boot
    # incusd got spawned through incus.socket BEFORE /etc/hosts had the .ts
    # entries, crash-looped on unresolvable cluster member names and hit the
    # socket trigger limit (han-inc02, 2026-09-24). Order the socket behind
    # the EARLY cache render (cycle-free), not behind the late full service.
    systemd.sockets = lib.optionalAttrs (config.virtualisation.incus.enable && cfg.bootCache) {
      incus = {
        after = [ "tailscale-hosts-boot.service" ];
        wants = [ "tailscale-hosts-boot.service" ];
      };
    };
  };
}
