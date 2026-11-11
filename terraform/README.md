# Cloud Infrastructure (`terraform/`)

Infrastructure as Code managed via [OpenTofu](https://opentofu.org/) (`tofu`) for cloud failover infrastructure.

## Resources Overview

| Resource | Terraform Name | Description |
| :--- | :--- | :--- |
| Compute & Network | `tofu` configurations | Provisions failover gateway infrastructure. |

## CLI Operations

```bash
tofu init      # Install provider plugins
tofu validate  # Validate syntax
tofu plan      # Inspect planned infrastructure changes
tofu apply     # Provision infrastructure (starts billing; requires user approval)
tofu destroy   # Tear down infrastructure (requires user approval)
```

> [!WARNING]
> Running `tofu apply` may incur cloud charges. State is stored locally in `terraform.tfstate` (excluded by [.gitignore](.gitignore)).

## References

- Google Cloud failover & recovery runbook: [docs/operations/gcp-failover.md](../docs/operations/gcp-failover.md)
- Network topology: [docs/architecture/network-topology.md](../docs/architecture/network-topology.md)
