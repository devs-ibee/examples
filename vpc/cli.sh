#!/usr/bin/env bash
# Create a VPC and a subnet, attach a VM, then remove all three, with the ibee CLI.
set -euo pipefail

# The API picks free address ranges when you give no CIDR.
VPC_ID=$(ibee -o id vpcs create --name example-network --site-id "$IBEE_SITE_ID" --no-create-default-subnet)
until [[ $(ibee --json vpcs get "$VPC_ID" | jq -r .status) == available ]]; do sleep 5; done

SUBNET_ID=$(ibee -o id vpcs subnets create "$VPC_ID" --name apps)
until [[ $(ibee --json vpcs subnets get "$VPC_ID" "$SUBNET_ID" | jq -r .status) == available ]]; do sleep 5; done

ibee vpcs nodes attach "$VPC_ID" --vm-id "$IBEE_VM_ID" --subnet-id "$SUBNET_ID"

ibee vpcs nodes detach "$VPC_ID" "$IBEE_VM_ID" --yes
ibee vpcs subnets delete "$VPC_ID" "$SUBNET_ID" --yes
ibee vpcs delete "$VPC_ID" --yes
