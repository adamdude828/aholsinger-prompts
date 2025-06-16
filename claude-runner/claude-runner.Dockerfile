FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    make \
    g++ \
    docker.io \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Install Claude Code globally as root
RUN npm install -g @anthropic-ai/claude-code

RUN npm i -g playwright

# Install Playwright browsers with dependencies
RUN npx -y playwright install --with-deps

RUN npx playwright install chrome

# Create non-root user with sudo privileges
RUN useradd -m -s /bin/bash node \
    && echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /workspace

# Don't switch to node user - container will start as root

# Create .config directory for node user
RUN mkdir -p /home/node/.config

# Set environment variables
ENV NODE_ENV=development
ENV PATH="/usr/local/bin:${PATH}"

# Keep container running
CMD ["tail", "-f", "/dev/null"]
