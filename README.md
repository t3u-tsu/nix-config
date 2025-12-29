# NixOS on Orange Pi Zero3 (torii-chan)

This repository contains the NixOS configuration for an Orange Pi Zero3, codenamed `torii-chan`. It supports building an initial SD card image and deploying updates to a running system, transitioning from an SD-only setup to an HDD-root setup.

## Configurations

The `flake.nix` exposes two main configurations:

| Configuration | Purpose | Description |
| :--- | :--- | :--- |
| `torii-chan-sd` | **Initial Setup** | Builds a complete SD card image containing the installer/system. Use this for the first boot. |
| `torii-chan` | **Production / HDD** | The target configuration for the running system. Configured to mount the root filesystem `/` from an external HDD (USB-SATA) and `/boot` from the SD card. |

## Prerequisites

- **Nix** with Flakes enabled (`experimental-features = nix-command flakes`).
- **Orange Pi Zero3** (1GB/1.5GB/2GB/4GB RAM model).
- **microSD Card** (16GB+ recommended).
- **USB-SATA Adapter & HDD/SSD** (for production storage).

---

## 🚀 Setup Guide

### Phase 0: Management PC Setup (WireGuard)

**Crucial:** In production, SSH access is restricted to the WireGuard VPN. You must set up your management PC as a WireGuard peer.

1.  **Generate Keys:**
    ```bash
    wg genkey | tee client_private.key | wg pubkey > client_public.key
    ```
2.  **Add Peer to Server Config:**
    Add the content of `client_public.key` to `hosts/torii-chan/services/wireguard.nix` (already done for initial setup).
3.  **Configure Client:**
    Create `/etc/wireguard/torii-chan.conf`:
    ```ini
    [Interface]
    PrivateKey = <YOUR_PRIVATE_KEY>
    Address = 10.0.0.2/32
    
    [Peer]
    PublicKey = <SERVER_PUBLIC_KEY_FROM_SOPS>
    Endpoint = torii-chan.t3u.uk:51820
    AllowedIPs = 10.0.0.0/24
    PersistentKeepalive = 25
    ```

### Phase 1: Build & Flash SD Image

1.  **Build the SD Image:**
    ```bash
    nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
    ```
    The output will be in `result/sd-image/nixos-image-sd-card-....img`.

2.  **Flash to SD Card:**
    Replace `/dev/sdX` with your actual SD card device.
    ```bash
    sudo dd if=result/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
    ```

3.  **Boot & Network:**
    - Insert the SD card and power on.
    - The system is configured with a static IP: `192.168.0.128` (check `hosts/torii-chan/configuration.nix`).
    - SSH is enabled on port `42540`.

4.  **Install Secrets Key:**
    - **Note:** On the initial SD card boot, `sudo` is configured to run **without a password**. This is intentional to allow you to set up the keys before the password hashes can be decrypted.
    - Since `sops-nix` is used, you must manually place the decryption key on the device.
    - Create the directory and file:
      ```bash
      # On the Orange Pi (sudo will not ask for password)
      sudo mkdir -p /var/lib/sops-nix
      sudo vi /var/lib/sops-nix/key.txt
      ```
    - Paste your age secret key into `key.txt` and set permissions:
      ```bash
      sudo chmod 600 /var/lib/sops-nix/key.txt
      ```
    - **After Deployment:** Once you deploy the production configuration (Phase 2), `sudo` will revert to requiring a password.

### Phase 1.5: Update on SD Card (Optional)

If you want to update the system configuration (e.g., add packages, configure WireGuard) *before* migrating to HDD, use the `torii-chan-sd-live` configuration.

**Note:** The initial SD image allows root login via SSH to facilitate this first deployment. Use `root@...` to avoid signature verification issues.

```bash
nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128
```

### Phase 2: Migrate to HDD (Root on HDD)

To extend SD card life, we move the root filesystem to an HDD.

1.  **Prepare the HDD:**
    - Connect the USB HDD to the Orange Pi.
    - Create an ext4 partition and label it `NIXOS_HDD`.
      ```bash
      # Example (BE CAREFUL):
      sudo mkfs.ext4 -L NIXOS_HDD /dev/sda1
      ```

2.  **Copy System:**
    - Mount the HDD and copy the current root filesystem.
      ```bash
      sudo mount /dev/disk/by-label/NIXOS_HDD /mnt
      sudo rsync -axHAWXS --numeric-ids --info=progress2 / /mnt/
      ```
      *(Note: Exclude pseudo-filesystems like /proc, /sys, /dev if simply copying root, but `rsync -x` handles one filesystem boundary. Ensure `/nix` and `/boot` context is understood. Ideally, just copying `/nix`, `/etc`, `/var`, `/home`, `/root` is sufficient if the config handles the rest.)*

3.  **Deploy HDD Configuration:**
    - Now that the data is on the HDD, switch the configuration to use it.
    - Run this from your **development machine**:
      ```bash
      nixos-rebuild switch --flake .#torii-chan --target-host t3u@192.168.0.128 --use-remote-sudo
      ```
    - This applies the configuration from `hosts/torii-chan/fs-hdd.nix`, mounting `NIXOS_HDD` as `/` and the SD card partition as `/boot`.

4.  **Reboot:**
    ```bash
    ssh -p 42540 t3u@192.168.0.128 "sudo reboot"
    ```
    - The system should now boot with the HDD as root.

---

## 🔐 Security & Access Control

### SSH Access
- **Port:** `22` (Standard)
- **Initial Setup (SD Image):** Open on all interfaces.
- **Production (HDD Config):** Restricted to **WireGuard VPN Interface (`wg0`) ONLY**.
  - **WARNING:** Before deploying the production config (`torii-chan`), you **MUST** add your WireGuard peer configuration to `hosts/torii-chan/services/wireguard.nix`.
  - If you deploy without a working VPN connection, you will be locked out of SSH.

## 🔐 Secrets Management (SOPS)

- **Edit Secrets:**
  ```bash
  nix shell nixpkgs#sops -c sops secrets/secrets.yaml
  ```
- **Key Location:** `secrets/.sops.yaml` defines the public keys.
- **Node Setup:** The secret key must be placed at `/var/lib/sops-nix/key.txt` on the target machine.
- **Troubleshooting:**
  - If password hashes are not reflecting in `/etc/shadow`, ensure `users.mutableUsers = false` is set.
  - Check `/run/secrets/` and `/run/secrets-for-users/` for decrypted files.
  - Verify `sops-nix` activation logs: `journalctl -t nixos-activation-script`.

## 🛠 Troubleshooting

- **U-Boot / BL31 Issues:** The flake uses an overlay to inject `BL31` firmware into the U-Boot build process to satisfy `binman`. If build fails, check `flake.nix` overlays.
- **SSH Access:** SSH runs on port `22`. Note the access restrictions in production mode.

---

## ⚠️ CRITICAL: Before You Deploy Production Config

To prevent being locked out of the system (since SSH is blocked on LAN in production):

1.  **Add Your WireGuard Peer:**
    Edit `hosts/torii-chan/services/wireguard.nix` and add your client's public key.
    ```nix
    peers = [
      {
        publicKey = "YOUR_CLIENT_PUBLIC_KEY";
        allowedIPs = [ "10.0.0.2/32" ];
      }
    ];
    ```
    *Without this, you cannot connect to the VPN, and thus cannot access SSH.*

2.  **Verify Secrets:**
    Ensure `secrets/secrets.yaml` contains:
    - `cloudflare_api_env` (for DDNS)
    - `torii_chan_wireguard_private_key` (for Server)

3.  **Prepare HDD:**
    Ensure the HDD is formatted with label `NIXOS_HDD` and data is copied from the SD card.
