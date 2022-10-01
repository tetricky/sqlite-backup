# sqlite-backup

## Intended use

A simple backup container to dump an sqlite database for nitnelave/lldap. By adjusting the environment variables this might also be backup container for any sqlite3 database

Code structure and logic largely from ttionya/sqlite-backup
https://github.com/ttionya/sqlite-backup
with further modifications from  karbon15/EteBase-Backup
https://github.com/karbon15/EteBase-Backup

### 

Dumps the sqlite database to rclone storage system backend (defaults to local filesystem), using cron to automate, with a simple retention policy, and the possibility of notifications by email or xmpp.


## Feature

This tool supports backing up the following file.

- `users.db`

In the event that the sqlite database is named differently, this can be set using the ```DB_NAME``` environment variable.

## Building the container

Clone the repository. From the root directory build (using podman) with:

```
podman build -t tetricky/sqlite-backup:latest -f Containerfile
```

## Usage Note

Using the default settings, which are to backup locally, with a retention of one (in days), the container acts as a periodic (set by cron) database dump. In order to provide effective backup this dump must be included as part of a wider backup scheme. Alternatively a non-local rclone storage system may be used, and retention increased, to provide a simple backup scheme from this container alone.

Using environment variables the periodicity and retention can be increased, and any rclone target can be used to achieve direct backup.

#### storage backend

By default we use [Rclone](https://rclone.org/docs/) to backup to the local filesystem. This can be exposed by mapping the backup directory in the container (by default "/sqliteback" - the ```RCLONE_REMOTE_DIR``` environment variable) to the host filesystem. This happens once a day, at five past midnight.

In order to change the storage backend make a rclone.conf file on the host and map it to /config/rclone/rclone.conf in the container.

Note that you need to set the environment variable `RCLONE_REMOTE_NAME` to match the remote name in your rclone.conf file.


### Automatic Backups

run container using podman
  
```
podman run -d --name lldap-backup -v [host sqlite database directory]:/sqlitebackup/data/ -v [host sqlite backup directory]:/sqliteback/ tetricky/sqlite-backup:latest
```

### Restore

There is intentionally no restore routine built into the container. sqlite3 databases are simple files. Copying the backed up (extracted if compressed) database into the location of the original database to replace it will restore the database to the backup. The container using the database should be stopped before doing this. This is destructive. 

## Environment Variables

> **Note:** All environment variables have default values, and you can use the docker/podman image without setting environment variables.

#### DATA_DIR

The location of the database to be backed up.

Default: `/sqliteback/data`

#### BACKUP_DIR

The location of the backups created.

Default: `/sqliteback/backup`


#### DB_NAME

The name of the sqlite database to be backed up.

Default: `users.db`

#### RCLONE_REMOTE_NAME

Rclone remote name, you can name it yourself.

Default: `sqlitebackup`

#### RCLONE_REMOTE_DIR

Folder for storing backup files in the storage system.

Default: `/sqliteback/`

#### CRON

Schedule run backup script, based on Linux `crond`. You can test the rules [here](https://crontab.guru/#5_*_*_*_*).

Default: `5 0 * * *` (run the script at 5 minutes past midnight every day)

#### ZIP_ENABLE

Compress the backup file as Zip archive. When set to `'TRUE'`.

Default: `FALSE`

#### ZIP_PASSWORD

Set your password to encrypt Zip archive. Note that the password will always be used when compressing the backup file. If zip compression is enabled, failing to set a new password is most insecure.

Default: `password`

#### BACKUP_KEEP_DAYS

Only keep last number of days backup files in the storage system. Set to `0` to keep all backup files.

Default: `1`

#### TIMEZONE

You should set the available timezone name. Currently only used in mail.

Here is timezone list at [wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Default: `UTC`

### Notifications using SENDXMPP

#### SENDXMPP_ENABLE

To enable, or otherwise, XMPP notifications.

Default: `FALSE`

#### SENDXMPP_WHEN_SUCCESS

To enable XMPP notification on successful completion.

Default: `FALSE`

#### SENDXMPP_WHEN_FAILURE

To enable XMPP notification of failure.

Default: `FALSE`

#### SENDXMPP_USER

Username of sending XMPP user. Required if SENDXMPP_ENABLE is true.

Default: ``

#### SENDXMPP_PASSWORD

Password of sending XMPP user. Required if SENDXMPP_ENABLE is true.

Default: ``

#### SENDXMPP_SERVER

Server of sending XMPP user. Required if SENDXMPP_ENABLE is true.

Default: ``

#### SENDXMPP_RECIPIENT=""

The recipient of the XMPP notifications. Required if SENDXMPP_ENABLE is true.

Default: ``

### MAIL Notification settings

The MAIL notification settings are inherited, and included if they might be of use. They should be considered unsupported.

#### MAIL_SMTP_ENABLE

The tool uses [heirloom-mailx](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) to send mail.

Default: `FALSE`

#### MAIL_SMTP_VARIABLES

Refer to the mailx documentation for the correct usage for your requirements. It's out of scope and unsupported here.

**We will set the subject according to the usage scenario, so you should not use the `-s` option.**


```text
# My example:

# For Zoho
-S smtp-use-starttls \
-S smtp=smtp://smtp.zoho.com:587 \
-S smtp-auth=login \
-S smtp-auth-user=<my-email-address> \
-S smtp-auth-password=<my-email-password> \
-S from=<my-email-address>
```

See [here](https://www.systutorials.com/sending-email-from-mailx-command-in-linux-using-gmails-smtp/) for more information.

#### MAIL_TO

Who will receive the notification email.

#### MAIL_WHEN_SUCCESS

Send email when backup is successful.

Default: `TRUE`

#### MAIL_WHEN_FAILURE

Send email when backup fails.

Default: `TRUE`


## License

MIT
