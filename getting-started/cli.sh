#!/usr/bin/env bash
# List the sites, plans and images that the other examples take as input.
set -euo pipefail

ibee compute sites
ibee compute plans --vm-type cloud
ibee compute images --vm-type cloud
