#!/bin/sh

set -e

request_input() {
  PROMPT="$1"
  DEFAULT="$2"
  printf "$PROMPT [$DEFAULT]: " >&2
  read VALUE
  VALUE="${VALUE:-$DEFAULT}"
  printf "%s" "$VALUE"
}

request_boolean() {
  ANSWER="$(request_input "$1" "$2")"
  if [[ "$ANSWER" == "y"* ]] || [[ "$ANSWER" == "Y"* ]]; then
    printf "true"
  else
    printf "false"
  fi
}

get_access_token() {
  curl -s https://network.pivotal.io/api/v2/authentication/access_tokens \
    -d '{"refresh_token": "'"$1"'"}' \
    | jq -r '.access_token'
}

get_versions() {
  RELEASES_URL="$1"
  RECORD_COUNT="$2"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r '.releases | sort_by(.version | split(".") | map(tonumber))[].version' | tail -r -n"$RECORD_COUNT"
}

get_version_id() {
  RELEASES_URL="$1"
  VERSION="$2"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r ".releases[] | select(.version == \"$VERSION\") | .id"
}

get_download_url() {
  VERSION_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$VERSION_URL" | jq -r '
    .file_groups[] |
    select(.name == "Greenplum Database Server") |
    .product_files[] |
    select((.name | contains("RHEL 7")) and (.name | contains("Binary"))) |
    ._links.download.href
  '
}
