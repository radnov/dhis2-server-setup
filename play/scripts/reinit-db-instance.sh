#!/bin/bash

# INIT
. env.sh

# GLOBALS
# ---
# TMP_DIR
# BASE_URL
# DB_BASE_DIR
# DB_FILE
# AUTH

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -eq 0 ]; then
  echo -e "Usage: $0 <instances...>\n"
  exit 1
fi

function validate() {
  if [ ! -d "${DB_BASE_DIR}/${1}" ]; then
    echo "Instance $1 does not have the required SQL file database directory."
    exit 1
  fi
}

function run() {
  $DIR/stop-instance.sh $1
  sleep 5
  sudo -u postgres dropdb $1
  sudo -u postgres createdb -O dhis $1

  cp "${DB_BASE_DIR}/${1}/${DB_FILE}.sql.gz" "${TMP_DIR}/${DB_FILE}-${1}.sql.gz"
  gunzip -f "${TMP_DIR}/${DB_FILE}-${1}.sql.gz"
  sudo -u postgres psql -d "${1}" -f "${TMP_DIR}/${DB_FILE}-${1}.sql"
  sleep 2
  $DIR/start-instance.sh $1
}

function analytics() {
  curl "${BASE_URL}/${1}/api/resourceTables/analytics" -X POST -u "${AUTH}"
}

for instance in $@; do
  validate $instance
  run $instance
  echo "Waiting 2 minutes to allow DHIS 2 to start before initiating analytics tables update"
  sleep 120
  analytics $instance
done
