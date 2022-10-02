FROM alpine:3.16

# Code largely from ttionya/vaultwarden-backup
# https://github.com/ttionya/vaultwarden-backup
# with further modifications from  karbon15/EteBase-Backup
# https://github.com/karbon15/EteBase-Backup

# Written as simple backup container to dump lldap database
# for nitnelave/lldap
# https://github.com/nitnelave/lldap
# the container is written in such a way as to possibly be used for other sqlite database dumps

# Alpine Linux 3.16 is used as a base, as this is the first version to include go-sendxmpp as a package

LABEL "repository"="https://github.com/tetricky/sqlite-backup/" \
  "homepage"="https://github.com/tetricky/sqlite-backup/" \
  "maintainer"="tetricky"

ENV DATA_DIR="/sqlitedata"
    BACKUP_DIR="/backup"
    DB_NAME="users.db"
    CRON="5 0 * * *"
    RCLONE_REMOTE_NAME="sqlitebackup"
    RCLONE_REMOTE_DIR="/sqliteback/"
    ZIP_ENABLE="FALSE"
    ZIP_PASSWORD="password"
    BACKUP_KEEP_DAYS="1"
    MAIL_SMTP_ENABLE="FALSE"
    MAIL_SMTP_VARIABLES=""
    MAIL_TO=""
    SENDXMPP_ENABLE="FALSE"
    SENDXMPP_USER=""
    SENDXMPP_PASSWORD=""
    SENDXMPP_SERVER=""
    SENDXMPP_RECIPIENT=""
    TIMEZONE="UTC"

COPY scripts/*.sh /app/
COPY rclone.conf /root/.config/rclone/

RUN chmod +x /app/*.sh \
  && apk add --no-cache bash curl sqlite p7zip heirloom-mailx tzdata unzip go-sendxmpp \
  && curl https://rclone.org/install.sh | bash \
  && apk del curl unzip && rm -rf /var/cache/apk/*

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["cron", "5 0 * * *"]
