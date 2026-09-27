#!/usr/bin/env bash
# Log in to the IBEE Container Registry, build and push an image, then pull it
# back by tag and by immutable digest.
#
# Requires: Docker
# Environment:
#   IBEE_REGISTRY_NAME      registry name from the portal, for example acme-apps
#   IBEE_REGISTRY_USERNAME  registry username from the access token
#   IBEE_REGISTRY_TOKEN     access token with push permission
#   IMAGE_TAG               tag to push (default: the current git commit, or "latest")
set -euo pipefail

REGISTRY="registry.ibee.ai"
REPOSITORY="${REPOSITORY:-web}"
TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo latest)}"
IMAGE="$REGISTRY/$IBEE_REGISTRY_NAME/$REPOSITORY"

# The token goes to Docker on standard input, never on the command line.
printf '%s' "$IBEE_REGISTRY_TOKEN" | docker login "$REGISTRY" --username "$IBEE_REGISTRY_USERNAME" --password-stdin

docker build -t "$IMAGE:$TAG" -t "$IMAGE:latest" "$(dirname "$0")"
docker push "$IMAGE:$TAG"
docker push "$IMAGE:latest"

# Deploy by digest for an immutable reference; tags can be moved.
DIGEST=$(docker inspect --format '{{index .RepoDigests 0}}' "$IMAGE:$TAG")
echo "Pushed $IMAGE:$TAG"
echo "Immutable reference: $DIGEST"

docker pull "$IMAGE:$TAG"
docker pull "$DIGEST"
