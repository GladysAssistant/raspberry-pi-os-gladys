#!/bin/bash
# Pulls latest Gladys/Watchtower images and starts containers on first boot.
set -euo pipefail

FLAG="/var/lib/gladysassistant/.firstboot-complete"
SETUP_IMAGE="gladysassistant/gladys-setup-in-progress:latest"
GLADYS_IMAGE="gladysassistant/gladys:v4"
WATCHTOWER_IMAGE="nickfedor/watchtower:latest"
SETUP_CONTAINER="gladys-setup-in-progress"

mkdir -p /var/lib/gladysassistant

if [ -f "${FLAG}" ]; then
	exit 0
fi

stop_setup_container() {
	docker rm -f "${SETUP_CONTAINER}" 2>/dev/null || true
}

start_setup_container() {
	echo "Gladys first boot: starting setup page..."
	docker rm -f "${SETUP_CONTAINER}" 2>/dev/null || true
	docker run -d \
		--name "${SETUP_CONTAINER}" \
		--network=host \
		"${SETUP_IMAGE}"
}

# The Pi has no RTC: on first boot the clock holds the image build date, and
# TLS to the Docker registry fails until NTP steps it. Best-effort wait so a
# blocked NTP port cannot hang first boot forever.
echo "Gladys first boot: waiting for time synchronization..."
for _ in $(seq 1 60); do
	if [ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = "yes" ]; then
		echo "Gladys first boot: clock synchronized ($(date -u))."
		break
	fi
	sleep 2
done

echo "Gladys first boot: waiting for Docker..."
until docker info >/dev/null 2>&1; do
	sleep 2
done

echo "Gladys first boot: pulling setup page image..."
docker pull "${SETUP_IMAGE}"
start_setup_container

echo "Gladys first boot: pulling Gladys image (setup page available on port 80)..."
docker pull "${GLADYS_IMAGE}"

echo "Gladys first boot: pulling Watchtower image..."
docker pull "${WATCHTOWER_IMAGE}"
stop_setup_container

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
	"${GLADYS_IMAGE}"

echo "Gladys first boot: starting Watchtower..."
docker rm -f watchtower 2>/dev/null || true
docker run -d \
	--name watchtower \
	--restart=always \
	-v /var/run/docker.sock:/var/run/docker.sock \
	"${WATCHTOWER_IMAGE}" \
	--cleanup --include-restarting

touch "${FLAG}"
systemctl disable gladys-firstboot.service >/dev/null 2>&1 || true

echo "Gladys first boot: complete. Access Gladys at http://$(hostname -I | awk '{print $1}')"
