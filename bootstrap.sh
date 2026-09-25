#!/usr/bin/env bash
#
# Source: https://mailinabox.email/ (https://github.com/mail-in-a-box/mailinabox)
# Updated by cryptopool.builders for crypto use.
#
# This script is intended to be run like this:
#
#   curl -fsSL https://raw.githubusercontent.com/mygiglifeinc-glitch/Multi-Pool-Installer/master/bootstrap.sh | bash
#
# Piping a remote script straight into bash means you are trusting this file
# sight-unseen. If you'd rather review it first:
#
#   curl -fsSL -o bootstrap.sh https://raw.githubusercontent.com/mygiglifeinc-glitch/Multi-Pool-Installer/master/bootstrap.sh
#   less bootstrap.sh
#   bash bootstrap.sh
#
#########################################################

set -euo pipefail

# Branch or tag of multipool_setup to install.
TAG="${TAG:-master}"
REPO_URL="https://github.com/mygiglifeinc-glitch/multipool_setup"
INSTALL_DIR="${HOME}/multipool/install"

# TAG is attacker-controllable (it's read from the environment). Reject
# anything that isn't a plausible git ref name before it ever reaches git,
# so a value like "-b" or "--upload-pack=..." can't be parsed as an option.
if ! [[ "${TAG}" =~ ^[A-Za-z0-9._/-]+$ ]] || [[ "${TAG}" == -* ]]; then
	echo "Error: TAG '${TAG}' is not a valid ref name." >&2
	exit 1
fi

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
		ubuntu:22.04|ubuntu:24.04|ubuntu:26.04)
			;;
		ubuntu:*)
			echo "Warning: Ubuntu ${VERSION_ID:-unknown} is untested. Ubuntu 22.04, 24.04 or 26.04 LTS is recommended." >&2
			;;
		*)
			echo "Warning: this installer targets Ubuntu LTS releases (22.04/24.04/26.04). Detected: ${PRETTY_NAME:-unknown OS}." >&2
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
		-- "${REPO_URL}" "${INSTALL_DIR}" \
		< /dev/null; then
		echo "Error: failed to clone ${REPO_URL} at ${TAG}." >&2
		exit 1
	fi
	echo
fi

# Change directory to it.
cd "${INSTALL_DIR}"

# Make sure the invoking user owns the checkout before we touch it.
${SUDO} chown -R "$(id -u):$(id -g)" "${INSTALL_DIR}"

# Older releases cloned from github.com/cryptopool-builders; always update
# from REPO_URL. TAG may be a branch or a tag, so compare commits rather than
# tag names.
git remote set-url origin "${REPO_URL}"
echo "Checking for MultiPool Installer updates (${TAG}) . . ."
if ! git fetch -q --depth 1 --force origin "${TAG}"; then
	echo "Error: failed to fetch ${TAG} from ${REPO_URL}." >&2
	exit 1
fi
if [ "$(git rev-parse HEAD)" != "$(git rev-parse FETCH_HEAD)" ]; then
	echo "Updating MultiPool Installer to ${TAG} . . ."
	if ! git checkout -q --force FETCH_HEAD; then
		echo "Update failed. Did you modify something in $(pwd)?" >&2
		exit 1
	fi
	echo
fi

# Start setup script.
exec bash "${INSTALL_DIR}/start.sh"
