#!/bin/bash

# Script to manage claude_code container with different startup options

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Container name
CONTAINER_NAME="claude_code"

# Function to display usage
usage() {
    echo "Usage: $0 {root|node|claude|claude-danger|rebuild} [additional arguments]"
    echo ""
    echo "Options:"
    echo "  root          - Start container and enter bash as root user"
    echo "  node          - Start container and enter bash as node user"
    echo "  claude        - Start container, upgrade claude, and run claude as node user"
    echo "  claude-danger - Start container, upgrade claude, and run claude with --dangerously-skip-permissions as node user"
    echo "  rebuild       - Bring down all containers, rebuild, and bring them back up"
    echo ""
    echo "For claude and claude-danger options, any additional arguments will be passed to the claude command."
    echo "Example: $0 claude --help"
    echo "Example: $0 claude-danger /path/to/file"
    echo ""
    exit 1
}

# Function to check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function to ensure container is running
ensure_container_running() {
    if ! container_exists; then
        echo -e "${YELLOW}Container ${CONTAINER_NAME} doesn't exist. Building and starting...${NC}"
        docker-compose up -d ${CONTAINER_NAME}
        sleep 5  # Give container time to start
    elif ! container_running; then
        echo -e "${YELLOW}Container ${CONTAINER_NAME} is not running. Starting...${NC}"
        docker-compose start ${CONTAINER_NAME}
        sleep 3  # Give container time to start
    else
        echo -e "${GREEN}Container ${CONTAINER_NAME} is already running${NC}"
    fi
}

# Function to upgrade claude as node user
upgrade_claude() {
    echo -e "${YELLOW}Upgrading @anthropic-ai/claude-code...${NC}"
    docker exec  ${CONTAINER_NAME} bash -c "npm update -g @anthropic-ai/claude-code"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Claude Code upgraded successfully${NC}"
    else
        echo -e "${RED}Failed to upgrade Claude Code${NC}"
        return 1
    fi
}

# Main script logic
case "$1" in
    root)
        ensure_container_running
        echo -e "${GREEN}Entering container as root user...${NC}"
        docker exec -it ${CONTAINER_NAME} bash
        ;;
    
    node)
        ensure_container_running
        echo -e "${GREEN}Entering container as node user...${NC}"
        docker exec -it -u node ${CONTAINER_NAME} bash
        ;;
    
    claude)
        ensure_container_running
        upgrade_claude
        echo -e "${GREEN}Running claude as node user...${NC}"
        shift  # Remove the 'claude' argument
        docker exec -it -u node -w /workspace ${CONTAINER_NAME} claude "$@"
        ;;
    
    claude-danger)
        ensure_container_running
        upgrade_claude
        echo -e "${GREEN}Running claude with --dangerously-skip-permissions as node user...${NC}"
        shift  # Remove the 'claude-danger' argument
        docker exec -it -u node -w /workspace ${CONTAINER_NAME} claude --dangerously-skip-permissions "$@"
        ;;
    
    rebuild)
        echo -e "${YELLOW}Bringing down all containers...${NC}"
        docker-compose down
        
        echo -e "${YELLOW}Rebuilding all containers...${NC}"
        docker-compose build
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Build completed successfully${NC}"
            echo -e "${YELLOW}Bringing up all containers...${NC}"
            docker-compose up -d
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}All containers are up and running${NC}"
                docker-compose ps
            else
                echo -e "${RED}Failed to bring up containers${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Build failed${NC}"
            exit 1
        fi
        ;;
    
    *)
        usage
        ;;
esac