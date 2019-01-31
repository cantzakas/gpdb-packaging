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
