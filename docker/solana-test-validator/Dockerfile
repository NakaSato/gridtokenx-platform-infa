# Solana Test Validator Docker Image
# Uses the official Agave image from Anza
#
# ⚠️  IMPORTANT: Apple Silicon (M1/M2/M3) Compatibility
#     The Solana validator requires AVX CPU instructions which are NOT available
#     when running x86_64 containers via Rosetta/QEMU emulation on ARM64.
#
#     For Apple Silicon Macs, run solana-test-validator natively:
#     1. Install: sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
#     2. Run: solana-test-validator --reset
#
#     This Docker image works on native x86_64/AMD64 Linux machines.
#
# Reference: https://github.com/anza-xyz/agave/blob/master/docker-solana/README.md

FROM anzaxyz/agave:v2.1.6

# Create ledger directory
RUN mkdir -p /solana/ledger

# Expose ports
# 8899 - JSON RPC
# 8900 - WebSocket  
# 8001 - Gossip
# 9900 - Faucet
EXPOSE 8899 8900 8001 9900

WORKDIR /solana

# Default command to run test validator
ENTRYPOINT ["solana-test-validator"]
CMD ["--ledger", "/solana/ledger", \
    "--rpc-port", "8899", \
    "--rpc-bind-address", "0.0.0.0", \
    "--dynamic-port-range", "8001-8020", \
    "--gossip-port", "8001", \
    "--faucet-port", "9900", \
    "--log"]
