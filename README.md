# Gladys Assistant — Raspberry Pi OS image

Automated build of a **Raspberry Pi OS Lite 64-bit** image with [Gladys Assistant](https://gladysassistant.com/) and [Watchtower](https://github.com/nickfedor/watchtower).

Images are built on GitHub Actions with [pi-gen](https://github.com/RPi-Distro/pi-gen) and [pi-gen-action](https://github.com/usimd/pi-gen-action).

## What is included

| Setting | Value |
|--------|--------|
| Base OS | Raspberry Pi OS Lite, Debian Trixie, arm64 |
| Hostname | `gladys` |
| User / password | `pi` / `raspberry` |
| SSH | Enabled |
| Timezone (Gladys container) | UTC |
| Docker | Pre-installed |
| Gladys | Started on **first boot** (`gladysassistant/gladys:v4`) |
| Watchtower | Started on **first boot** (auto-updates Gladys) |

Gladys and Watchtower are **not** baked into the image. On first boot, the system pulls the latest images from Docker Hub so each flash gets up-to-date containers.

## Flash the image

1. Download the latest `.img.xz` from the repository **GitHub Releases** page.
2. Flash with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) or:

   ```bash
   xz -dk gladys-assistant-*.img.xz
   sudo dd if=gladys-assistant-*.img of=/dev/sdX bs=4M conv=fsync status=progress
   ```

3. Boot the Pi on your LAN (Ethernet or Wi‑Fi configured as usual on Raspberry Pi OS).
4. Wait a few minutes on first boot while Docker pulls images and starts Gladys.
5. Open `http://<pi-ip-address>/` in a browser on the same network.

Verify first-boot progress:

```bash
ssh pi@gladys.local
sudo journalctl -u gladys-firstboot.service -f
docker ps
```

## Supported hardware

Raspberry Pi **3**, **4**, **5**, and **Zero 2 W** (64-bit capable boards).

## Security notice

The image ships with default credentials (`pi` / `raspberry`) and SSH enabled, matching stock Raspberry Pi OS defaults. **Change the password and consider SSH keys before exposing the device to untrusted networks.**

## Repository layout

```
stage2-gladys/          # Custom pi-gen stage (Docker + first-boot)
.github/workflows/      # CI build and release
```

## Build locally (optional)

Requires a Debian-based host with enough disk space (~30 GB) and Docker:

```bash
git clone https://github.com/RPi-Distro/pi-gen.git --branch arm64 --depth 1
cd pi-gen
cp -r /path/to/raspberry-pi-gladys/stage2-gladys .
# Configure (see pi-gen-action inputs in .github/workflows/build-image.yml)
./build-docker.sh
```

Local builds are mainly for debugging; production images are produced by GitHub Actions.

## Automation

| Trigger | Action |
|---------|--------|
| Push to `main` | Build + artifact + GitHub Release |
| Weekly (Monday 03:00 UTC) | Rebuild with latest Raspberry Pi OS base |
| Manual (`workflow_dispatch`) | On-demand build |

## License

MIT — see [LICENSE](LICENSE).
