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

COPY scripts/*.sh /app/
COPY rclone.conf /root/.config/rclone/
COPY .env /root/.config/variables/

RUN chmod +x /app/*.sh \
  && apk add --no-cache bash curl sqlite p7zip heirloom-mailx tzdata unzip go-sendxmpp \
  && curl https://rclone.org/install.sh | bash \
  && apk del curl unzip && rm -rf /var/cache/apk/*

ENV DATA_DIR="/sqlitedata"
ENV BACKUP_DIR="/backup"
ENV DB_NAME="users.db"
ENV CRON="5 0 * * *"
ENV RCLONE_REMOTE_NAME="sqlitebackup"
ENV RCLONE_REMOTE_DIR="/sqliteback/"
ENV ZIP_ENABLE="FALSE"
ENV ZIP_PASSWORD="password"
ENV FILES_TO_KEEP="2"
ENV MAIL_SMTP_ENABLE="FALSE"
ENV MAIL_SMTP_VARIABLES=""
ENV MAIL_TO=""
ENV SENDXMPP_ENABLE="FALSE"
ENV SENDXMPP_USER=""
ENV SENDXMPP_PASSWORD=""
ENV SENDXMPP_RECIPIENT=""
ENV TIMEZONE="UTC"

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["cron", "5 0 * * *"]
