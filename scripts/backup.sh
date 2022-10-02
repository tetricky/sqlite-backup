#!/bin/bash

. /app/includes.sh

TIMESTAMP=$(date +"%Y-%m-%d-%H:%M")
# backup Sqlite database file
BACKUP_FILE_DB="${BACKUP_DIR}/${TIMESTAMP}-${DB_NAME}"
# backup zip file
BACKUP_FILE_ZIP="${BACKUP_DIR}/${TIMESTAMP}-${DB_NAME}.zip"

function backup_db() {
    color blue "backup_db(): backup sqlite database"
    
    echo "backup_db(): backup sqlite database" >> ${BACKUP_DIR}/report

    if [[ -f "${DATA_DB}" ]]; then
        sqlite3 ${DATA_DB} ".backup ${BACKUP_FILE_DB}"
    else
        color yellow "backup_db(): not found sqlite database, skipping"
        
        echo "backup_db(): not found sqlite database, skipping" >> ${BACKUP_DIR}/report
    fi
}

function backup() {

    backup_db

    ls -lah ${BACKUP_DIR}
    
    ls -lah ${BACKUP_DIR} >> ${BACKUP_DIR}/report
}

function backup_package() {
    if [[ "${ZIP_ENABLE}" == "TRUE" ]]; then
        color blue "backup_package(): package backup file"
        
        echo "backup_package(): package backup file" >> ${BACKUP_DIR}/report

        UPLOAD_FILE="${BACKUP_FILE_ZIP}"

        zip -jP ${ZIP_PASSWORD} ${BACKUP_FILE_ZIP} ${BACKUP_DIR}/*

        ls -lah ${BACKUP_DIR}

        color blue "backup_package(): display backup zip file list"
        
        echo "backup_package(): display backup zip file list" >> ${BACKUP_DIR}/report

        zip -sf ${BACKUP_FILE_ZIP}/ # echo $TIMEZONE 

    else
        color yellow "backup_package(): skip package backup files"
        
        echo "backup_package(): skip package backup files" >> ${BACKUP_DIR}/report

        UPLOAD_FILE="${BACKUP_DIR}"
    fi
}

function upload() {
    color blue "upload(): upload backup file to storage system"
    
    echo "upload(): upload backup file to storage system" >> ${BACKUP_DIR}/report

    # upload file not exist
    if [[ ! -f ${UPLOAD_FILE} ]]; then
        color red "upload(): upload file not found"
        
        echo "upload(): File upload failed at $(date +"%Y-%m-%d %H:%M:%S %Z"). Reason: Upload file not found." >> ${BACKUP_DIR}/report

        exit 1
    fi

    rclone copy ${UPLOAD_FILE} ${RCLONE_REMOTE}
    if [[ $? != 0 ]]; then
        color red "upload(): upload failed"
        
         echo "upload(): File upload failed at $(date +"%Y-%m-%d %H:%M:%S %Z")." >> ${BACKUP_DIR}/report

        exit 1
    fi
}

function clear_history() {
    if [[ "${BACKUP_KEEP_DAYS}" -gt 0 ]]; then
        color blue "clear_history(): delete ${BACKUP_KEEP_DAYS} days ago backup files"
        
        echo "clear_history(): delete ${BACKUP_KEEP_DAYS} days ago backup files" >> ${BACKUP_DIR}/report

        local RCLONE_DELETE_LIST=$(rclone lsf ${RCLONE_REMOTE} | head -n -${BACKUP_KEEP_DAYS})

        for RCLONE_DELETE_FILE in ${RCLONE_DELETE_LIST}
        do
            color yellow "clear_history(): deleting ${RCLONE_DELETE_FILE}"
            
            echo "clear_history(): deleting ${RCLONE_DELETE_FILE}" >> ${BACKUP_DIR}/report

            rclone delete ${RCLONE_REMOTE}/${RCLONE_DELETE_FILE}
            if [[ $? != 0 ]]; then
                color red "clear_history(): delete ${RCLONE_DELETE_FILE} failed"
                
                echo "clear_history(): delete ${RCLONE_DELETE_FILE} failed" >> ${BACKUP_DIR}/report
            fi
        done
    fi
}

color blue "backup.sh run for ${DB_NAME} at $(date +"%Y-%m-%d %H:%M:%S %Z")"

echo "backup.sh run for ${DB_NAME} at $(date +"%Y-%m-%d %H:%M:%S %Z")" > ${BACKUP_DIR}/report

# init_env
check_rclone_connection
backup
backup_package
upload
clear_history
send_xmpp_report
send_mail_report "${RCLONE_REMOTE_NAME} Backup Report $(date +"%Y-%m-%d %H:%M:%S %Z")."

color none ""
echo "" >> ${BACKUP_DIR}/report

