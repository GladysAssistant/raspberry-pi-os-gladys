#!/bin/bash
# Pulls latest Gladys/Watchtower images and starts containers on first boot.
set -euo pipefail

FLAG="/var/lib/gladysassistant/.firstboot-complete"
mkdir -p /var/lib/gladysassistant

if [ -f "${FLAG}" ]; then
	exit 0
fi

echo "Gladys first boot: waiting for Docker..."
until docker info >/dev/null 2>&1; do
	sleep 2
done

echo "Gladys first boot: pulling images..."
docker pull gladysassistant/gladys:v4
docker pull nickfedor/watchtower:latest

echo "Gladys first boot: starting Gladys..."
docker rm -f gladys 2>/dev/null || true
docker run -d \
	--log-driver json-file \
	--log-opt max-size=10m \
	--cgroupns=host \
	--restart=always \
	--privileged \
	--network=host \
	--name gladys \
	-e NODE_ENV=production \
	-e SERVER_PORT=80 \
	-e TZ=UTC \
	-e SQLITE_FILE_PATH=/var/lib/gladysassistant/gladys-production.db \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v /var/lib/gladysassistant:/var/lib/gladysassistant \
	-v /dev:/dev \
	-v /run/udev:/run/udev:ro \
	gladysassistant/gladys:v4

echo "Gladys first boot: starting Watchtower..."
docker rm -f watchtower 2>/dev/null || true
docker run -d \
	--name watchtower \
	--restart=always \
	-v /var/run/docker.sock:/var/run/docker.sock \
	nickfedor/watchtower:latest \
	--cleanup --include-restarting

touch "${FLAG}"
systemctl disable gladys-firstboot.service >/dev/null 2>&1 || true

echo "Gladys first boot: complete. Access Gladys at http://$(hostname -I | awk '{print $1}')"
