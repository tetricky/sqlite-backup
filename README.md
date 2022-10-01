# lldap-backup
A simple backup container to dump an sqlite database for nitnelave/lldap

# sqlite_back
<br>
By adjusting the environment variables this might also be backup container for any sqlite database

<br>

Code structure and logic largely from ttionya/sqlite-backup
https://github.com/ttionya/sqlite-backup
with further modifications from  karbon15/EteBase-Backup
https://github.com/karbon15/EteBase-Backup

<br>

## Intended use

Written as simple backup container to dump an sqlite database for nitnelave/lldap (but may be used for other sqlite databases)
https://github.com/nitnelave/lldap

<br>

### 

Backups to rclone storage system (defaults to local), using cron to set activate, with retention policy, and the possibility of notifications by email or xmpp (TBC).

<br>

## Feature

This tool supports backing up the following file.

- `users.db`


## Usage Note

Using the default settings, which are to backup locally, with a retention of one (in days), the container acts as a periodic (set by cron) database dump. In order to provide effective backup this dump must be included as part of a wider backup scheme. Alternatively a non-local rclone storage system may be used, and retention increased, to provide a simple backup scheme from this container alone.

Using environment variables the regularity and retention can be increased, and any rclone target can be used to achieve direct backup.

### Backup

We upload the backup files to the storage system by [Rclone](https://rclone.org/).

Visit [GitHub](https://github.com/rclone/rclone) for more storage system tutorials. Different systems get tokens differently.

You can get the token by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=etebase-rclone-data,target=/config/ \
  karbon15/etebase-backup:latest \
  rclone config
```

After setting, check the configuration content by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=etebase-rclone-data,target=/config/ \
  karbon15/etebase-backup:latest \
  rclone config show

# Microsoft Onedrive Example
# [YouRemoteName]
# type = onedrive
# token = {"access_token":"access token","token_type":"token type","refresh_token":"refresh token","expiry":"expiry time"}
# drive_id = driveid
# drive_type = personal
```

Note that you need to set the environment variable `RCLONE_REMOTE_NAME` to a remote name like `YouRemoteName`.


#### Automatic Backups

Make sure that your etebase container is named `etebase` otherwise you have to replace the container name in the `--volumes-from` section of the docker run call.

Start backup container with default settings (automatic backup at 5 minute every hour)

```shell
docker run -d \
  --restart=always \
  --name etebase_backup \
  --volumes-from=etebase \
  --mount type=volume,source=etebase-rclone-data,target=/config/ \
  -e RCLONE_REMOTE_NAME="YouRemoteName"
  karbon15/etebase-backup:latest
```


# run container using podman
  
podman run -d --name sqlite-backup -v /var/lib/lldap:/sqlitebackup/data/ -v /var/lib/sqlite-backup:/config/ -v /backup/sqlite_vw/:/backup/ -e RCLONE_REMOTE_NAME=vw_back -e RCLONE_REMOTE_DIR=/backup/ -e CRON="45 23 * * *" -e ZIP_ENABLE=FALSE -e BACKUP_KEEP_DAYS=1 c8n.io/tetricky/ttionya/sqlite-backup:latest


### Restore

> **Important:** Restore will overwrite the existing files.

You need to stop the Docker container before the restore.

Because the host's files are not accessible in the Docker container, you need to map the directory where the backup files that need to be restored are located to the docker container.

And go to the directory where your backup files are located.

If you are using automatic backups, please confirm the etebase volume and replace the `--mount` `source` section.

```shell
docker run --rm -it \
  --mount type=volume,source=etebase-data,target=/etebase/data/ \
  --mount type=bind,source=$(pwd),target=/etebase/restore/ \
  karbon15/etebase-backup:latest restore \
  [OPTIONS]
```

See [Options](#options) for options information.

#### Options

##### --db-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `db.sqlite3` file.

##### --config-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `etebase-server.ini` file.

##### --media-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `attachments.tar` file.

##### --secret-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `secret.txt` file.


##### --zip-file

If you set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `backup-etebase.zip` file.

Make sure the file name in the zip file has not been changed.

##### -p / --password

THIS IS INSECURE!

If the `backup-etebase.zip` file has a password, you can use this option to set the password to unzip it.

If not, the password will be asked for interactively.



## Environment Variables

> **Note:** All environment variables have default values, and you can use the docker/podman image without setting environment variables.

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

Compress the backup file as Zip archive. When set to `'TRUE'`, only upload `.sqlite3` files with compression.

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

### The SENDXMPP notification settings are currently a stub, and yet to be implimented

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

### The MAIL notification settings are inherited, and included if they might be of use. They should be considered unsupported.

#### MAIL_SMTP_ENABLE

The tool uses [heirloom-mailx](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) to send mail.

Default: `FALSE`

#### MAIL_SMTP_VARIABLES

Refer to the mailx documentation for the correct usage for your requirements. It's out of scope and unsupported here.

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
podman run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' tetricky/lldap-backup:latest mail <mail send to>

# Or

podman run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' tetricky/lldap-backup:latest mail
```


## License

MIT
