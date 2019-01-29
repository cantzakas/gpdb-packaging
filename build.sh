#!/bin/sh

set -e

PRODUCT_URL="https://network.pivotal.io/api/v2/products/pivotal-gpdb"

BUILD="build"
OS="centos7"
#OS="ubuntu"

# Show help if requested
if [[ -z "$REFRESH_TOKEN" ]] || [[ " $* " == *' --help '* ]] || [[ " $* " == *' help '* ]] || [[ " $* " == *' -h '* ]] || [[ " $* " == *' -? '* ]]; then
  echo "Usage:" >&2
  echo >&2
  echo "REFRESH_TOKEN='<token>' $0 [--force-download] [--force-build-os]" >&2
  echo >&2
  exit
fi

# Show dependencies if not available
if ! which packer >/dev/null || ! which virtualbox >/dev/null || ! which jq >/dev/null; then
  echo "Need to install packer, virtualbox and jq!" >&2
  echo "  brew cask install virtualbox" >&2
  echo "  brew install packer jq" >&2
  echo >&2
  exit 1
fi

cd "$(dirname "$0")"

source "./helpers.sh"

# Ask which Greenplum

echo "Negotiating token to download Greenplum from Pivotal Network..."
ACCESS_TOKEN="$(get_access_token "$REFRESH_TOKEN")"

GP_VERSIONS="$(get_versions "$PRODUCT_URL/releases" 5)"
echo "Which Greenplum?"
i=1
for v in $GP_VERSIONS; do
  echo "[$i] $v"
  (( i ++ ))
done
CHOSEN_GP="$(request_input "Enter number" "1")"

GP_VERSION="$(echo "$GP_VERSIONS" | head -n"$CHOSEN_GP" | tail -n1)"
echo "Using version $GP_VERSION"

GP_VERSION_ID="$(get_version_id "$PRODUCT_URL/releases" "$GP_VERSION")"
GP_DOWNLOAD_URL="$(get_download_url "$PRODUCT_URL/releases/$GP_VERSION_ID")"

DISK_SIZE="$(request_input "Enter disk size (MB)" "10000")"
MEMORY_SIZE="$(request_input "Enter RAM memory size (MB)" "8192")"

mkdir -p "$BUILD"

# Download Greenplum
GP_ZIP="$BUILD/greenplum-$GP_VERSION_ID.zip"
if [[ " $* " == *' --force-download '* ]] || ! test -f "$GP_ZIP"; then

  echo "Downloading Greenplum using access token: $ACCESS_TOKEN"
  curl -H "Authorization: Bearer $ACCESS_TOKEN" -L -o "$GP_ZIP" "$GP_DOWNLOAD_URL"
else
  echo "Using existing greenplum.zip download (specify --force-download to download latest)"
fi

if [[ "$(head -c1 "$GP_ZIP")" == '{' ]]; then
  echo "Failed to download greenplum.zip. Error:" >&2
  cat "$GP_ZIP" >&2
  echo >&2;
  rm "$GP_ZIP"
  exit 1
fi

# Fancy sed/cut regex to extract version number from an output like:
# 280341880  01-16-2019 02:47   greenplum-db-5.16.0-rhel7-x86_64.bin
GP_VERSION="$(unzip -qql "$GP_ZIP" | head -n1 | sed -E 's/(([0-9]+\.)+[0-9]+).*/|\1/' | cut -d'|' -f2)"

# Build base OS
if [[ " $* " == *' --force-build-os '* ]] || ! test -f "$BUILD/$OS-os/"*.ovf; then
  echo "Building base OS image..."
  rm -rf "$BUILD/$OS-os" || true
  packer build \
    -var "disk_size=${DISK_SIZE}" \
    "packer/$OS-os.json"
else
  echo "Using existing $OS image (specify --force-build-os to build fresh)"
fi

OUTPUT_FILE="$BUILD/$OS-greenplum-$GP_VERSION.ova"

# Build VM
BASE_IMAGE_OVF=( "$BUILD/$OS-os/"*.ovf )
echo "Building Greenplum $GP_VERSION image (based on $BASE_IMAGE_OVF)..."
rm -rf "$BUILD/$OS-greenplum" || true
packer build \
  -var "base_os=$BASE_IMAGE_OVF" \
  -var "greenplum_zip=$GP_ZIP" \
  -var "gp_version=$GP_VERSION" \
  -var "memory=$MEMORY_SIZE" \
  "packer/$OS-greenplum.json"

mv -f "$BUILD/$OS-greenplum/"*.ova "$OUTPUT_FILE"

if [[ " $* " == *' --remove-gpdb-zip '* ]]; then
  echo "Removing $GP_ZIP"
  rm "$GP_ZIP"
else
  echo "Keeping $GP_ZIP for future builds. To remove, specify --remove-gpdb-zip"
fi

echo
echo "Build complete; generated $OUTPUT_FILE"

cd - >/dev/null
