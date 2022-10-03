# sqlite-backup

## Intended use

A simple backup container to dump an sqlite database for nitnelave/lldap. By adjusting the environment variables this might also be backup container for any sqlite3 database

Code structure and logic largely from ttionya/sqlite-backup
https://github.com/ttionya/sqlite-backup
with further modifications from  karbon15/EteBase-Backup
https://github.com/karbon15/EteBase-Backup


Dumps the sqlite database to rclone storage system backend (defaults to local filesystem), using cron to automate, with a simple retention policy, and the possibility of notifications by email and/or xmpp.


### Feature

This tool supports backing up the following file.

- `users.db`

In the event that the sqlite database is named differently, this can be set using the `DB_NAME` environment variable.

### Building the container

Clone the repository.

```
git clone https://github.com/tetricky/sqlite-backup.git
```

From the root directory build (using podman which is out of scope here, docker should also work) with:

```
podman build -t tetricky/sqlite-backup:latest -f Containerfile
```

#### Usage Note

Using the default settings, which are to backup locally, with a retention of two (see retention note), the container acts as a periodic (set by cron) database dump. In order to provide effective backup this dump must be included as part of a wider backup scheme. Alternatively a non-local rclone storage system may be used, and retention increased, to provide a simple backup scheme from this container alone.

Retention is set by `FILES_TO_KEEP` (default `2`). This works very simply and retains `FILES_TO_KEEP` number of files in the rclone storage backend (local filesystem by default). The first file is `report` This provides a basic log of the last backup run. Subesquent files are timestamped dumps of the sqlite database. `FILES_TO_KEEP` of `1` will only save the report (for testing purposes), A `FILES_TO_KEEP` of `5` would save the report and 4 timestamped database dumps. A `FILES_TO_KEEP` of `0` retains all files uploaded to the storage backend.

The periodicity of backups (set by `CRON`) in conjunction with the number of files retained will determine the period that backups will cover. Further archive or backups of these files (I use [Borgmatic](https://torsion.org/borgmatic/)) should be used to ensure the backup coverage that is required.

Using environment variables the periodicity and retention can be increased, and any rclone target can be used to achieve direct backup.

### Automatic Backups

#### Running the default container

In the event that default settings are used, and the container is used to backup to a rclone storage backend on the local filesystem, then the storage backend location within the container must be mounted to the host computer in order to easily access the files outside the container.

```
podman run -d --name lldap-backup -v [host_lldap_database_directory]:/sqlitedata -v [host_backup_directory]:/sqliteback tetricky/sqlite-backup:latest
```
This is an equivalent run command, which might prove useful as a template to adjust environment variables for a specific use case.

```
podman run -d --name lldap-backup \
-v [host_lldap_database_directory]:/sqlitedata \
-v [host_backup_directory]:/sqliteback \
-e CRON="5 0 * * *" \
-e FILES_TO_KEEP="2" \
-e MAIL_SMTP_ENABLE="FALSE" \
-e MAIL_SMTP_VARIABLES="" \
-e MAIL_TO="" \
-e SENDXMPP_ENABLE="FALSE" \
-e SENDXMPP_USER="" \
-e SENDXMPP_PASSWORD="" \
-e SENDXMPP_RECIPIENT="" \
-e TIMEZONE="UTC" \
tetricky/sqlite-backup:latest
```

### LLDAP Note

It should be noted that by default this backup script only dumps the sqlite3 database. To fully restore an lldap installation it may be necessary to also backup other files (`lldap_config.toml` `private_key`). This backup just addresses the database.

#### storage backend

By default we use [Rclone](https://rclone.org/docs/) to backup to the local filesystem. This can be exposed by mapping the backup directory in the container (by default "/sqliteback" - the `RCLONE_REMOTE_DIR` environment variable) to the host filesystem. This happens once a day, at five past midnight.

In order to change the storage backend make a rclone.conf file on the host and map it to /root/.config/rclone/rclone.conf in the container.

Note that you need to set the environment variable `RCLONE_REMOTE_NAME` to match the remote name in your rclone.conf file.

It is also possible to mount the 

### Automatic Backups

run container using podman
  
```
podman run -d --name lldap-backup -v [host sqlite database directory]:/sqlitebackup/data/ -v [host sqlite backup directory]:/sqliteback/ -v :/config/rclone/rclone.conf tetricky/sqlite-backup:latest
```

### Restore

There is intentionally no restore routine built into the container. sqlite3 databases are simple files. Copying the backed up database into the location of the source will restore the database to the backup. The container using the database should be stopped before doing this. This is destructive. Note - If deleting the original database you will also want to delete any .db-shm or db-wal file before copying in the backed up database and restarting the container.

## Environment Variables

> **Note:** All environment variables have default values, and you can use the docker/podman image without setting environment variables.

#### DATA_DIR

The location of the database to be backed up.

Default: `/sqliteback/data`

#### BACKUP_DIR

The location of the backups created to be copied to the storage backend.

Default: `/backup`


#### DB_NAME

The name of the sqlite database to be backed up.

Default: `users.db`

#### RCLONE_REMOTE_NAME

Rclone remote name, to upload the database dumps to. Must match the rclone.conf settings.

Default: `sqlitebackup`

#### RCLONE_REMOTE_DIR

Folder for storing backup files rclone storage system.

Default: `/sqliteback/`

#### CRON

Schedule run backup script, based on Linux `crond`. You can test the rules [here](https://crontab.guru/#5_*_*_*_*).

Default: `5 0 * * *` (run the script at 5 minutes past midnight every day)

#### FILES_TO_KEEP

The number of files in the backup storage system to retain. A value of `1` will retain only the backup report, NOT any backups (for testing purposes). The minimum value to retain a backup is `2`. Set to `0` to keep all backup files.

Default: `2`

#### TIMEZONE

You should set the available timezone name. Currently only used in mail.

Here is timezone list at [wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Default: `UTC`

### Notifications using SENDXMPP

A trypical notification will look similar to this:

```
backup.sh run for users.db at 2022-10-03 00:05:00 BST
check_rclone_connection(): sqlitebackup Initialising
backup_db(): backup sqlite database
-rw-r--r--    1 root     root       40.0K Oct  3 00:05 /backup/2022-10-03-00:05-users.db
upload(): upload backup file to storage system
clear_history(): keep only 2 file(s)
clear_history(): deleting 2022-10-02-00:05-users.db
    40960 2022-10-03 00:05:00.672655984 2022-10-03-00:05-users.db
      279 2022-10-03 00:05:00.708656089 report
send_xmpp_report(): sendxmpp successful
send_mail(): mailx send successful
```

#### SENDXMPP_ENABLE

To enable (`TRUE`), or otherwise, XMPP notifications.

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

### Notifications using mailx

#### MAIL_SMTP_ENABLE

To enable (`TRUE`), or otherwise, email notifications. The tool uses [heirloom-mailx](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) to send mail.

Default: `FALSE`

#### MAIL_TO

The recipient of the mailx notifications. Required if MAIL_SMTP_ENABLE is true.

Default: ``

#### MAIL_SMTP_VARIABLES

Defines how the email notification is sent. Refer to the mailx documentation for the correct usage for your requirements. It's out of scope and unsupported here.

**We will set the subject according to the usage scenario, so you should not use the `-s` option.**

As an example to send notifications using a zoho account and server.

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
These settings would translate to an environment variable of:

```
MAIL_SMTP_VARIABLES="-S smtp-use-starttls -S smtp=smtp://smtp.zoho.com:587 -S smtp-auth=login -S smtp-auth-user=<my-email-address> -S smtp-auth-password=<my-email-password> -S from=<my-email-address>"
```

See [here](https://www.systutorials.com/sending-email-from-mailx-command-in-linux-using-gmails-smtp/) for more information.

## License

MIT
