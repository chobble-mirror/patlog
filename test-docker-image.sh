#!/bin/bash
set -e

# Configuration
IMAGE_NAME="patlog-test-local"
TAG="latest"
CONTAINER_NAME="patlog-test"
PORT=3000
TIMEOUT=30  # seconds to wait for container to start

echo "Building and testing local Docker image..."

# Cleanup any existing test container and image
echo "Cleaning up any existing test resources..."
docker rm -f ${CONTAINER_NAME} &>/dev/null || true
docker rmi ${IMAGE_NAME}:${TAG} &>/dev/null || true

# Build the image locally
echo "Building Docker image from local Dockerfile..."
docker build -t ${IMAGE_NAME}:${TAG} .

# Run the container
echo "Starting container..."
docker run -d --name ${CONTAINER_NAME} -p ${PORT}:3000 \
  -e SECRET_KEY_BASE=c6f7be2111cd5fa56e8a8f6cd00200d0c6f7be2111cd5fa56e8a8f6cd00200d0 \
  -e RAILS_MASTER_KEY=c6f7be2111cd5fa56e8a8f6cd00200d0 \
  -e DATABASE_URL="sqlite3:/rails/db/production.sqlite3" \
  --cap-add=NET_ADMIN \
  ${IMAGE_NAME}:${TAG}

# Note: we don't need to install curl as it's already included in the base image

# Wait for container to be ready
echo "Waiting for container to start (up to ${TIMEOUT} seconds)..."
start_time=$(date +%s)
while true; do
  if docker logs ${CONTAINER_NAME} 2>&1 | grep -q "Listening on"; then
    echo "Container started successfully!"
    break
  fi
  
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  
  if [ $elapsed -gt $TIMEOUT ]; then
    echo "ERROR: Container failed to start within ${TIMEOUT} seconds"
    docker logs ${CONTAINER_NAME}
    docker rm -f ${CONTAINER_NAME}
    exit 1
  fi
  
  echo "Still waiting... (${elapsed}s elapsed)"
  sleep 2
done

# Test HTTP response both from outside and inside the container
echo "Testing HTTP connection from host to localhost:${PORT}..."
host_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/ || echo "failed")

echo "Testing HTTP connection from inside the container..."
container_response=$(docker exec ${CONTAINER_NAME} curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "failed")

echo "Host response: ${host_response}"
echo "Container internal response: ${container_response}"

# Use the container's response as the primary check
response=${container_response}

echo "HTTP response code: ${response}"

# Cleanup
echo "Cleaning up test container..."
docker rm -f ${CONTAINER_NAME}

# Check result
if [ "${response}" == "200" ] || [ "${response}" == "302" ]; then
  echo "SUCCESS: Docker image is working correctly! (HTTP ${response})"
  exit 0
else
  echo "FAILURE: Docker image returned HTTP ${response} instead of 200/302"
  exit 1
fi