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

### Phase 1: Build & Flash SD Image

1.  **Build the SD Image:**
    ```bash
    nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
    ```
    The output will be in `result/sd-image/nixos-image-sd-card-....img.zst`.

2.  **Flash to SD Card:**
    Replace `/dev/sdX` with your actual SD card device.
    ```bash
    zstdcat result/sd-image/nixos-image-sd-card-*.img.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
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

## 🔐 Secrets Management (SOPS)

- **Edit Secrets:**
  ```bash
  nix shell nixpkgs#sops -c sops secrets/secrets.yaml
  ```
- **Key Location:** `secrets/.sops.yaml` defines the public keys.
- **Recovery:** If you lose the `key.txt`, you must regenerate keys and re-encrypt `secrets.yaml` (see `GEMINI.md` history).

## 🛠 Troubleshooting

- **U-Boot / BL31 Issues:** The flake uses an overlay to inject `BL31` firmware into the U-Boot build process to satisfy `binman`. If build fails, check `flake.nix` overlays.
- **SSH Access:** SSH runs on port `42540`, not 22.
