#!/usr/bin/env bash

# --------------------------------------------------
#
# Script to install all services.
#
# Prerequisites:
#   - JBoss EAP 7.4 zip
#   - JBoss EAP 7.4.3 patch
#   - JBoss EAP XP4 manager
#   - JBoss EAP XP4 patch
#   - Java, Maven & Git
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
Script to install all services.

Prerequisites:
  - JBoss EAP 7.4 zip
  - JBoss EAP 7.4.3 patch
  - JBoss EAP XP4 manager
  - JBoss EAP XP4 patch
  - Java, Maven & Git

USAGE:
    $(basename "${BASH_SOURCE[0]}") [FLAGS]

FLAGS:
    -f, --flag          Some flag
    -h, --help          Prints help information
    -v, --version       Prints version information
    --no-color          Uses plain text output
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
  return 0
}

parse_params "$@"
setup_colors

CLI_FILE=configure-eap.cli

EAP_74_DIR=jboss-eap-7.4
EAP_74_ZIP=jboss-eap-7.4.0.zip
EAP_DOWNLOAD_URL=https://developers.redhat.com/products/eap/download

EAP_743_PATCH=jboss-eap-7.4.3-patch.zip
EAP_743_URL=https://access.redhat.com/articles/6289951

EAP_XP4_MANAGER=jboss-eap-xp-4.0.0-manager.jar
EAP_XP4_PATCH=jboss-eap-xp-4.0.0-patch.zip

KAFKA_VERSION=2.13-3.4.0
KAFKA_DIR=kafka_${KAFKA_VERSION}
KAFKA_TAR=kafka_${KAFKA_VERSION}.tgz
KAFKA_URL=https://dlcdn.apache.org/kafka/3.4.0/${KAFKA_TAR}

POSTGRESQL_VERSION=42.2.5
POSTGRESQL_JAR=postgresql-${POSTGRESQL_VERSION}.jar
POSTGRESQL_URL=https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRESQL_VERSION}/${POSTGRESQL_JAR}

FRDEMO_NAME=first-responder-demo
FRDEMO_URL=https://github.com/wildfly-extras/${FRDEMO_NAME}
FRDEMO_BACKEND_WAR=${FRDEMO_NAME}/backend/target/frdemo-backend.war
FRDEMO_SIMULATOR_JAR=${FRDEMO_NAME}/simulator/target/quarkus-app/quarkus-run.jar

[[ -f ${EAP_74_ZIP} ]] || die "No JBoss EAP 7.4 zip file found: '${EAP_74_ZIP}'.\nPlease get it from ${EAP_DOWNLOAD_URL}"
[[ -f ${EAP_743_PATCH} ]] || die "No JBoss EAP 7.4.3 patch found: '${EAP_743_PATCH}'.\nPlease get it from ${EAP_743_URL}"
[[ -f ${EAP_XP4_MANAGER} ]] || die "No JBoss EAP XP4 manager found: '${EAP_XP4_MANAGER}'.\nPlease get it from ${EAP_DOWNLOAD_URL}"
[[ -f ${EAP_XP4_PATCH} ]] || die "No JBoss EAP XP4 patch found: '${EAP_XP4_PATCH}'.\nPlease get it from ${EAP_DOWNLOAD_URL}"
[[ -x "$(command -v java)" ]] || die "Java is not available"
[[ -x "$(command -v mvn)" ]] || die "Maven is not available"
[[ -x "$(command -v git)" ]] || die "Git is not available"

msg "\n${CYAN}Download${NOFORMAT} Kafka ${KAFKA_VERSION}"
if [[ -f ${KAFKA_TAR} ]]; then
  msg "${YELLOW}Skipped${NOFORMAT}"
else
  wget ${KAFKA_URL}
  msg "${GREEN}DONE${NOFORMAT}"
fi

msg "\n${CYAN}Unzip${NOFORMAT} Kafka ${KAFKA_VERSION}"
if [[ -d ${KAFKA_DIR} ]]; then
  msg "${YELLOW}Skipped${NOFORMAT}"
else
  tar xf ${KAFKA_TAR}
  msg "${GREEN}DONE${NOFORMAT}"
fi

msg "\n${CYAN}Unzip${NOFORMAT} JBoss EAP 7.4"
if [[ -d ${EAP_74_DIR} ]]; then
  msg "${YELLOW}Skipped${NOFORMAT}"
else
  unzip -q ${EAP_74_ZIP}
  msg "${GREEN}DONE${NOFORMAT}"
fi

msg "\n${CYAN}Apply${NOFORMAT} patch ${CYAN}7.4.3${NOFORMAT}"
java -jar ${EAP_XP4_MANAGER} patch-apply --jboss-home=${EAP_74_DIR} --patch=${EAP_743_PATCH}
msg "${GREEN}DONE${NOFORMAT}"

msg "\n${CYAN}Prepare${NOFORMAT} patch ${CYAN}XP4${NOFORMAT}"
java -jar ${EAP_XP4_MANAGER} setup --jboss-home=${EAP_74_DIR} --accept-support-policy
msg "${GREEN}DONE${NOFORMAT}"

msg "\n${CYAN}Apply${NOFORMAT} patch ${CYAN}XP4${NOFORMAT}"
java -jar ${EAP_XP4_MANAGER} patch-apply --jboss-home=${EAP_74_DIR} --patch=${EAP_XP4_PATCH}
msg "${GREEN}DONE${NOFORMAT}"

msg "\n${CYAN}Download${NOFORMAT} PostgreSQL JDBC driver"
if [[ -f ${POSTGRESQL_JAR} ]]; then
  msg "${YELLOW}Skipped${NOFORMAT}"
else
  wget ${POSTGRESQL_URL}
  msg "${GREEN}DONE${NOFORMAT}"
fi

msg "\n${CYAN}Clone${NOFORMAT} First Responder Demo"
if [[ -d ${FRDEMO_NAME} ]]; then
  msg "${YELLOW}Skipped${NOFORMAT}"
else
  git clone ${FRDEMO_URL}
  msg "${GREEN}DONE${NOFORMAT}"
fi

msg "\n${CYAN}Build${NOFORMAT} Backend"
if [[ -f ${FRDEMO_BACKEND_WAR} ]]; then
  msg "${YELLOW}Skipped${NOFORMAT}"
else
  cd ${FRDEMO_NAME}
  mvn clean package -DskipTests -DfailOnMissingWebXml=false -pl backend
  msg "${GREEN}DONE${NOFORMAT}"
  cd ..
fi

msg "\n${CYAN}Build${NOFORMAT} Simulator"
if [[ -f ${FRDEMO_SIMULATOR_JAR} ]]; then
  msg "${YELLOW}Skipped${NOFORMAT}"
else
  cd ${FRDEMO_NAME}
  mvn clean package -DskipTests -Dquarkus.container-image.build=false -Dquarkus.container-image.push=false -pl simulator
  msg "${GREEN}DONE${NOFORMAT}"
  cd ..
fi

msg "\n${CYAN}Configure${NOFORMAT} JBoss EAP"
${EAP_74_DIR}/bin/jboss-cli.sh --file=${CLI_FILE}
msg "${GREEN}DONE${NOFORMAT}"
