# Declarative Unity Development Environment on NixOS via Distrobox

This directory manages a declarative, sandbox-compatible Unity Hub and Unity Editor development environment on NixOS using a Distrobox (Ubuntu 22.04 LTS) container.

---

## 1. Why Distrobox? (Architecture)

The native NixOS `unityhub` package relies on FHS emulation (bubblewrap). While Unity Hub itself runs, the Unity Editor spawns build processes and external scripts (like Burst compiler JIT compilation) that run outside the initial sandbox. These sub-processes often fail to link against host system libraries (e.g., GLIBC, OpenGL, Vulkan), leading to crashes during script compilation.

By using **Distrobox** with an Ubuntu 22.04 LTS image, we provide a complete, officially supported Ubuntu FHS environment. Both Unity Hub and the Unity Editor run inside this container, sharing the host's networking, X11/Wayland display, and GPU acceleration.

---

## 2. Key Challenges & Solutions

To make this containerized setup integrate seamlessly with NixOS and function without network or launching issues, several custom workarounds are implemented:

### Host-to-Container GIO & SSL Variable Conflicts
*   **Problem:** Host environment variables like `GIO_EXTRA_MODULES` (pointing to dconf/gvfs in the Nix store) and NixOS-specific `SSL_CERT_FILE` variables are inherited by the container. The container's glibc (2.35) crashes or fails to load host modules compiled against newer glibc versions, and OpenSSL fails to locate valid certificates.
*   **Solution:** [launcher.sh](launcher.sh) unsets `GIO_EXTRA_MODULES`, `SSL_CERT_FILE`, `NIX_SSL_CERT_FILE`, `CURL_CA_BUNDLE`, `SSL_CERT_DIR`, and `NIX_SSL_CERT_DIR` before entering the container, forcing Unity to use native Ubuntu libraries and certificates.

### Browser Sandbox Escape (Deep-linking for Sign-in)
*   **Problem:** Web browsers (e.g., Zen Browser) running in their own sandboxed user namespaces cannot spawn container processes or escalate privileges inside the container via `su` when trying to handle the `unityhub://` protocol.
*   **Solution:** The desktop entry launches the hub via `systemd-run --user`. This delegates the execution back to the user's host systemd session, effectively escaping the browser's sandbox.

### SSL/TLS Handshake Timeout (Failed to call Unity ID to get auth code)
*   **Problem:** Modern .NET Sockets (CoreCLR used by Unity Editor 6) dynamically loads `libssl.so.1.1` via P/Invoke for TLS handshakes. Ubuntu 22.04 and NixOS host only provide `libssl.so.3`. This discrepancy caused the Editor's HTTPS connections to services like `api.unity.com` and `services.unity.com` to hang/timeout right after establishing the TCP connection (`ESTABLISHED`), breaking UPM and Asset Store OAuth.
*   **Solution:** The container's `pre_init_hooks` downloads and installs the official `libssl1.1` deb package directly into the container using `curl` and `dpkg`.

### Distrobox INI Parser Constraints
*   **Problem:** The simplified INI parser in `distrobox-assemble` misinterprets square brackets `[` `]` inside keys (like `[1/5]` or `[arch=amd64]`) as new section boundaries, causing the rest of the script to be discarded.
*   **Solution:** Raw brackets are completely avoided in [distrobox.ini](distrobox.ini). For the APT repository line where brackets are required, we write them dynamically using `printf` with hex escapes (`\x5b` and `\x5d`).

### Persistent `xdg-open` Redirection
*   **Problem:** Distrobox periodically regenerates `/usr/bin/xdg-open` inside the container, breaking browser redirects for authentication.
*   **Solution:** [launcher.sh](launcher.sh) features a self-healing block that checks and replaces `/usr/bin/xdg-open` with a symlink to `/usr/bin/distrobox-host-exec` every time the launcher is run.

---

## 3. Maintenance & Troubleshooting

### Rebuilding the Container
If you modify [distrobox.ini](distrobox.ini) (e.g., adding packages or updating hooks):
1.  Apply the NixOS changes:
    ```bash
    sudo nixos-rebuild switch --flake .#BrokenPC
    ```
2.  Remove the existing container:
    ```bash
    distrobox rm -f unity
    ```
3.  Launch Unity Hub (this triggers the automatic recreate process):
    ```bash
    unityhub
    ```

### Verifying Symlinks
Inside the container, ensure `xdg-open` correctly redirects to the host:
```bash
distrobox enter unity -- ls -la /usr/bin/xdg-open
# Should return: /usr/bin/xdg-open -> /usr/bin/distrobox-host-exec
```
