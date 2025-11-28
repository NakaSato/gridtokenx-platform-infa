FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    libssl-dev \
    libudev-dev \
    pkg-config \
    zlib1g-dev \
    llvm \
    clang \
    cmake \
    make \
    libprotobuf-dev \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Set Solana version (can be overridden at build time)
ARG SOLANA_VERSION=1.18.22

# Install Solana CLI tools
RUN sh -c "$(curl -sSfL https://release.solana.com/v${SOLANA_VERSION}/install)" && \
    echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /root/.bashrc

ENV PATH="/root/.local/share/solana/install/active_release/bin:$PATH"

# Create ledger directory
RUN mkdir -p /solana/ledger

# Expose ports
# 8899 - JSON RPC
# 8900 - WebSocket
# 8001 - Gossip
# 8002 - TPU
# 8003 - TPU forwards
# 8004 - Repair
# 8005 - ServeR
EXPOSE 8899 8900 8001 8002 8003 8004 8005

WORKDIR /solana

# Default command to run test validator
CMD ["solana-test-validator", \
    "--ledger", "/solana/ledger", \
    "--rpc-port", "8899", \
    "--rpc-bind-address", "0.0.0.0", \
    "--dynamic-port-range", "8001-8020", \
    "--gossip-port", "8001", \
    "--faucet-port", "9900", \
    "--log"]
