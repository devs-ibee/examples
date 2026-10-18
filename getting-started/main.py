"""List the sites, plans and images that the other examples take as input."""

from ibee import Ibee

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV

print("Sites")
for site in client.compute_catalog.list_compute_sites().sites:
    print(f"  {site.site_id}  {site.name}")

print("Cloud VM plans")
for plan in client.compute_catalog.list_compute_plans(vm_type="cloud").plans:
    print(f"  {plan.plan_id}  {plan.name}  {plan.cpu} vCPU  {plan.ram_mb} MB  site={plan.site_id}")

print("Cloud VM images")
for image in client.compute_catalog.list_compute_images(vm_type="cloud").images:
    print(f"  {image.template_id}  {image.name}")
