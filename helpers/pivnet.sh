#!/bin/bash

PIVNET_ACCESS_TOKEN=""

request_access_token() {
  curl -s https://network.pivotal.io/api/v2/authentication/access_tokens \
    -d "{\"refresh_token\": \"$REFRESH_TOKEN\"}"
}

get_access_token() {
  if [[ -z "$PIVNET_ACCESS_TOKEN" ]]; then
    PIVNET_ACCESS_TOKEN="$(request_access_token | jq -r '.access_token')"
  fi

  if [[ "$PIVNET_ACCESS_TOKEN" == "null" ]]; then
    echo "Failed to negotiate pivnet access token." >&2
    echo "Check provided REFRESH_TOKEN has not expired." >&2
    echo >&2
    request_access_token >&2
    exit 1
  fi

  echo "$PIVNET_ACCESS_TOKEN"
}

get_pivnet_data() {
  curl -s -L "$@"
}

get_authenticated_pivnet_data() {
  curl -H "Authorization: Bearer $(get_access_token)" -L "$@"
}

download_pivnet_file() {
  local URL="$1"
  local OUTPUT="$2"
  if ! test -f "$OUTPUT"; then
    echo "Downloading $URL as $OUTPUT..."
    get_authenticated_pivnet_data "$URL" > "$OUTPUT"
  else
    echo "Using existing $OUTPUT"
  fi

  if [[ "$(head -c1 "$OUTPUT")" == '{' ]]; then
    echo "Failed to download $OUTPUT. Error:" >&2
    cat "$OUTPUT" >&2
    echo >&2;
    rm "$OUTPUT"
    exit 1
  fi
}

get_pivnet_product_releases() {
  local RELEASES_URL="$1"
  local RECORD_COUNT="$2"
  get_pivnet_data "$RELEASES_URL" \
    | jq -r '.releases | sort_by(.version | split(".") | map(tonumber))[].version' \
    | tail -r -n"$RECORD_COUNT"
}

get_pivnet_product_release_id() {
  local RELEASES_URL="$1"
  local VERSION="$2"
  get_pivnet_data "$RELEASES_URL" \
    | jq -r ".releases[] | select(.version == \"$VERSION\") | .id"
}

get_pivnet_product_release_data() {
  local RELEASES_URL="$1"
  local VERSION_ID="$2"
  get_pivnet_data "$RELEASES_URL/$VERSION_ID"
}

get_pivnet_eula() {
  local RELEASE_DATA="$1"
  local URL="$(echo "$RELEASE_DATA" | jq -r '.eula._links.self.href')"
  get_pivnet_data "$URL" \
    | jq -r '.content' \
    | sed 's/<pre/<pre style="white-space:pre-wrap"/g'
}

accept_pivnet_eula() {
  local RELEASE_DATA="$1"
  local URL="$(echo "$RELEASE_DATA" | jq -r '._links.self.href')/eula_acceptance"
  get_authenticated_pivnet_data -s -X POST "$URL" >/dev/null
}

pivnet_data_file_group() {
  local GROUP_NAME="$1"
  jq -cr ".file_groups[] | select(.name == \"$GROUP_NAME\") | .product_files[]"
}

pivnet_data_download_url() {
  jq -r '._links.download.href'
}
