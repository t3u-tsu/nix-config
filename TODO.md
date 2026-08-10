# Repository Improvement TODO

Outstanding tasks to improve the maintainability and extensibility of this
NixOS configuration repository and the availability of the multi-site
infrastructure. (Completed tasks are removed from the list rather than kept in
history.)

- **Reduce build load on remote servers (shosoin-tan / torii-chan)**: offload
  evaluation/builds to the main machine (BrokenPC) or set up remote builds; also
  slim down the shell setup to prevent resource starvation (D-Bus timeouts, etc.)
- **Introduce a cache server (Attic, etc.)**: share build caches between hosts;
  operate a private cache for packages with license restrictions to lower the
  build load on servers.
- **Decide on a deployment strategy (deploy-rs or cache-based pull)**: settle on
  an optimal deployment method that avoids heavy builds on remote servers
  (`comin` was removed on 2026-08-09).
- **Introduce a failover VPS**: when the connection to torii-chan is lost, use
  the API of a metered cheap VPS (Vultr, etc.) to dynamically switch the
  connection target via CNAME.
- **Introduce an onion-routing (Tor) SSH backdoor**: as a last resort, ensure a
  remote SSH route when the global IP / VPN is completely down and torii-chan
  is unreachable.
- **Build a BrokenPC backup server**: automatically and safely back up BrokenPC
  data (e.g. to shosoin-tan).
- **Host a local LLM server using GPU resources**: host a local LLM server on
  surplus GPUs of kagutsuchi-sama / shosoin-tan and make it available via API etc.
