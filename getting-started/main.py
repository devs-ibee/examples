"""Verify credentials and discover sites, plans, images, and billing status.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (vm.read, network.read, billing.read)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_ENV           "dev" to use the development API (optional)
"""

import os

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)


def money(minor, currency):
    return "-" if minor is None else f"{minor / 100:,.2f} {currency}"


print("Compute sites")
for site in client.compute_catalog.list_compute_sites(workspace_id=WORKSPACE_ID).sites:
    print(f"  {site.site_id}  {site.name}  {site.location or ''}")

print("\nCloud VM plans (priced, cheapest first)")
plans = client.compute_catalog.list_compute_plans(workspace_id=WORKSPACE_ID, vm_type="cloud").plans
priced = [p for p in plans if p.selectable and p.pricing_status == "priced"]
for plan in sorted(priced, key=lambda p: p.hourly_price_minor or 0)[:10]:
    print(
        f"  {plan.plan_id}  {plan.name}  {plan.cpu} vCPU / {plan.ram_mb // 1024} GB RAM / {plan.disk_gb} GB disk"
        f"  {money(plan.hourly_price_minor, plan.currency)}/hour  site={plan.site_id}"
    )

print("\nCloud OS images")
for image in client.compute_catalog.list_compute_images(workspace_id=WORKSPACE_ID, vm_type="cloud").images:
    print(f"  {image.template_id}  {image.name}  ({image.os_distro} {image.distro_version or ''})")

print("\nNetworking sites")
for site in client.vpcs.list_networking_sites(workspace_id=WORKSPACE_ID):
    print(f"  {site.site_id}  {site.site_name}  {'available' if site.available else 'unavailable'}")

decision = client.billing.check_resource_eligibility(workspace_id=WORKSPACE_ID, sku_code="OBJECTST-STD")
print(f"\nBilling allows a new bucket: {decision.allowed} ({decision.reason})")
