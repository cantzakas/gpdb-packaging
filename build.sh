#!/bin/sh

GP_DOWNLOAD_URL="https://network.pivotal.io/api/v2/products/pivotal-gpdb/releases/280281/product_files/292163/download"

OUTPUT_FILE="build/centos7-greenplum.ova";

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

get_access_token() {
  curl -s https://network.pivotal.io/api/v2/authentication/access_tokens \
    -d '{"refresh_token": "'"$1"'"}' \
    | jq -r '.access_token'
}

# Download Greenplum
GP_ZIP="build/greenplum.zip"
if [[ " $* " == *' --force-download '* ]] || ! test -f "$GP_ZIP"; then
  echo "Negotiating token to download Greenplum from Pivotal Network..."
  ACCESS_TOKEN="$(get_access_token "$REFRESH_TOKEN")"

  echo "Downloading Greenplum using access token: $ACCESS_TOKEN";
  curl -H "Authorization: Bearer $ACCESS_TOKEN" -L -o "$GP_ZIP" "$GP_DOWNLOAD_URL"
else
  echo "Using existing greenplum.zip download (specify --force-download to download latest)"
fi

# Build base OS
if [[ " $* " == *' --force-build-os '* ]] || ! test -f "build/centos7-os/"*.ovf; then
  echo "Building base OS image..."
  rm -rf "build/centos7-os" || true
  packer build packer/centos7-os.json
else
  echo "Using existing CentOS7 image (specify --force-build-os to build fresh)"
fi

# Build VM
BASE_IMAGE_OVF=( build/centos7-os/*.ovf )
echo "Building Greenplum image (based on $BASE_IMAGE_OVF)..."
rm -rf "build/centos7-greenplum" || true
packer build \
  -var "base_os=$BASE_IMAGE_OVF" \
  -var "greenplum_zip=$GP_ZIP" \
  packer/centos7-greenplum.json

mv -f build/centos7-greenplum/*.ova "$OUTPUT_FILE"

echo
echo "Build complete; generated $OUTPUT_FILE"

cd -
