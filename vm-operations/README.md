# VM operations

Day-2 operations on a running Cloud VM: read metrics and events, check and apply a resize, add an SSH key, and open a browser console.

## What it does

1. Prints current metrics, the last hour of metric series, this month's bandwidth, and recent lifecycle events.
2. Asks the API whether the VM can move to the next larger plan, and prints the decision with any reasons and warnings.
3. With `RESIZE=1`, applies that resize. If the precheck says the VM must be stopped, it stops the VM first and starts it again afterwards.
4. With `IBEE_SSH_PUBLIC_KEY` set, adds that public key to the VM's admin user.
5. Opens a short-lived graphical console session and prints its URL.

## Requirements

- An API token with `vm.read` and `vm.write`.
- An existing Cloud VM (`IBEE_VM_ID`).
- Resizing to a larger plan increases the VM's hourly price.

## Run it

```bash
export IBEE_TOKEN="ibee_prod_key_..."
export IBEE_WORKSPACE_ID="<workspace-id>"
export IBEE_VM_ID="<vm-id>"

python3 main.py                  # read-only checks and a console session
RESIZE=1 python3 main.py         # also resize to the next plan
IBEE_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" python3 main.py
npx tsx index.ts                 # the same with the TypeScript SDK
bash cli.sh                      # the same with the ibee CLI
bash api.sh                      # the same with curl and jq
```

The console URL grants access to the VM. Do not log it or share it; it expires after a few minutes.
