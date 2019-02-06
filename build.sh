#!/bin/sh

set -e

PRODUCT_URL="https://network.pivotal.io/api/v2/products/pivotal-gpdb"

BUILD="build"
CACHE="$BUILD/cache"

# Show help if requested
if [[ -z "$REFRESH_TOKEN" || " $* " == *' --help '* || " $* " == *' help '* || " $* " == *' -h '* || " $* " == *' -? '* ]]; then
  echo "Usage:" >&2
  echo >&2
  echo "REFRESH_TOKEN='<token>' $0 [--force-build-os] [--keep-files]" >&2
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

source "./helpers/input.sh"
source "./helpers/pivnet.sh"
source "./helpers/pivnet_gpdb.sh"



# Ask user for configuration

echo "Configuring..."

OS="$(request_option "Which base OS?" "centos7")"

GP_VERSIONS="$(get_pivnet_product_releases "$PRODUCT_URL/releases" 5)"
GP_VERSION="$(request_option "Which Greenplum?" "$GP_VERSIONS")"

DISK_SIZE="$(request_input "Enter disk size (MB)" "16000")"
MEMORY_SIZE="$(request_input "Enter RAM memory size (MB)" "8192")"

INSTALL_POSTGIS="$(request_boolean "Install PostGIS?" "n")"
INSTALL_PLR="$(request_boolean "Install PL/R?" "n")"
INSTALL_PLPY="$(request_boolean "Install PL/Python?" "n")"
INSTALL_PLCONTAINER_R="$(request_boolean "Install PL/Container R?" "n")"
INSTALL_PLCONTAINER_PY="$(request_boolean "Install PL/Container Python?" "n")"
INSTALL_MADLIB="$(request_boolean "Install MADlib?" "n")"
#INSTALL_GPTEXT="$(request_boolean "Install GPText?" "n")"
#INSTALL_GPCC="$(request_boolean "Install Command Center?" "n")"



echo "Fetching Greenplum version information..."

GP_VERSION_ID="$(get_pivnet_product_release_id "$PRODUCT_URL/releases" "$GP_VERSION")"
GP_VERSION_DATA="$(get_pivnet_product_release_data "$PRODUCT_URL/releases" "$GP_VERSION_ID")"

echo "Preparing files..."

rm -rf "$BUILD/files" >/dev/null || true
mkdir -p "$BUILD" "$CACHE" "$BUILD/files"
DESCRIPTION_EXTRAS=""

download() {
  URL_FUNC="$1"
  FILE_NAME="$2"
  CACHE_NAME="${FILE_NAME%%.*}-$GP_VERSION_ID.${FILE_NAME#*.}"

  download_pivnet_file "$("$URL_FUNC" "$GP_VERSION_DATA")" "$CACHE/$CACHE_NAME"
  cp "$CACHE/$CACHE_NAME" "$BUILD/files/$FILE_NAME"
}

# Download Greenplum
download get_gpdb_download_url "greenplum.zip"

# Download PostGIS
if [[ "$INSTALL_POSTGIS" == "true" ]]; then
  DESCRIPTION_EXTRAS="$DESCRIPTION_EXTRAS + PostGIS"
  download get_postgis_download_url "postgis.gppkg"
fi

# Download PL/R
if [[ "$INSTALL_PLR" == "true" ]]; then
  DESCRIPTION_EXTRAS="$DESCRIPTION_EXTRAS + PL/R"
  download get_plr_download_url "plr.gppkg"
fi

# Download PL/Container

INSTALL_PLCONTAINER="false"

if [[ "$INSTALL_PLCONTAINER_R" == "true" ]]; then
  download get_plc_r_download_url "plc-r.tar.gz"
  INSTALL_PLCONTAINER="true"
fi

if [[ "$INSTALL_PLCONTAINER_PY" == "true" ]]; then
  download get_plc_py_download_url "plc-py.tar.gz"
  INSTALL_PLCONTAINER="true"
fi

if [[ "$INSTALL_PLCONTAINER" == "true" ]]; then
  DESCRIPTION_EXTRAS="$DESCRIPTION_EXTRAS + PL/Container"
  download get_plcontainer_download_url "plcontainer.gppkg"
fi

# Download MADlib
if [[ "$INSTALL_MADLIB" == "true" ]]; then
  DESCRIPTION_EXTRAS="$DESCRIPTION_EXTRAS + MADlib"
  download get_madlib_download_url "madlib.tar.gz"
fi

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

# Build VM
BASE_IMAGE_OVF=( "$BUILD/$OS-os/"*.ovf )
echo "Building Greenplum $GP_VERSION image (based on $BASE_IMAGE_OVF)..."
rm -rf "$BUILD/$OS-greenplum" || true
packer build \
  -var "base_os=$BASE_IMAGE_OVF" \
  -var "gp_version=$GP_VERSION" \
  -var "memory=$MEMORY_SIZE" \
  -var "description_extras=$DESCRIPTION_EXTRAS" \
  -var "install_postgis=$INSTALL_POSTGIS" \
  -var "install_plr=$INSTALL_PLR" \
  -var "install_plpy=$INSTALL_PLPY" \
  -var "install_plcontainer=$INSTALL_PLCONTAINER" \
  -var "install_plcontainer_r=$INSTALL_PLCONTAINER_R" \
  -var "install_plcontainer_py=$INSTALL_PLCONTAINER_PY" \
  -var "install_madlib=$INSTALL_MADLIB" \
  -var "install_gptext=$INSTALL_GPTEXT" \
  -var "install_gpcc=$INSTALL_GPCC" \
  "packer/$OS-greenplum.json"

OUTPUT_FILE="$BUILD/$OS-greenplum-$GP_VERSION.ova"
mv -f "$BUILD/$OS-greenplum/"*.ova "$OUTPUT_FILE"

echo "Cleaning up..."

rm -r "$BUILD/files"

if [[ " $* " == *' --keep-files '* ]]; then
  echo "Keeping downloaded files for future builds"
else
  echo "Removing downloaded files. To keep, specify --keep-files"
  rm -r "$CACHE"
fi

echo
echo "Build complete; generated $OUTPUT_FILE"

cd - >/dev/null
