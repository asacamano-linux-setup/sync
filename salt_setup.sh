#!/bin/bash

# Set up salt on a new server following the instructions at
# https://docs.saltproject.io/en/latest/topics/tutorials/quickstart.html#salt-masterless-quickstart

# ----------------------------------------------------------------------------
# Bash strict mode
#
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------------
# Utility functions

backup_and_empty() {
  FILE=${1}
  if [[ -f ${FILE} ]]; then
    MAX=$( ( ls -1 "${FILE}.bak."* 2>/dev/null || echo "" ) | sed -e "s:${FILE}.bak.::" | grep -v '[^0-9]' | sort -n | tail -1)
    if [[ -z "${MAX}" ]]; then 
      MAX=0
    else
      MAX=$(($MAX + 1))
    fi
    echo "Backing up ${FILE} to ${FILE}.bak.${MAX}"
    mv "${FILE}" "${FILE}.bak.${MAX}"
  fi
  echo "Making new ${FILE}"
  touch "${FILE}"
}

other_modules() {
  ( cd ${SYNC_DIR}/modules; ls -d * ) 2>/dev/null || echo ""
}

# ----------------------------------------------------------------------------
# Main

# Run as root rather than random prompt for password
if [ "$EUID" -ne 0 ]
  then echo "Please run as root. Trust me, it's OK."
  exit
fi

# Handle options
FORCE_DOWNLOAD=""
FORCE_NEW_CONFIG=""
DEBUG=""
while getopts "dcx" OPT; do
  case "${OPT}" in
    d)
      FORCE_DOWNLOAD="Y"
      ;;
    c)
      FORCE_NEW_CONFIG="Y"
      ;;
    x)
      DEBUG="-l debug"
      ;;
    *)
      echo "Use -d to force new downloads, or -c to force new config, or -x to debug."
      exit 1
      ;;
   esac
done

# Use configuration from this directory
SYNC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install salt if requested
SALT_CMD=$( which salt-call || echo "")
if [[ -z "${SALT_CMD}" || -n "${FORCE_DOWNLOAD}" ]]; then
  # No signature, but then this is running their software anyway...
  mkdir -p "${SYNC_DIR}/tmp"
  curl -L https://bootstrap.saltstack.com -o "${SYNC_DIR}/tmp/bootstrap_salt.sh"
  sh "${SYNC_DIR}/tmp/bootstrap_salt.sh"
fi

# Set up a masterless minion
MINION_FILE="/etc/salt/minion"
HAS_MINION_ALREADY=$( grep "^file_client: local" "${MINION_FILE}" || echo "")
if [[ -z "${HAS_MINION_ALREADY}" || -n "${FORCE_NEW_CONFIG}" ]]; then
  backup_and_empty "${MINION_FILE}"

  # Use a local file client
  echo "file_client: local" > "${MINION_FILE}"

  echo "file_roots:" >> "${MINION_FILE}"
  echo "  base:" >> "${MINION_FILE}"
  echo "    - ${SYNC_DIR}/public" >> "${MINION_FILE}"
  # Other modules (i.e. for work, etc)
  for MODULE in $( other_modules ); do
    echo "    - ${SYNC_DIR}/modules/${MODULE}" >>"${MINION_FILE}"
  done

  echo "" >> "${MINION_FILE}"
  echo "grains:" >> "${MINION_FILE}"
  echo "  sync_dir: \"${SYNC_DIR}\"" >> "${MINION_FILE}"
  echo "  target_user: \"${SUDO_USER}\"" >> "${MINION_FILE}"
  TARGET_HOME=$( eval echo "~${SUDO_USER}" )
  echo "  target_home: \"${TARGET_HOME}\"" >> "${MINION_FILE}"
  echo "  modules:" >> "${MINION_FILE}"
  # Other modules (i.e. for work, etc)
  for MODULE in $( other_modules ); do
    echo "    - ${MODULE}" >>"${MINION_FILE}"
  done

#  echo "" >> "${MINION_FILE}"
#  echo "include:" >> "${MINION_FILE}"
#  # Other modules (i.e. for work, etc)
#  for MODULE in $( other_modules ); do
#    if [[ -f "${SYNC_DIR}/modules/${MODULE}/minion" ]]; then
#      echo "  - ${SYNC_DIR}/modules/${MODULE}/minion" >>"${MINION_FILE}"
#    fi
#  done

fi

# Run the setup
echo "salt-call --local state.apply ${DEBUG}"
IFS=" "
salt-call --local state.apply ${DEBUG}
