# Container Registry

Build an image, push it to your IBEE registry, and pull it back. The registry has no public API yet: create the registry and its access tokens in the portal, then use Docker.

1. In the [portal](https://portal.ibee.ai), open **Infrastructure → Container Registry** and create a registry, for example `acme-apps`.
2. Create a registry access token (**Pull and push**) and save its username and token; the token is shown only once.

```bash
export IBEE_REGISTRY_NAME=acme-apps
export IBEE_REGISTRY_USERNAME='<registry-username>'   # contains a $, so use single quotes
export IBEE_REGISTRY_TOKEN='<access-token>'
bash push.sh
```

On a server or in Kubernetes, log in to `registry.ibee.ai` with a **Pull only** token and use the image `registry.ibee.ai/<registry>/web:<tag>`.
