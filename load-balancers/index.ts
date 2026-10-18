// Create an HTTP load balancer in front of two backends, read its status, and delete it.
import { Ibee } from "ibee-sdk";

const ibee = new Ibee(); // reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
const lbs = ibee.loadBalancers;

const lb = await lbs.createL7LoadBalancer({
  name: "example-web",
  protocol: "http",
  backends: process.env.IBEE_BACKEND_IPS!.split(",").map((target) => ({ type: "ip", target, port: 80 })),
});
const status = await lbs.getLoadBalancerStatus({ load_balancer_id: lb.lb_id });
console.log(`${lb.name} is ${status.status} at ${status.endpoint_url}`);

await lbs.deleteLoadBalancer({ load_balancer_id: lb.lb_id });
