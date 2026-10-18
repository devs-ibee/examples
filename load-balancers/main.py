"""Create an HTTP load balancer in front of two backends, read its status, and delete it."""

import os

from ibee import Ibee, LoadBalancerBackend

client = Ibee()  # reads IBEE_TOKEN, IBEE_WORKSPACE_ID and IBEE_ENV
lbs = client.load_balancers

lb = lbs.create_l7load_balancer(
    name="example-web",
    protocol="http",
    backends=[LoadBalancerBackend(type="ip", target=ip, port=80) for ip in os.environ["IBEE_BACKEND_IPS"].split(",")],
)
status = lbs.get_load_balancer_status(lb.lb_id)
print(f"{lb.name} is {status.status} at {status.endpoint_url}")

lbs.delete_load_balancer(lb.lb_id)
