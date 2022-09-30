# lldap-backup
A simple backup container to dump an sqlite database for nitnelave/lldap

# sqlite_back
<br>
Simple backup container to backup an sqlite database

<br>

Code structure and logic largely from ttionya/sqlite-backup
https://github.com/ttionya/sqlite-backup

<br>

## Intended use

Written as simple backup container to dump an sqlite database for nitnelave/lldap (but may be used for other sqlite databases)
https://github.com/nitnelave/lldap

<br>

### 

Backups to rclone storage system (defaults to local), using cron to set activate, with retention policy, and the possibility of notifications by email or xmpp.

<br>

## Usage Note

Using the default settings, which are to backup locally, with a retention of one (in days), the container acts as a periodic (set by cron) database dump. In order to provide effective backup this dump must be included as part of a wider backup scheme. Alternatively a non-local rclone storage system may be used, and retention increased, to provide a simple backup scheme from this container alone.

# run container
  
podman run -d --name sqlite-backup -v /var/lib/lldap:/bitwarden/data/ -v /var/lib/sqlite-backup:/config/ -v /backup/sqlite_vw/:/backup/ -e RCLONE_REMOTE_NAME=vw_back -e RCLONE_REMOTE_DIR=/backup/ -e CRON="45 23 * * *" -e ZIP_ENABLE=FALSE -e BACKUP_KEEP_DAYS=1 c8n.io/tetricky/ttionya/sqlite-backup:latest

## Environment Variables

> **Note:** All environment variables have default values, and you can use the docker image without setting environment variables.

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

Compress the backup file as Zip archive. When set to `'TRUE'`, only upload `.sqlite3` files with compression.

Default: `FALSE`

#### ZIP_PASSWORD

Set your password to encrypt Zip archive. Note that the password will always be used when compressing the backup file.

Default: `password`

#### BACKUP_KEEP_DAYS

Only keep last number of days backup files in the storage system. Set to `0` to keep all backup files.

Default: `1`

#### TIMEZONE

You should set the available timezone name. Currently only used in mail.

Here is timezone list at [wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Default: `UTC`

#### MAIL_SMTP_ENABLE

The tool uses [heirloom-mailx](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) to send mail.

Default: `FALSE`

#### MAIL_SMTP_VARIABLES

Because the configuration for sending emails is too complicated, we allow you to configure it yourself.

**We will set the subject according to the usage scenario, so you should not use the `-s` option.**

When testing, we will add the `-v` option to display detailed information.

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



## Mail Test

You can use the following command to test the mail sending. Remember to replace your smtp variables.

```shell
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' karbon15/etebase-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' karbon15/etebase-backup:latest mail
```



## License

MIT
