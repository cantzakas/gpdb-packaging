#!/bin/sh

request_input() {
  local PROMPT="$1"
  local DEFAULT="$2"
  printf "$PROMPT [$DEFAULT]: " >&2
  read VALUE
  printf "%s" "${VALUE:-$DEFAULT}"
}

request_boolean() {
  local ANSWER="$(request_input "$1" "$2")"
  if [[ "$ANSWER" == "y"* ]] || [[ "$ANSWER" == "Y"* ]]; then
    printf "true"
  else
    printf "false"
  fi
}

request_option() {
  local PROMPT="$1"
  local OPTIONS="$2"
  local CHOICE=1

  if (( "$(echo "$OPTIONS" | wc -l)" > 1 )); then
    echo "$1" >&2
    local i=1
    OLD_IFS="$IFS"
    IFS=$'\n'
    for option in ${OPTIONS}; do
      echo "[$i] $option" >&2
      (( i ++ ))
    done
    IFS="$OLD_IFS"

    CHOICE="$(request_input "Enter option number" "1")"
  fi

  local OPTION="$(echo "$OPTIONS" | head -n"$CHOICE" | tail -n1)"
  echo "Using $OPTION" >&2
  echo "$OPTION"
}
