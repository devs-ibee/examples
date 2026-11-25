"""Create a regional HTTP load balancer in front of two VMs, change it, and delete it."""

import os
import time

from ibee import (
    Ibee,
    LoadBalancerHealthCheck,
    LoadBalancerListener,
    LoadBalancerSpec,
    LoadBalancerTarget,
    LoadBalancerTargetGroup,
)

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
lbs = client.load_balancers
region = lbs.list_load_balancer_regions()[0]


def spec(health_path):
    """The whole specification: create sends it, and every update sends it again."""
    return dict(
        name="example-web",
        region_id=region.id,
        traffic_type="http",
        # Listeners are the ports it answers on; each sends traffic to a target group.
        listeners=[LoadBalancerListener(name="http", protocol="HTTP", port=80, target_group="web")],
        # Targets are VMs with their own public IP, by ID. Private addresses (kind="ip") only work
        # in a region whose capabilities.private_targets is true, and then also need vpc_id.
        target_groups=[
            LoadBalancerTargetGroup(
                name="web",
                protocol="HTTP",
                targets=[LoadBalancerTarget(kind="vm", resource_id=vm, port=80) for vm in os.environ["IBEE_BACKEND_VM_IDS"].split(",")],
                # Leave unhealthy_threshold out: the service uses 1 for HTTP checks and 3 for TCP.
                health_check=LoadBalancerHealthCheck(protocol="HTTP", path=health_path),
            )
        ],
    )


def wait(accepted):
    """Poll a load balancer operation until it finishes."""
    while True:
        op = lbs.get_load_balancer_operation(accepted.id)
        if op.completed_at:
            print(f"{op.kind}: {op.status} {op.reason or ''}")
            return op
        time.sleep(10)


accepted = lbs.create_load_balancer(**spec("/"))
wait(accepted)

lb = lbs.get_load_balancer(accepted.lb_id)
# The public address clients connect to (point an A record at it for your own domain).
address = (lb.conditions.addresses or ["-"])[0]
print(f"{lb.name} in {region.name} is {lb.observed_state} at {address}, version {lb.version}")

# An update replaces the whole specification and sends the version it was read at.
wait(lbs.update_load_balancer(lb.id, version=lb.version, specification=LoadBalancerSpec(**spec("/healthz"))))

wait(lbs.delete_load_balancer(lb.id))
