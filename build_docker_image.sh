#!/usr/bin/env bash
#
# Usage:
#   ./build_docker_image.sh [<image_name>]

set -euox pipefail

cd "$(dirname "${0}")"

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
GIT_SHA="$(git rev-parse --short HEAD)"

REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com" TAG="sha-${GIT_SHA}" \
  docker buildx bake
