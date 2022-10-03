#!/bin/bash

. /app/includes.sh

TIMESTAMP=$(date +"%Y-%m-%d-%H:%M")
# backup Sqlite database file
BACKUP_FILE_DB="${BACKUP_DIR}/${TIMESTAMP}-${DB_NAME}"

function backup() {

    rm ${BACKUP_DIR}/*${DB_NAME}
    
    color blue "backup_db(): backup sqlite database"
    
    echo "backup_db(): backup sqlite database" >> ${BACKUP_DIR}/report

    if [[ -f "${DATA_DB}" ]]; then
        sqlite3 ${DATA_DB} ".backup ${BACKUP_FILE_DB}"
    else
        color red "backup_db(): not found sqlite database, skipping"
        
        echo "backup_db(): not found sqlite database, skipping" >> ${BACKUP_DIR}/report
    fi

    ls -lh ${BACKUP_DIR}/*${DB_NAME}
    ls -lh ${BACKUP_DIR}/*${DB_NAME} >> ${BACKUP_DIR}/report
}


function upload() {
    color blue "upload(): upload backup file to storage system"
    
    echo "upload(): upload backup file to storage system" >> ${BACKUP_DIR}/report
    
    rclone copy ${BACKUP_DIR} ${RCLONE_REMOTE}

    if [[ $? != 0 ]]; then

        color red "upload(): Remote copy failed, check backup directory"

        echo "upload(): Remote copy failed, check backup directory $(date +"%Y-%m-%d %H:%M:%S %Z")." >> ${BACKUP_DIR}/report

        return 1
    fi
}

function clear_history() {
    if [[ "${FILES_TO_KEEP}" -gt 0 ]]; then

        color blue "clear_history(): keep only ${FILES_TO_KEEP} file(s)"
        
        echo "clear_history(): keep only ${FILES_TO_KEEP} file(s)" >> ${BACKUP_DIR}/report

        local RCLONE_DELETE_LIST=$(rclone lsf ${RCLONE_REMOTE} | head -n -${FILES_TO_KEEP})

        for RCLONE_DELETE_FILE in ${RCLONE_DELETE_LIST}
        do
            color blue "clear_history(): deleting ${RCLONE_DELETE_FILE}"
            
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

check_rclone_connection
backup
upload
clear_history
send_xmpp_report
send_mail_report "${RCLONE_REMOTE_NAME} Backup Report $(date +"%Y-%m-%d %H:%M:%S %Z")."

