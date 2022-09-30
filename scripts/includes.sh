#!/bin/sh

DATA_DIR="/sqliteback/data"
# DB_NAME="users.db"
# DATA_DB="${DATA_DIR}/${DB_NAME}"
BACKUP_DIR="/sqliteback/backup"
RESTORE_DIR="/sqliteback/restore"
RESTORE_EXTRACT_DIR="${RESTORE_DIR}/extract"

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
    rclone mkdir ${RCLONE_REMOTE}
    if [[ $? != 0 ]]; then
        color red "storage system connection failure"
        exit 1
    fi
}

########################################
# Send mail by mailx.
# Arguments:
#     mail subject
#     mail content
# Outputs:
#     send mail result
########################################
function send_mail() {
    if [[ "${MAIL_DEBUG}" == "TRUE" ]]; then
        local MAIL_VERBOSE="-v"
    fi

    echo "$2" | mailx ${MAIL_VERBOSE} -s "$1" ${MAIL_SMTP_VARIABLES} ${MAIL_TO}
    if [[ $? != 0 ]]; then
        color red "mail sending failed"
    else
        color blue "mail send was successfully"
    fi
}

########################################
# Send mail.
# Arguments:
#     backup successful
#     mail content
########################################
function send_mail_content() {
    if [[ "${MAIL_SMTP_ENABLE}" == "FALSE" ]]; then
        return
    fi

    # successful
    if [[ "$1" == "TRUE" && "${MAIL_WHEN_SUCCESS}" == "TRUE" ]]; then
        send_mail "Sqlite Backup Success" "$2"
    fi

    # failed
    if [[ "$1" == "FALSE" && "${MAIL_WHEN_FAILURE}" == "TRUE" ]]; then
        send_mail "Sqlite Backup Failed" "$2"
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
    # MAIL_TO
    MAIL_SMTP_ENABLE=$(echo "${MAIL_SMTP_ENABLE}" | tr '[a-z]' '[A-Z]')
    if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" && -n "${MAIL_TO}" ]]; then
        MAIL_SMTP_ENABLE="TRUE"
    else
        MAIL_SMTP_ENABLE="FALSE"
    fi

    # MAIL_WHEN_SUCCESS
    MAIL_WHEN_SUCCESS=$(echo "${MAIL_WHEN_SUCCESS}" | tr '[a-z]' '[A-Z]')
    if [[ "${MAIL_WHEN_SUCCESS}" == "FALSE" ]]; then
        MAIL_WHEN_SUCCESS="FALSE"
    else
        MAIL_WHEN_SUCCESS="TRUE"
    fi

    # MAIL_WHEN_FAILURE
    MAIL_WHEN_FAILURE=$(echo "${MAIL_WHEN_FAILURE}" | tr '[a-z]' '[A-Z]')
    if [[ "${MAIL_WHEN_FAILURE}" == "FALSE" ]]; then
        MAIL_WHEN_FAILURE="FALSE"
    else
        MAIL_WHEN_FAILURE="TRUE"
    fi

    # SENDXMPP_ENABLE
    # MAIL_TO
    SENDXMPP_ENABLE=$(echo "${SENDXMPP_ENABLE}" | tr '[a-z]' '[A-Z]')
    if [[ "${SENDXMPP_ENABLE}" == "TRUE" && -n "${MAIL_TO}" ]]; then
        SENDXMPP_ENABLE="TRUE"
    else
        SENDXMPP_ENABLE="FALSE"
    fi

    # SENDXMPP_WHEN_SUCCESS
    SENDXMPP_WHEN_SUCCESS=$(echo "${SENDXMPP_WHEN_SUCCESS}" | tr '[a-z]' '[A-Z]')
    if [[ "${SENDXMPP_WHEN_SUCCESS}" == "FALSE" ]]; then
        SENDXMPP_WHEN_SUCCESS="FALSE"
    else
        SENDXMPP_WHEN_SUCCESS="TRUE"
    fi

    # SENDXMPP_WHEN_FAILURE
    SENDXMPP_WHEN_FAILURE=$(echo "${SENDXMPP_WHEN_FAILURE}" | tr '[a-z]' '[A-Z]')
    if [[ "${SENDXMPP_WHEN_FAILURE}" == "FALSE" ]]; then
        SENDXMPP_WHEN_FAILURE="FALSE"
    else
        SENDXMPP_WHEN_FAILURE="TRUE"
    fi

    # TIMEZONE
    local TIMEZONE_MATCHED_COUNT=$(ls "/usr/share/zoneinfo/${TIMEZONE}" 2> /dev/null | wc -l)
    if [[ ${TIMEZONE_MATCHED_COUNT} -ne 1 ]]; then
        TIMEZONE="UTC"
    fi

    color yellow "========================================"
    color yellow "DB_NAME: ${DB_NAME}"
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
        color yellow "MAIL_WHEN_SUCCESS: ${MAIL_WHEN_SUCCESS}"
        color yellow "MAIL_WHEN_FAILURE: ${MAIL_WHEN_FAILURE}"
    fi
    color yellow "SENDXMPP_ENABLE: ${SENDXMPP_ENABLE}"
    if [[ "${SENDXMPP_ENABLE}" == "TRUE" ]]; then
        color yellow "SENDXMPP_RECIPIENT: ${SENDXMPP_RECIPIENT}"
        color yellow "SENDXMPP_WHEN_SUCCESS: ${SENDXMPP_WHEN_SUCCESS}"
        color yellow "SENDXMPP_WHEN_FAILURE: ${SENDXMPP_WHEN_FAILURE}"
    fi
    color yellow "TIMEZONE: ${TIMEZONE}"
    color yellow "========================================"
}
