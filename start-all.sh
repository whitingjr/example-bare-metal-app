#!/usr/bin/env bash

# --------------------------------------------------
#
# Script to start all services (in this order):
#   - PostgreSQL
#   - Zookeeper
#   - Kafka
#   - JBoss EAP
#
# --------------------------------------------------

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

VERSION=0.0.1

# Change into the script's directory
# Using relative paths is safe!
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
readonly script_dir
cd "${script_dir}"

usage() {
  cat <<EOF
Script to start all services (in this order):
  - PostgreSQL
  - Zookeeper
  - Kafka
  - JBoss EAP

Prerequisites:
  - JBoss EAP 7.4.3 with XP4 and deployed first responder demo
  - MAPBOX_TOKEN environment variable
  - Docker Compose

USAGE:
    $(basename "${BASH_SOURCE[0]}") [FLAGS] <mapbox-token>

FLAGS:
    -f, --flag          Some flag
    -h, --help          Prints help information
    -v, --version       Prints version information
    --no-color          Uses plain text output

ARGS:
    <mapbox-token>      MapBox API token
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    # shellcheck disable=SC2034
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

version() {
  msg "${BASH_SOURCE[0]} $VERSION"
  exit 0
}

parse_params() {
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --version) version ;;
    --no-color) NO_COLOR=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")
  [[ ${#args[@]} -eq 0 ]] && die "Missing argument. Please specify a MapBox API token"
  MAPBOX_TOKEN=${args[0]}

  return 0
}

parse_params "$@"
setup_colors

EAP_74_DIR=jboss-eap-7.4

[[ -x "$(command -v docker-compose)" ]] || die "Docker compose is not available"

msg "\nStart ${CYAN}PostgreSQL, Zookeeper and Kafka${NOFORMAT}"
docker-compose up --detach
msg "${GREEN}DONE${NOFORMAT}"

msg "\nStart ${CYAN}JBoss EAP${NOFORMAT} after waiting 10 seconds"
${EAP_74_DIR}/bin/add-user.sh -u admin -p admin --silent
sleep 10
${EAP_74_DIR}/bin/standalone.sh \
  -DKAFKA_SERVER=localhost:9092 \
  -DMAPBOX_TOKEN="${MAPBOX_TOKEN}" \
  -c standalone-microprofile.xml
msg "${GREEN}DONE${NOFORMAT}"
