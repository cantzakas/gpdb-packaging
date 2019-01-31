#!/bin/sh

get_access_token() {
  curl -s https://network.pivotal.io/api/v2/authentication/access_tokens \
    -d '{"refresh_token": "'"$1"'"}' \
    | jq -r '.access_token'
}

get_pivnet_data() {
  URL="$1"
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" -L "$URL"
}

download_pivnet_file() {
  URL="$1"
  OUTPUT="$2"
  if ! test -f "$OUTPUT"; then
    curl -H "Authorization: Bearer $ACCESS_TOKEN" -L "$URL" -o "$OUTPUT"
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

# Get Greenplum Database Server related info & files
get_gpdb_versions() {
  RELEASES_URL="$1"
  RECORD_COUNT="$2"
  get_pivnet_data "$RELEASES_URL" | jq -c -r '.releases | sort_by(.version | split(".") | map(tonumber))[].version' | tail -r -n"$RECORD_COUNT"
}

get_gpdb_version_id() {
  RELEASES_URL="$1"
  VERSION="$2"
  get_pivnet_data "$RELEASES_URL" | jq -c -r ".releases[] | select(.version == \"$VERSION\") | .id"
}

get_gpdb_download_url() {
  VERSION_URL="$1"
  get_pivnet_data "$VERSION_URL" | jq -r '
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
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"PostGIS\")) |
    .name"
}

get_postgis_version_id() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"PostGIS\")) |
    .id"
}

get_postgis_download_url() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"PostGIS\")) |
    ._links.download.href"
}

# Get PL/R for Greenplum Database related info & files
get_plr_versions() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Procedural Languages\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"PL/R\")) |
    .name"
}

get_plr_version_id() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Procedural Languages\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"PL/R\")) |
    .id"
}

get_plr_download_url() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Procedural Languages\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"PL/R\")) |
    ._links.download.href"
}

# Get MADlib for Greenplum Database related info & files
get_madlib_versions() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"MADlib\")) |
    .name"
}

get_madlib_version_id() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"MADlib\")) |
    .id"
}

get_madlib_download_url() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL 7\")) |
    select(.name |
    contains(\"MADlib\")) |
    ._links.download.href"
}

# Get GPText for Greenplum Database related info & files
get_gptext_versions() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
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
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
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
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Advanced Analytics\") |
    .product_files[] |
    select(.name |
    contains(\"RHEL\")) |
    select(.name |
    contains(\"Text\")) |
    ._links.download.href"
}

# Get Greenplum Database Command Center related info & files
get_gpcc_versions() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Command Center\") |
    .product_files[] |
    select(.name |
    contains(\"Greenplum Command Center\")) |
    .name"
}

get_gpcc_version_id() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Command Center\") |
    .product_files[] |
    select(.name |
    contains(\"Greenplum Command Center\")) |
    .id"
}

get_gpcc_download_url() {
  RELEASES_URL="$1"
  get_pivnet_data "$RELEASES_URL" | jq -c -r "
    .file_groups[] |
    select(.name == \"Greenplum Command Center\") |
    .product_files[] |
    select(.name |
    contains(\"Greenplum Command Center\")) |
    ._links.download.href"
}