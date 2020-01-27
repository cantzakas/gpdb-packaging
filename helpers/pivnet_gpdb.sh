#!/bin/bash

get_gpdb_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Database Server" \
    | jq -r 'select((.name | contains("RHEL 7")) and (.name | contains("Installer")) and (.name | contains("DCA") | not))' \
    | pivnet_data_download_url
}

get_postgis_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Advanced Analytics" \
    | jq -r 'select((.name | contains("RHEL 7")) and (.name | contains("PostGIS")))' \
    | pivnet_data_download_url
}

get_plr_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Procedural Languages" \
    | jq -r 'select((.name | contains("RHEL 7")) and (.name | contains("PL/R")))' \
    | pivnet_data_download_url
}

get_pljava_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Procedural Languages" \
    | jq -r 'select((.name | contains("RHEL 7")) and (.name | contains("PL/Java")))' \
    | pivnet_data_download_url
}

get_plcontainer_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Procedural Languages" \
    | jq -r 'select((.name | contains("RHEL 7")) and (.name | contains("PL/Container")))' \
    | pivnet_data_download_url
}

get_plc_r_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Procedural Languages" \
    | jq -r 'select((.name | contains("for R")) and (.name | contains("Pl/Container")))' \
    | pivnet_data_download_url
}

get_plc_py_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Procedural Languages" \
    | jq -r 'select((.name | contains("for Python")) and (.name | contains("Pl/Container")))' \
    | pivnet_data_download_url
}

get_madlib_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Advanced Analytics" \
    | jq -r 'select((.name | contains("RHEL 7")) and (.name | contains("MADlib")))' \
    | pivnet_data_download_url
}

get_gptext_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Advanced Analytics" \
    | jq -r 'select((.name | contains("RHEL")) and (.name | contains("Text")))' \
    | pivnet_data_download_url
}

get_gpcc_download_url() {
  echo "$1" \
    | pivnet_data_file_group "Greenplum Command Center" \
    | jq -r 'select(.name | contains("Greenplum Command Center"))' \
    | pivnet_data_download_url
}
