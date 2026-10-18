#!/usr/bin/env bash
# Reserve a public IP, attach it to a VM, detach it, and release it, with the ibee CLI.
set -euo pipefail

IP_ID=$(ibee -o id reserved-ips reserve --site-id "$IBEE_SITE_ID" --label example-web)

ibee reserved-ips attach "$IP_ID" "$IBEE_VM_ID"
ibee reserved-ips get "$IP_ID"
ibee reserved-ips detach "$IP_ID"
ibee reserved-ips release "$IP_ID" --yes
