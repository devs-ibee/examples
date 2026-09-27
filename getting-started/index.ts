/**
 * Verify credentials and discover sites, plans, images, and billing status.
 *
 * Requires: npm install ibee-sdk
 * Run:      npx tsx getting-started/index.ts
 * Environment: IBEE_TOKEN, IBEE_WORKSPACE_ID, optional IBEE_ENV=dev
 */
import { Ibee, IbeeEnvironment } from "ibee-sdk";

const workspaceId = process.env.IBEE_WORKSPACE_ID!;
const client = new Ibee({
  token: process.env.IBEE_TOKEN!,
  environment: process.env.IBEE_ENV === "dev" ? IbeeEnvironment.DEVELOPMENT : IbeeEnvironment.DEFAULT,
});

const money = (minor: number | undefined, currency: string) =>
  minor === undefined ? "-" : `${(minor / 100).toFixed(2)} ${currency}`;

const { sites } = await client.computeCatalog.listSites({ workspaceId });
console.log("Compute sites");
for (const site of sites) console.log(`  ${site.site_id}  ${site.name}  ${site.location ?? ""}`);

const { plans } = await client.computeCatalog.listPlans({ workspaceId, vmType: "cloud" });
console.log("\nCloud VM plans (priced, cheapest first)");
plans
  .filter((plan) => plan.selectable && plan.pricing_status === "priced")
  .sort((a, b) => (a.hourly_price_minor ?? 0) - (b.hourly_price_minor ?? 0))
  .slice(0, 10)
  .forEach((plan) =>
    console.log(
      `  ${plan.plan_id}  ${plan.name}  ${plan.cpu} vCPU / ${plan.ram_mb / 1024} GB RAM  ` +
        `${money(plan.hourly_price_minor, plan.currency)}/hour  site=${plan.site_id}`,
    ),
  );

const { images } = await client.computeCatalog.listImages({ workspaceId, vmType: "cloud" });
console.log("\nCloud OS images");
for (const image of images) console.log(`  ${image.template_id}  ${image.name}  (${image.os_distro})`);

console.log("\nNetworking sites");
for (const site of await client.vpcs.listSites({ workspaceId })) {
  console.log(`  ${site.site_id}  ${site.site_name}  ${site.available ? "available" : "unavailable"}`);
}

const decision = await client.billing.checkResourceEligibility({ workspaceId, skuCode: "OBJECTST-STD" });
console.log(`\nBilling allows a new bucket: ${decision.allowed} (${decision.reason})`);
