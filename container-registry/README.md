# Container Registry

Build an image, push it to your IBEE registry, pull it on a server, deploy it to Kubernetes, and publish it from GitHub Actions.

Registries and their access tokens are created in the portal; everything else uses standard Docker and OCI tooling against `registry.ibee.ai`.

## Files

| File | Use |
|---|---|
| `Dockerfile` | A minimal web image to push |
| `push.sh` | Log in, build, push, and pull by tag and by digest |
| `github-actions.yml` | Build and push on every commit to `main` |
| `kubernetes.yaml` | Pull from a private registry with an image pull secret |

## Before you begin

1. In the portal, open **Container Registry** under **Infrastructure** and create a registry, for example `acme-apps`. See [Container Registry](https://ibee.ai/docs/tools/container-registry).
2. Create a registry access token from the registry's **Overview** tab (**API Tokens → Registry access tokens**):
   - **Pull and push** for developers and CI.
   - **Pull only** for servers and Kubernetes clusters.
3. Save the **Registry username** and **Access token**; the token is shown only once.

## Push from your machine

```bash
export IBEE_REGISTRY_NAME="acme-apps"
export IBEE_REGISTRY_USERNAME='<registry-username>'   # contains a $, so use single quotes
export IBEE_REGISTRY_TOKEN='<access-token>'
bash push.sh
```

## Pull on a server

Log in with a **Pull only** token, then run the image:

```bash
printf '%s' "$IBEE_REGISTRY_TOKEN" | docker login registry.ibee.ai --username "$IBEE_REGISTRY_USERNAME" --password-stdin
docker run -d --restart unless-stopped -p 80:8080 registry.ibee.ai/acme-apps/web:latest
```

## Deploy to Kubernetes

```bash
kubectl create secret docker-registry ibee-registry \
  --docker-server=registry.ibee.ai \
  --docker-username='<registry-username>' \
  --docker-password='<access-token>'
kubectl apply -f kubernetes.yaml
```

## Publish from GitHub Actions

Copy `github-actions.yml` to `.github/workflows/publish.yml` in your repository and add three repository secrets: `IBEE_REGISTRY_NAME`, `IBEE_REGISTRY_USERNAME`, and `IBEE_REGISTRY_TOKEN` (a **Pull and push** token).

Every pushed image is scanned for vulnerabilities and gets an SBOM automatically. Review the results on the registry's **Security** tab.
