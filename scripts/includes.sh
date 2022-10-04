#!/bin/bash

#################### Function ####################
########################################
# Print colorful message.
# Arguments:
#     color
#     message
# Outputs:
#     colorful message
########################################
function color() {
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo $2 ;;
    esac
}

########################################
# Check storage system connection success.
# Arguments:
#     None
########################################
function check_rclone_connection() {
    color blue "check_rclone_connection(): ${RCLONE_REMOTE_NAME} Initialising"
    echo "check_rclone_connection(): ${RCLONE_REMOTE_NAME} Initialising" >> ${BACKUP_DIR}/report
    # test rclone storage backend
    rclone mkdir ${RCLONE_REMOTE}
    rclone mkdir ${RCLONE_REMOTE}/init
    if [[ $? != 0 ]]; then
        color red "check_rclone_connection(): ${RCLONE_REMOTE_NAME} Storage system failure $(date +"%Y-%m-%d %H:%M:%S %Z")"
        echo "check_rclone_connection(): ${RCLONE_REMOTE_NAME} Storage system failure $(date +"%Y-%m-%d %H:%M:%S %Z")" >> ${BACKUP_DIR}/report
        exit 1
    fi
}

########################################
# Send mail report.
# Arguments:
#     mail subject
# Outputs:
#     send report
########################################
function send_mail_report() {
    if [[ "${MAIL_SMTP_ENABLE}" == "FALSE" ]]; then
        return
    fi

    if [[ "${MAIL_DEBUG}" == "TRUE" ]]; then
        local MAIL_VERBOSE="-v"
    fi

    cat ${BACKUP_DIR}/report | mailx ${MAIL_VERBOSE} -s "$1" ${MAIL_SMTP_VARIABLES} ${MAIL_TO}
    if [[ $? != 0 ]]; then
        color red "send_mail(): mailx send failed"
        echo "send_mail(): mailx send failed" >> ${BACKUP_DIR}/report
    else
        color green "send_mail(): mailx send successful"
        echo "send_mail(): mailx send successful" >> ${BACKUP_DIR}/report
    fi
}

########################################
# Send xmpp report.
# Outputs:
#     send report
########################################
function send_xmpp_report() {
    if [[ "${SENDXMPP_ENABLE}" == "FALSE" ]]; then
        return
    fi

    cat ${BACKUP_DIR}/report | go-sendxmpp -u ${SENDXMPP_USER} -p ${SENDXMPP_PASSWORD} ${SENDXMPP_RECIPIENT}
    if [[ $? != 0 ]]; then
        color red "send_xmpp_report(): sendxmpp failed"
        echo "send_xmpp_report(): sendxmpp failed" >> ${BACKUP_DIR}/report
    else
        color green "send_xmpp_report(): sendxmpp successful"
        echo "send_xmpp_report(): sendxmpp successful" >> ${BACKUP_DIR}/report
    fi
}

########################################
# Initialization environment variables.
# Arguments:
#     None
# Outputs:
#     environment variables
########################################
function init_env() {
    # Define DATA_DB
    export DATA_DB="${DATA_DIR}/${DB_NAME}"
    # Define RCLONE_REMOTE
    export RCLONE_REMOTE="${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_DIR}"    
    color yellow "========================================"
    color yellow "DB_NAME: ${DB_NAME}"
    color yellow "DATA_DIR: ${DATA_DIR}"
    color yellow "CONFIG_NAME: ${CONFIG_NAME}"
    color yellow "PKEY_NAME: ${PKEY_NAME}"
    color yellow "DATA_DB: ${DATA_DB}"
    color yellow "BACKUP_DIR: ${BACKUP_DIR}"
    color yellow "CRON: ${CRON}"
    color yellow "RCLONE_REMOTE_NAME: ${RCLONE_REMOTE_NAME}"
    color yellow "RCLONE_REMOTE_DIR: ${RCLONE_REMOTE_DIR}"
    color yellow "RCLONE_REMOTE: ${RCLONE_REMOTE}"
    color yellow "FILES_TO_KEEP: ${FILES_TO_KEEP}"
    color yellow "MAIL_SMTP_ENABLE: ${MAIL_SMTP_ENABLE}"
    if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" ]]; then
        color yellow "MAIL_TO: ${MAIL_TO}"
    fi
    color yellow "SENDXMPP_ENABLE: ${SENDXMPP_ENABLE}"
    if [[ "${SENDXMPP_ENABLE}" == "TRUE" ]]; then
        color yellow "SENDXMPP_USER: ${SENDXMPP_USER}"
        color yellow "SENDXMPP_RECIPIENT: ${SENDXMPP_RECIPIENT}"
    fi
    color yellow "TIMEZONE: ${TIMEZONE}"
    color yellow "========================================"
}
