#!/bin/bash

set -e

PRODUCT_URL="https://network.pivotal.io/api/v2/products/pivotal-gpdb"

BUILD="build"
CACHE="$BUILD/cache"

# Show help if requested
if [[ -z "$REFRESH_TOKEN" || " $* " == *' --help '* || " $* " == *' help '* || " $* " == *' -h '* || " $* " == *' -? '* ]]; then
  echo "Usage:" >&2
  echo >&2
  echo "REFRESH_TOKEN='<token>' $0 [--keep-files]" >&2
  echo >&2
  exit
fi

# Show dependencies if not available
if ! which packer >/dev/null || ! which virtualbox >/dev/null || ! which jq >/dev/null; then
  echo "Need to install packer and jq!" >&2
  echo "  brew install packer jq" >&2
  echo >&2
  exit 1
fi

# Detect installed virtual machine managers

VM_MANAGERS=""
if which virtualbox >/dev/null; then
  VM_MANAGERS+="virtualbox"$'\n'
fi

if which vmnet-cli >/dev/null; then
  VM_MANAGERS+="vmware"$'\n'
fi

if [[ -z "$VM_MANAGERS" ]]; then
  echo "Need to install a virtual machine manager, e.g.:" >&2
  echo "  brew cask install virtualbox" >&2
  echo "  (see README.md for more)" >&2
  echo >&2
  exit 1
fi


cd "$(dirname "$0")"

source "./helpers/input.sh"
source "./helpers/pivnet.sh"
source "./helpers/pivnet_gpdb.sh"



# Ask user for configuration

echo "Configuring..."

VM_MANAGER="$(request_option "Which VM management tool?" "$VM_MANAGERS")"

if [[ "$VM_MANAGER" == "virtualbox" ]]; then
  VM_EXT="ovf"
  OUT_EXT="ova"
elif [[ "$VM_MANAGER" == "vmware" ]]; then
  VM_EXT="vmx"
  OUT_EXT="vmx"
else
  echo "Unknown VM manager!" >&2
  exit 1
fi

OS="$(request_option "Which base OS?" "centos7")"

BASE_IMAGE_DIR="$BUILD/$OS-os-$VM_MANAGER"
BUILD_OS="true"
if test -f "$BASE_IMAGE_DIR/"*."$VM_EXT"; then
  BUILD_OS="$(request_boolean "Found existing base OS image for $OS on $VM_MANAGER - rebuild?" "n")"
fi

INCLUDE_EULA="$(request_boolean "Auto-accept and include Pivotal Network EULA in VM?" "y")"

GP_VERSIONS="$(get_pivnet_product_releases "$PRODUCT_URL/releases" 5)"
GP_VERSION="$(request_option "Which Greenplum?" "$GP_VERSIONS")"

if [[ "$BUILD_OS" == "true" ]]; then
  DISK_SIZE="$(request_input "Enter disk size (MB)" "16000")"
fi

MEMORY_SIZE="$(request_input "Enter RAM memory size (MB)" "8192")"

INSTALL_POSTGIS="$(request_boolean "Install PostGIS?" "n")"
INSTALL_PLR="$(request_boolean "Install PL/R?" "n")"
INSTALL_PLPY="$(request_boolean "Install PL/Python?" "n")"
INSTALL_PLCONTAINER_R="$(request_boolean "Install PL/Container R?" "n")"
INSTALL_PLCONTAINER_PY="$(request_boolean "Install PL/Container Python?" "n")"
INSTALL_MADLIB="$(request_boolean "Install MADlib?" "n")"
INSTALL_GPTEXT="$(request_boolean "Install GPText?" "n")"
#INSTALL_GPCC="$(request_boolean "Install Command Center?" "n")"


echo
echo

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

# Download / Accept EULA

EULAFILE="$CACHE/eula-$GP_VERSION_ID.html"
get_pivnet_eula "$GP_VERSION_DATA" > "$EULAFILE"

if [[ "$INCLUDE_EULA" == "true" ]]; then
  echo "Auto-accepting Pivotal Network EULA (will be copied into VM)"
else
  echo
  echo "VM will be created without a EULA, so you must accept it in advance:"
  echo
  print_html < "$EULAFILE"
  echo
  if [[ "$(request_boolean "Accept EULA?" "n")" != "true" ]]; then
    echo "Rejected EULA; aborting" >&2
    exit 1
  fi
  EULAFILE="/dev/null"
fi

accept_pivnet_eula "$GP_VERSION_DATA"

# These options are automatically set to true if a tool is requested which needs them
INSTALL_PLCONTAINER="false"
INSTALL_JAVA="false"

# Download Greenplum
download get_gpdb_download_url "greenplum.zip"

# Download PostGIS
if [[ "$INSTALL_POSTGIS" == "true" ]]; then
  DESCRIPTION_EXTRAS+=" + PostGIS"
  download get_postgis_download_url "postgis.gppkg"
fi

# Download PL/R
if [[ "$INSTALL_PLR" == "true" ]]; then
  DESCRIPTION_EXTRAS+=" + PL/R"
  download get_plr_download_url "plr.gppkg"
fi

# PL/Python
if [[ "$INSTALL_PLPY" == "true" ]]; then
  DESCRIPTION_EXTRAS+=" + PL/Python"
  # Bundled by default; nothing to download
fi

# Download PL/Container R
if [[ "$INSTALL_PLCONTAINER_R" == "true" ]]; then
  download get_plc_r_download_url "plc-r.tar.gz"
  INSTALL_PLCONTAINER="true"
fi

# Download PL/Container Python
if [[ "$INSTALL_PLCONTAINER_PY" == "true" ]]; then
  download get_plc_py_download_url "plc-py.tar.gz"
  INSTALL_PLCONTAINER="true"
fi

# Download PL/Container
if [[ "$INSTALL_PLCONTAINER" == "true" ]]; then
  DESCRIPTION_EXTRAS+=" + PL/Container"
  download get_plcontainer_download_url "plcontainer.gppkg"
fi

# Download MADlib
if [[ "$INSTALL_MADLIB" == "true" ]]; then
  DESCRIPTION_EXTRAS+=" + MADlib"
  download get_madlib_download_url "madlib.tar.gz"
fi

# Download GPText
if [[ "$INSTALL_GPTEXT" == "true" ]]; then
  DESCRIPTION_EXTRAS+=" + GPText"
  download get_gptext_download_url "gptext.tar.gz"
  INSTALL_JAVA="true"
fi

# Build base OS
if [[ "$BUILD_OS" == "true" ]]; then
  echo "Building base OS image..."
  rm -rf "$BASE_IMAGE_DIR" || true
  packer build \
    -only="$VM_MANAGER" \
    -var "disk_size=${DISK_SIZE}" \
    -var "build_dir=${BASE_IMAGE_DIR}" \
    "packer/$OS-os.json"
else
  echo "Using existing $OS image"
fi

# Build VM
BASE_IMAGE=( "$BASE_IMAGE_DIR/"*."$VM_EXT" )
echo "Building Greenplum $GP_VERSION image (based on $BASE_IMAGE)..."
rm -rf "$BUILD/$OS-greenplum" || true
packer build \
  -only="$VM_MANAGER" \
  -var "base_os=$BASE_IMAGE" \
  -var "gp_version=$GP_VERSION" \
  -var "memory=$MEMORY_SIZE" \
  -var "eulafile=$EULAFILE" \
  -var "description_extras=$DESCRIPTION_EXTRAS" \
  -var "install_postgis=$INSTALL_POSTGIS" \
  -var "install_plr=$INSTALL_PLR" \
  -var "install_plpy=$INSTALL_PLPY" \
  -var "install_plcontainer=$INSTALL_PLCONTAINER" \
  -var "install_plcontainer_r=$INSTALL_PLCONTAINER_R" \
  -var "install_plcontainer_py=$INSTALL_PLCONTAINER_PY" \
  -var "install_madlib=$INSTALL_MADLIB" \
  -var "install_java=$INSTALL_JAVA" \
  -var "install_gptext=$INSTALL_GPTEXT" \
  -var "install_gpcc=$INSTALL_GPCC" \
  "packer/$OS-greenplum.json"

OUTPUT_FILE="$BUILD/$OS-greenplum-$GP_VERSION.$OUT_EXT"
mv -f "$BUILD/$OS-greenplum/"*."$OUT_EXT" "$OUTPUT_FILE"

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
