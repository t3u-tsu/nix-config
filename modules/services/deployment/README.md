# Deployment Module (comin)

This module uses `comin`, a community-standard deployment tool, to manage the automatic updates of all hosts.

## Design Philosophy

Previously, we used a centralized Update Hub server running on `torii-chan` to instruct clients to update. In Phase 7, we migrated to a **Pull-based (Decentralized)** architecture.

- **No Central Server Needed**: Each node (host) independently keeps its own configuration up-to-date.
- **Improved Security**: The risk of remote command execution is eliminated, enabling safer provisioning.
- **Stability**: Utilizing a mature community tool reduces maintenance costs.

## Specifications

- **Polling Interval**: Every 5 minutes (300 seconds)
- **Target Branch**: `main`
- **Behavior**: If there is an update to the latest `main` branch in the repository, it automatically executes `nixos-rebuild switch` to synchronize the state.
