#!/bin/bash

set -e

setup_mc() {
  echo "Setting Up Minio Client"
  /usr/local/bin/mc --config-dir /tmp config host add default "${S3_ENDPOINT_URL}" "${S3_ACCESS_KEY_ID}" "${S3_SECRET_ACCESS_KEY}"
}

sync_folder() {
  echo "Trying to Sync ${BACKUP_FILE}"
  /usr/local/bin/mc --config-dir /tmp mirror "${BACKUP_DIR}" "default/${S3_BUCKET}/${DB_NAME}/${BACKUP_FILE}"
}

if [[ -z "${DB_HOST}" ]]; then
    echo "No DB_HOST Provided. Exiting."
    exit 1
fi

if [[ -z "${DB_USER}" ]]; then
    echo "No DB_USER provided. Assuming 'root'"
    DB_USER="root"
fi

if [[ -z "${DB_PASSWORD}" ]]; then
    echo "No DB_PASSWORD provided. Exiting"
    exit 1
fi

if [[ -z "${DB_NAME}" ]]; then
    echo "No DB_NAME provided. Exiting"
    exit 1
fi

if [[ -z "${BACKUP_DIR}" ]]; then
    echo "No BACKUP_DIR defined. Using /backups"
    BACKUP_DIR=/backups
fi


if [[ ! -d "${BACKUP_DIR}" ]]; then
   echo "Creating backup dir: ${BACKUP_DIR}"
   mkdir -p "${BACKUP_DIR}"
fi

BACKUP_FILE=${BACKUP_DIR}/${DB_NAME}-$(date +%d-%b-%y).dump

PGPASSWORD=${DB_PASSWORD}
export PGPASSWORD

pg_dump -h "${DB_HOST}" -U "${DB_USER}" -Fc "${DB_NAME}" > ${BACKUP_FILE}

if [[ ! -z "${S3_ACCESS_KEY_ID}" ]]; then
    echo "S3 Support recognized, Configuring client and the file will be sent to S3 in after pg_dump work."
    setup_mc
    sync_folder
    rm -rf "${BACKUP_FILE}"
    echo "S3 Backup Finished"
fi
