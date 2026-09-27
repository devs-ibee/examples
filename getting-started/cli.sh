#!/usr/bin/env bash
# Verify credentials and discover sites, plans, images, and billing status.
#
# Requires: pip install ibee-cli
# Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev
set -euo pipefail

ibee --version
ibee compute sites
ibee compute plans --vm-type cloud
ibee compute images --vm-type cloud
ibee vpcs sites
ibee billing eligibility --sku-code OBJECTST-STD
