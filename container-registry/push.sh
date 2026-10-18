#!/usr/bin/env bash
# Log in to the IBEE Container Registry, build and push an image, then pull it back.
set -euo pipefail

IMAGE="registry.ibee.ai/$IBEE_REGISTRY_NAME/web:${IMAGE_TAG:-latest}"

# The token goes to Docker on standard input, never on the command line.
printf '%s' "$IBEE_REGISTRY_TOKEN" | docker login registry.ibee.ai --username "$IBEE_REGISTRY_USERNAME" --password-stdin

docker build -t "$IMAGE" "$(dirname "$0")"
docker push "$IMAGE"
docker pull "$IMAGE"
