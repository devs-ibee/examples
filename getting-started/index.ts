// List the sites, plans and images that the other examples take as input.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV

console.log("Sites");
for (const site of (await ibee.computeCatalog.listComputeSites()).sites) {
  console.log(`  ${site.site_id}  ${site.name}`);
}

console.log("Cloud VM plans");
for (const plan of (await ibee.computeCatalog.listComputePlans({ vm_type: "cloud" })).plans) {
  console.log(`  ${plan.plan_id}  ${plan.name}  ${plan.cpu} vCPU  ${plan.ram_mb} MB  site=${plan.site_id}`);
}

console.log("Cloud VM images");
for (const image of (await ibee.computeCatalog.listComputeImages({ vm_type: "cloud" })).images) {
  console.log(`  ${image.template_id}  ${image.name}`);
}
