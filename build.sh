#!/bin/bash
#
# Builds a package from a SlackBuilds repository and places it in the
# Slackware repository.
#
# Make sure to set the $REPOSROOT to the location of the Slackware
# repository and to set SLACKBUILDS to the location of the SlackBuilds
# repository. Both of these variables should be set in the genreprc
# file.
#
# Example:
#   $ ./build.sh system/rxvt-unicode

set -euo pipefail

readonly USERDEFS=${USERDEFS:-genreprc}
if [ -f $USERDEFS ]; then
  echo "Importing user defaults."
  . $USERDEFS
fi

if [[ -z "${REPOSROOT}" ]]; then
  echo "missing REPOSROOT in ${USERDEFS} configuration file."
  exit 1
fi

if [[ -z "${SLACKBUILDS}" ]]; then
  echo "missing SLACKBUILDS in ${USERDEFS} configuration file."
  exit 1
fi

# Check package.
PACKAGE="$1"
if [[ -z "${PACKAGE}" ]]; then
  echo missing package as first argument, e.g., libraries/libAfterImage
  exit 1
fi

source "${SLACKBUILDS}/${PACKAGE}/$(basename "${PACKAGE}").info"

# Check configuration.
if [[ -z "${PRGNAM}" ]]; then
  echo failed to determine package name
  exit 1
fi

if [[ -z "${VERSION}" ]]; then
  echo failed to determine package version
  exit 1
fi

# Check package download URL.
URL="${DOWNLOAD_x86_64}"
if [[ -z "${URL}" ]]; then
  URL="${DOWNLOAD}"
fi
if [[ -z "${URL}" ]]; then
  echo failed to determine package download URL
  exit 1
fi

echo Package: "${PRGNAM}-${VERSION}"
echo URL: "${URL}"

# Check package MD5 checksum.
MD5="${MD5SUM_x86_64}"
if [[ -z "${MD5}" ]]; then
  MD5="${MD5SUM}"
fi
if [[ -z "${MD5}" ]]; then
  echo failed to determine package MD5 expected checksum
  exit 1
fi

# Download source.
readonly DOWNLOAD_FILE="${SLACKBUILDS}/${PACKAGE}/$(basename "${URL}")"
wget -O - "${URL}" > "${DOWNLOAD_FILE}" 2> /dev/null

# Check MD5 checksum of the downloaded source.
readonly ACTUAL_MD5=$(md5sum "${DOWNLOAD_FILE}" | cut -d " " -f 1)
if [[ "${ACTUAL_MD5}" != "${MD5}" ]]; then
  echo MD5 checksum does not match, "${ACTUAL_MD5}" vs. "${MD5}"
  exit 1
fi

echo MD5 checksum OK

# Prompt for confirmation.
read -p "Are you sure you want to build the package (y/n)? " choice
case "$choice" in
  y|Y )
    ;;
  * )
    exit 1 ;;
esac

# Make sure destination directory exists.
readonly REPO_DIR="${REPOSROOT}/${PRGNAM}/"
mkdir -p "${REPO_DIR}"

# Build package.
pushd . &> /dev/null
cd "${SLACKBUILDS}/${PACKAGE}"
chmod +x "./${PRGNAM}.SlackBuild"
export MAKEFLAGS=-j8
sudo env OUTPUT="${REPO_DIR}" "./${PRGNAM}.SlackBuild"
chmod -x "./${PRGNAM}.SlackBuild"
popd &> /dev/null

# Set permissions on package file.
readonly PACKAGE_FILE="${REPO_DIR}/${PRGNAM}-${VERSION}-*.t?z"
sudo chown "${USER}:users" ${PACKAGE_FILE}

echo Do not forget to run ./gen_repos_files.sh to update the repository.
