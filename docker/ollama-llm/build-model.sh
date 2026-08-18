#!/bin/bash
# builds+tags+pushes a new ollama-llm version reproducibly (Dockerfile-based,
# not docker commit) — can be re-run anytime, even after deleting everything locally
set -e

NEW_TAG=$1        # e.g. v2, v3, v6
BASE_IMAGE=$2      # e.g. ollama-llm:v1 (to ADD a model) or ollama/ollama:0.3.6 (fresh start)
MODEL_NAME=$3      # e.g. nomic-embed-text:v1.5

ECR_URI="332250067977.dkr.ecr.eu-central-1.amazonaws.com/ollama-llm"

DOCKER_BUILDKIT=0 docker build \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  --build-arg MODEL_NAME="$MODEL_NAME" \
  -t ollama-llm:"$NEW_TAG" .

docker tag ollama-llm:"$NEW_TAG" "$ECR_URI:$NEW_TAG"
docker push "$ECR_URI:$NEW_TAG"

echo "Done: ollama-llm:$NEW_TAG pushed to ECR"
