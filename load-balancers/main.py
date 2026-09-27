"""Load Balancers: an L7 HTTP balancer with path routing and an L4 TCP balancer.

Requires: pip install ibee
Environment:
  IBEE_TOKEN         API token (load-balancer.read, load-balancer.write)
  IBEE_WORKSPACE_ID  workspace ID
  IBEE_BACKEND_IPS   comma-separated backend VM IPs
  IBEE_ENV           "dev" to use the development API (optional)
  KEEP               set to 1 to keep the load balancers
"""

import os
import time

from ibee import Ibee, IbeeEnvironment, LoadBalancerBackend, LoadBalancerRouting, LoadBalancerRule

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
BACKEND_IPS = [ip.strip() for ip in os.environ.get("IBEE_BACKEND_IPS", "").split(",") if ip.strip()]
if not BACKEND_IPS:
    raise SystemExit("Set IBEE_BACKEND_IPS to the backend VM addresses")
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
lbs = client.load_balancers


def backends(port):
    return [LoadBalancerBackend(type="ip", target=ip, port=port) for ip in BACKEND_IPS]


def wait_until_active(lb_id, timeout_seconds=900):
    deadline = time.monotonic() + timeout_seconds
    while True:
        status = lbs.get_load_balancer_status(load_balancer_id=lb_id, workspace_id=WORKSPACE_ID)
        if status.status == "active":
            return status
        if status.status == "failed" or time.monotonic() > deadline:
            raise RuntimeError(f"load balancer {lb_id} is {status.status}: {status.error_message}")
        time.sleep(10)


# 1. L7: web traffic on port 80, /api to port 8080.
web = lbs.create_l7load_balancer(
    workspace_id=WORKSPACE_ID,
    name="example-web",
    protocol="http",
    backends=backends(80),
    routing=LoadBalancerRouting(algorithm="round_robin"),
    rules=[LoadBalancerRule(priority=10, path_prefix="/api", backends=backends(8080))],
)

# 2. L4: raw TCP, for example a database or a custom protocol.
tcp = lbs.create_l4load_balancer(
    workspace_id=WORKSPACE_ID,
    name="example-postgres",
    protocol="tcp",
    backends=backends(5432),
)

for lb in (web, tcp):
    ready = wait_until_active(lb.lb_id)
    print(f"{lb.name} ({lb.layer}) is active at {ready.endpoint_url}")

if os.getenv("KEEP") != "1":
    for lb in (web, tcp):
        lbs.delete_load_balancer(load_balancer_id=lb.lb_id, workspace_id=WORKSPACE_ID)
        print(f"Deleted {lb.name}")
