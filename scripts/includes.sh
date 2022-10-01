#!/bin/sh

DATA_DIR="/sqliteback/data"
BACKUP_DIR="/sqliteback/backup"

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
    echo "check_rclone_connection(): ${RCLONE_REMOTE_NAME} Initialising" >> ${BACKUP_DIR}/report
    rclone mkdir ${RCLONE_REMOTE}
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
        color blue "send_mail(): mailx send successful"
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

    cat ${BACKUP_DIR}/report | go-sendxmpp -u ${SENDXMPP_USER} -j ${SENDXMPP_SERVER} -p ${SENDXMPP_PASSWORD} ${SENDXMPP_RECIPIENT}
    if [[ $? != 0 ]]; then
        color red "send_xmpp_report(): sendxmpp failed"
        echo "send_xmpp_report(): sendxmpp failed" >> ${BACKUP_DIR}/report
    else
        color blue "send_xmpp_report(): sendxmpp successful"
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

    # DB_NAME
    local DB_NAME_DEFAULT="users.db"
    if [[ -z "${DB_NAME}" ]]; then
        DB_NAME="${DB_NAME_DEFAULT}"
    fi

    # DATA_DB
    DATA_DIR="/sqliteback/data"
    BACKUP_DIR="/sqliteback/backup"
    DATA_DB="${DATA_DIR}/${DB_NAME}"

    # CRON
    local CRON_DEFAULT="5 0 * * *"
    if [[ -z "${CRON}" ]]; then
        CRON="${CRON_DEFAULT}"
    fi

    # RCLONE_REMOTE_NAME
    local RCLONE_REMOTE_NAME_DEFAULT="sqlitebackup"
    if [[ -z "${RCLONE_REMOTE_NAME}" ]]; then
        RCLONE_REMOTE_NAME="${RCLONE_REMOTE_NAME_DEFAULT}"
    fi

    # RCLONE_REMOTE_DIR
    local RCLONE_REMOTE_DIR_DEFAULT="/sqliteback/"
    if [[ -z "${RCLONE_REMOTE_DIR}" ]]; then
        RCLONE_REMOTE_DIR="${RCLONE_REMOTE_DIR_DEFAULT}"
    fi

    # RCLONE_REMOTE
    RCLONE_REMOTE="${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_DIR}"

    # ZIP_ENABLE
    ZIP_ENABLE=$(echo "${ZIP_ENABLE}" | tr '[a-z]' '[A-Z]')
    if [[ "${ZIP_ENABLE}" == "TRUE" ]]; then
        ZIP_ENABLE="TRUE"
    else
        ZIP_ENABLE="FALSE"
    fi

    # ZIP_PASSWORD
    if [[ -z "${ZIP_PASSWORD}" ]]; then
        ZIP_PASSWORD="password"
    fi

    # BACKUP_KEEP_DAYS
    local BACKUP_KEEP_DAYS_DEFAULT="1"
    if [[ -z "${BACKUP_KEEP_DAYS}" ]]; then
        BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS_DEFAULT}"
    fi

    # MAIL_SMTP_ENABLE
    MAIL_SMTP_ENABLE=$(echo "${MAIL_SMTP_ENABLE}" | tr '[a-z]' '[A-Z]')
    if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" && -n "${MAIL_TO}" ]]; then
        MAIL_SMTP_ENABLE="TRUE"
    else
        MAIL_SMTP_ENABLE="FALSE"
        echo "mailx disabled, or not configured" >> ${BACKUP_DIR}/report
    fi

    # SENDXMPP_ENABLE
    SENDXMPP_ENABLE=$(echo "${SENDXMPP_ENABLE}" | tr '[a-z]' '[A-Z]')
    if [[ "${SENDXMPP_ENABLE}" == "TRUE" && -n "${SENDXMPP_RECIPIENT}" ]]; then
        SENDXMPP_ENABLE="TRUE"
    else
        SENDXMPP_ENABLE="FALSE"
        echo "sendxmpp disabled, or not configured" >> ${BACKUP_DIR}/report
    fi

    # TIMEZONE
    TIMEZONE_MATCHED_COUNT=$(ls "/usr/share/zoneinfo/${TIMEZONE}" 2> /dev/null | wc -l)
    if [[ ${TIMEZONE_MATCHED_COUNT} -ne 1 ]]; then
        TIMEZONE="UTC"
    fi

    color yellow "========================================"
    color yellow "DB_NAME: ${DB_NAME}"
    color yellow "DATA_DIR: ${DATA_DIR}"
    color yellow "DATA_DB: ${DATA_DB}"
    color yellow "BACKUP_DIR: ${BACKUP_DIR}"
    color yellow "CRON: ${CRON}"
    color yellow "RCLONE_REMOTE_NAME: ${RCLONE_REMOTE_NAME}"
    color yellow "RCLONE_REMOTE_DIR: ${RCLONE_REMOTE_DIR}"
    color yellow "RCLONE_REMOTE: ${RCLONE_REMOTE}"
    color yellow "ZIP_ENABLE: ${ZIP_ENABLE}"
    color yellow "ZIP_PASSWORD: ${ZIP_PASSWORD} Chars"
    color yellow "BACKUP_KEEP_DAYS: ${BACKUP_KEEP_DAYS}"
    color yellow "MAIL_SMTP_ENABLE: ${MAIL_SMTP_ENABLE}"
    if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" ]]; then
        color yellow "MAIL_TO: ${MAIL_TO}"
    fi
    color yellow "SENDXMPP_ENABLE: ${SENDXMPP_ENABLE}"
    if [[ "${SENDXMPP_ENABLE}" == "TRUE" ]]; then
        color yellow "SENDXMPP_RECIPIENT: ${SENDXMPP_RECIPIENT}"
    fi
    color yellow "TIMEZONE: ${TIMEZONE}"
    color yellow "========================================"
}
