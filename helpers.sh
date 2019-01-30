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

# Get Greenplum Database Server related info & files
get_gpdb_versions() {
  RELEASES_URL="$1"
  RECORD_COUNT="$2"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r '.releases | sort_by(.version | split(".") | map(tonumber))[].version' | tail -r -n"$RECORD_COUNT"
}

get_gpdb_version_id() {
  RELEASES_URL="$1"
  VERSION="$2"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r ".releases[] | select(.version == \"$VERSION\") | .id"
}

get_gpdb_download_url() {
  VERSION_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$VERSION_URL" | jq -r '
    .file_groups[] |
    select(.name == "Greenplum Database Server") |
    .product_files[] |
    select((.name | contains("RHEL 7")) and (.name | contains("Binary"))) |
    ._links.download.href
  '
}

# Get PostGIS for Greenplum Database related info & files
get_postgis_versions() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"7\")) |
    select(.name |
    contains(\"PostGIS\")) |
    .name"
}

get_postgis_version_id() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"7\")) |
    select(.name |
    contains(\"PostGIS\")) |
    .id"
}

get_postgis_download_url() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"7\")) |
    select(.name |
    contains(\"PostGIS\")) |
    ._links.download.href"
}

# Get MADlib for Greenplum Database related info & files
get_madlib_versions() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"7\")) |
    select(.name |
    contains(\"MADlib\")) |
    .name"
}

get_madlib_version_id() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"7\")) |
    select(.name |
    contains(\"MADlib\")) |
    .id"
}

get_madlib_download_url() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"7\")) |
    select(.name |
    contains(\"MADlib\")) |
    ._links.download.href"
}

# Get GPText for Greenplum Database related info & files
get_gptext_versions() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL\")) |
    select(.name |
    contains(\"Text\")) |
    .name"
}

get_gptext_version_id() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL\")) |
    select(.name |
    contains(\"Text\")) |
    .id"
}

get_gptext_download_url() {
  RELEASES_URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL\")) |
    select(.name |
    contains(\"Text\")) |
    ._links.download.href"
}