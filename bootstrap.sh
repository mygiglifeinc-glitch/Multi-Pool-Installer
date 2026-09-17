#!/usr/bin/env bash
#
# Source: https://mailinabox.email/ (https://github.com/mail-in-a-box/mailinabox)
# Updated by cryptopool.builders for crypto use.
#
# This script is intended to be run like this:
#
#   curl -fsSL https://raw.githubusercontent.com/cryptopool-builders/Multi-Pool-Installer/master/bootstrap.sh | bash
#
# Piping a remote script straight into bash means you are trusting this file
# sight-unseen. If you'd rather review it first:
#
#   curl -fsSL -o bootstrap.sh https://raw.githubusercontent.com/cryptopool-builders/Multi-Pool-Installer/master/bootstrap.sh
#   less bootstrap.sh
#   bash bootstrap.sh
#
#########################################################

set -euo pipefail

TAG="${TAG:-v2.55}"
REPO_URL="https://github.com/cryptopool-builders/multipool_setup"
INSTALL_DIR="${HOME}/multipool/install"

if [ -z "${HOME:-}" ]; then
	echo "Error: \$HOME is not set; cannot determine the install directory." >&2
	exit 1
fi

# Only escalate with sudo when we're not already root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
fi

# Warn (non-fatally) if this doesn't look like a supported Ubuntu LTS release.
if [ -r /etc/os-release ]; then
	# shellcheck source=/dev/null
	. /etc/os-release
	case "${ID:-}:${VERSION_ID:-}" in
		ubuntu:22.04|ubuntu:24.04)
			;;
		ubuntu:*)
			echo "Warning: Ubuntu ${VERSION_ID:-unknown} is untested. Ubuntu 22.04 LTS or 24.04 LTS is recommended." >&2
			;;
		*)
			echo "Warning: this installer targets Ubuntu LTS releases (22.04/24.04). Detected: ${PRETTY_NAME:-unknown OS}." >&2
			;;
	esac
fi

# Clone the MultiPool repository if it doesn't exist.
if [ ! -d "${INSTALL_DIR}" ]; then
	if ! command -v git >/dev/null 2>&1; then
		echo "Installing git . . ."
		${SUDO} apt-get -q -q update
		${SUDO} env DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git < /dev/null
		echo
	fi

	echo "Downloading MultiPool Installer ${TAG} . . ."
	if ! git clone \
		-b "${TAG}" --depth 1 \
		"${REPO_URL}" \
		"${INSTALL_DIR}" \
		< /dev/null; then
		echo "Error: failed to clone ${REPO_URL} at tag ${TAG}." >&2
		exit 1
	fi
	echo
fi

# Change directory to it.
cd "${INSTALL_DIR}"

# Make sure the invoking user owns the checkout before we touch it.
${SUDO} chown -R "$(id -u):$(id -g)" "${INSTALL_DIR}/.git"

CURRENT_TAG="$(git describe --tags)"
if [ "${TAG}" != "${CURRENT_TAG}" ]; then
	echo "Updating MultiPool Installer to ${TAG} . . ."
	git fetch --depth 1 --force --prune origin tag "${TAG}"
	if ! git checkout -q "${TAG}"; then
		echo "Update failed. Did you modify something in $(pwd)?" >&2
		exit 1
	fi
	echo
fi

# Start setup script.
exec bash "${INSTALL_DIR}/start.sh"
