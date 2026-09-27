#!/usr/bin/env bash
# Scheduled backups, an on-demand backup, a snapshot, and recovery points with the ibee CLI.
#
# Requires: pip install ibee-cli
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, IBEE_VM_ID, optional IBEE_ENV=dev
set -euo pipefail

VM_ID="$IBEE_VM_ID"

ibee vms backup-policy enable "$VM_ID" --frequency daily --timezone UTC --hour 20 --retention-days 7
ibee vms backup-policy get "$VM_ID"
ibee vms backups create "$VM_ID" --reason "before upgrade"
ibee vms snapshots create "$VM_ID" "before-upgrade-$(date +%Y%m%d)" --mode root_only

ibee vms backups list "$VM_ID" --limit 10
ibee vms snapshots list "$VM_ID" --limit 10
