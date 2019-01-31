#!/bin/sh

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

request_option() {
  PROMPT="$1"
  OPTIONS="$2"

  echo "$1" >&2

  OLD_IFS="$IFS"
  IFS=$'\n'

  local i=1
  for option in ${OPTIONS}; do
    echo "[$i] $option" >&2
    (( i ++ ))
  done

  IFS="$OLD_IFS"

  CHOICE="$(request_input "Enter option number" "1")"
  echo "$OPTIONS" | head -n"$CHOICE" | tail -n1
}
