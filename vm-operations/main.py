"""Day-2 Cloud VM operations: metrics, events, resize, SSH access, and console.

Requires: pip install ibee
Environment:
  IBEE_TOKEN           API token (vm.read, vm.write)
  IBEE_WORKSPACE_ID    workspace ID
  IBEE_VM_ID           the Cloud VM to operate on
  IBEE_ENV             "dev" to use the development API (optional)
  RESIZE               set to 1 to apply the resize after the precheck
  IBEE_SSH_PUBLIC_KEY  public key to add to the VM (optional)
"""

import datetime
import os
import time
import uuid

from ibee import Ibee, IbeeEnvironment

WORKSPACE_ID = os.environ["IBEE_WORKSPACE_ID"]
VM_ID = os.environ["IBEE_VM_ID"]
client = Ibee(
    token=os.environ["IBEE_TOKEN"],
    environment=IbeeEnvironment.DEVELOPMENT if os.getenv("IBEE_ENV") == "dev" else IbeeEnvironment.DEFAULT,
)
vms = client.cloud_vms


def wait_for(operation_id):
    while True:
        op = vms.get_compute_operation(operation_id=operation_id, workspace_id=WORKSPACE_ID)
        if op.status in {"succeeded", "failed", "cancelled", "timed_out"}:
            break
        time.sleep(10)
    if op.status != "succeeded":
        raise RuntimeError(f"{op.action} {op.status}: {op.error_message}")
    print(f"  {op.action}: succeeded")


# 1. Observability.
vm = vms.get_cloud_vm(vm_id=VM_ID, workspace_id=WORKSPACE_ID)
print(f"{vm.name}: {vm.status}, {vm.cpu} vCPU, {vm.ram_mb} MB RAM, {vm.disk_gb} GB disk")
print("Current metrics:", vms.get_cloud_vm_metrics(vm_id=VM_ID, workspace_id=WORKSPACE_ID))
series = vms.get_cloud_vm_metrics_timeseries(vm_id=VM_ID, workspace_id=WORKSPACE_ID, range="1h")
print(f"Metric series for the last hour at {series.resolution} resolution: {sorted((series.series or {}).keys())}")
month = datetime.date.today().strftime("%Y-%m")
bandwidth = vms.get_cloud_vm_bandwidth(vm_id=VM_ID, workspace_id=WORKSPACE_ID, month=month)
print(f"Bandwidth in {month}: received {bandwidth.rx_bytes} bytes, sent {bandwidth.tx_bytes} bytes")
for event in vms.list_cloud_vm_events(vm_id=VM_ID, workspace_id=WORKSPACE_ID, limit=5):
    print(f"Event {event.created_at:%Y-%m-%d %H:%M}: {event.event_type}: {event.message}")

# 2. Resize precheck to the next larger priced plan.
plans = client.compute_catalog.list_compute_plans(workspace_id=WORKSPACE_ID, vm_type="cloud").plans
larger = sorted(
    (p for p in plans if p.selectable and p.pricing_status == "priced" and (p.cpu, p.ram_mb) > (vm.cpu or 0, vm.ram_mb or 0)),
    key=lambda p: (p.cpu, p.ram_mb),
)
if larger:
    target = larger[0]
    check = vms.precheck_cloud_vm_resize(vm_id=VM_ID, workspace_id=WORKSPACE_ID, cpu=target.cpu, ram_mb=target.ram_mb)
    print(f"Resize to {target.cpu} vCPU / {target.ram_mb} MB: {check.decision}, requires stop: {check.requires_stop}")
    for reason in check.reasons or []:
        print("  reason:", reason)
    for warning in check.warnings or []:
        print("  warning:", warning)

    # 3. Apply the resize only when asked to, and only when the precheck allows it.
    if os.getenv("RESIZE") == "1" and check.decision != "blocked":
        if check.requires_stop:
            wait_for(vms.stop_cloud_vm(vm_id=VM_ID, workspace_id=WORKSPACE_ID, idempotency_key=str(uuid.uuid4())).operation_id)
        wait_for(
            vms.resize_cloud_vm_plan(
                vm_id=VM_ID,
                workspace_id=WORKSPACE_ID,
                idempotency_key=str(uuid.uuid4()),
                cpu=target.cpu,
                ram_mb=target.ram_mb,
            ).operation_id
        )
        if check.requires_stop:
            wait_for(vms.start_cloud_vm(vm_id=VM_ID, workspace_id=WORKSPACE_ID, idempotency_key=str(uuid.uuid4())).operation_id)

# 4. Add an SSH public key to the admin user.
if os.getenv("IBEE_SSH_PUBLIC_KEY"):
    wait_for(
        vms.update_cloud_vm_access(
            vm_id=VM_ID,
            workspace_id=WORKSPACE_ID,
            idempotency_key=str(uuid.uuid4()),
            ssh_key_mode="add",
            ssh_keys=[os.environ["IBEE_SSH_PUBLIC_KEY"]],
        ).operation_id
    )

# 5. A short-lived browser console. The URL grants access: do not log or share it.
session = client.vm_console.create_vm_console_session(workspace_id=WORKSPACE_ID, vm_id=VM_ID, vm_type="cloud")
print(f"Console session {session.session_id} expires in {session.token_expires_in_seconds} seconds:")
print(session.connect_url)
