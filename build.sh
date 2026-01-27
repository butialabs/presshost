#!/bin/bash
# Usage: ./build.sh [REGISTRY=<registry>] [IMAGE_TAG=latest] [PLATFORMS=<platforms>] [PUSH=true|false] [RUN=true|false]
# local build and run: ./build.sh
# local build only: RUN=false ./build.sh
# local build with custom name: REGISTRY=myapp IMAGE_TAG=dev ./build.sh
# push to registry: REGISTRY=docker.io/myuser/presshost IMAGE_TAG=v1.0 ./build.sh
# push to registry explicit: REGISTRY=docker.io/myuser/presshost PUSH=true ./build.sh

set -e

REGISTRY="${REGISTRY:-presshost}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
PLATFORMS="${PLATFORMS:-}"
PUSH="${PUSH:-}"
RUN="${RUN:-true}"
BUILDER_NAME="presshost-builder"
CONTAINER_NAME="presshost-dev"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

IMAGE_NAME="${REGISTRY}"

IS_REMOTE_REGISTRY=false
if [[ "${REGISTRY}" == *"/"* ]] || [[ "${REGISTRY}" == *"."* ]]; then
    IS_REMOTE_REGISTRY=true
fi

if [ -z "${PLATFORMS}" ]; then
    if [ "${PUSH}" = "true" ] || [ "${IS_REMOTE_REGISTRY}" = "true" ]; then
        PLATFORMS="linux/amd64,linux/arm64"
    else
        ARCH=$(uname -m)
        case "${ARCH}" in
            x86_64) PLATFORMS="linux/amd64" ;;
            aarch64|arm64) PLATFORMS="linux/arm64" ;;
            armv7l) PLATFORMS="linux/arm/v7" ;;
            *) PLATFORMS="linux/amd64" ;;
        esac
    fi
fi

if [ -z "${PUSH}" ]; then
    if [ "${IS_REMOTE_REGISTRY}" = "true" ]; then
        PUSH="true"
    else
        PUSH="false"
    fi
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} PressHost Docker Build${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Image: ${YELLOW}${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo -e "Platforms: ${YELLOW}${PLATFORMS}${NC}"
if [ "${PUSH}" = "true" ]; then
    echo -e "Mode: ${YELLOW}Push to Registry${NC}"
else
    echo -e "Mode: ${YELLOW}Local Build${NC}"
fi
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed or not in PATH${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}ERROR: Docker daemon is not running. Please start Docker.${NC}"
    exit 1
fi

if ! docker buildx inspect "${BUILDER_NAME}" &> /dev/null; then
    echo -e "${GREEN}Creating buildx builder '${BUILDER_NAME}'...${NC}"
    docker buildx create --name "${BUILDER_NAME}" --driver docker-container --bootstrap
fi

docker buildx use "${BUILDER_NAME}"

echo -e "${GREEN}Building Docker image for platforms: ${PLATFORMS}...${NC}"
echo ""

if [ "${PUSH}" = "true" ]; then
    docker buildx build \
        --platform "${PLATFORMS}" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        -f Dockerfile \
        --push \
        .
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Build & Push Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Image: ${YELLOW}${IMAGE_NAME}:${IMAGE_TAG}${NC}"
    echo -e "Platforms: ${YELLOW}${PLATFORMS}${NC}"
else
    docker buildx build \
        --platform "${PLATFORMS}" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        -f Dockerfile \
        --load \
        .
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Build Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Image: ${YELLOW}${IMAGE_NAME}:${IMAGE_TAG}${NC}"
    echo -e "Platforms: ${YELLOW}${PLATFORMS}${NC}"
    echo ""
    echo -e "${YELLOW}Note: Image loaded to local Docker daemon.${NC}"
    echo -e "${YELLOW}Use PUSH=true to push to a registry, or specify a remote registry.${NC}"
    
    if [ "${RUN}" = "true" ]; then
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN} Starting Container...${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        
        if docker ps -aq -f name="${CONTAINER_NAME}" | grep -q .; then
            echo -e "${YELLOW}Stopping existing container '${CONTAINER_NAME}'...${NC}"
            docker stop "${CONTAINER_NAME}" 2>/dev/null || true
            docker rm "${CONTAINER_NAME}" 2>/dev/null || true
        fi
        
        echo -e "${GREEN}Starting container '${CONTAINER_NAME}'...${NC}"
        docker run -d \
            --name "${CONTAINER_NAME}" \
            -p 8080:80 \
            -p 8443:443 \
            -e SITE_URL=localhost \
            -e DB_HOST=host.docker.internal \
            -e DB_NAME=presshost \
            -e DB_USER=presshost \
            -e DB_PASSWORD=presshost \
            "${IMAGE_NAME}:${IMAGE_TAG}"
        
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN} Container Started!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "Container: ${YELLOW}${CONTAINER_NAME}${NC}"
        echo -e "HTTP: ${YELLOW}http://localhost:8080${NC}"
        echo -e "HTTPS: ${YELLOW}https://localhost:8443${NC}"
        echo ""
        echo -e "${GREEN}Commands:${NC}"
        echo -e "  ${YELLOW}Logs: docker logs -f ${CONTAINER_NAME}${NC}"
        echo -e "  ${YELLOW}Shell: docker exec -it ${CONTAINER_NAME} bash${NC}"
        echo -e "  ${YELLOW}Stop: docker stop ${CONTAINER_NAME}${NC}"
    fi
fi
