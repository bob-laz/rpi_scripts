#!/bin/bash

# This script runs on a schedule and deletes plex backups older than x days to free up space 
# on raspberry pi sim card. It then syncs the backup directory for the plex library from the 
# SD card to the external HD. Then it syncs the primary drive /media-big with /media-backup. 
# Finally, it sends me an email with the status of the cron job. 


set -e
exec 2>/home/pi/error_log

TO_EMAIL="blaskowski94@gmail.com"
BACKUP_THRESHOLD=30

on_error() {
  echo "CRON JOB FAILED"
  ERROR_LOG=$(</home/pi/error_log)
  echo "ERROR: $ERROR_LOG"
  echo "JOB FAILED: $ERROR_LOG" | mail -s "CRON FAILED" $TO_EMAIL
}

trap "on_error" ERR

# Delete backups older than X days to free up space on RPI
DELETED_PLEX_BACKUPS=$(find '/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases' -type f -mtime +$BACKUP_THRESHOLD -delete)

# Sync backup directory on SD card with backup directory on external HD
SYNCHED_PLEX_BACKUPS=$(rsync -av --delete '/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/' /mnt/media-big/plex-backups)

MEDIA_BACKUPS=$(rsync -av --delete /mnt/media-big/ /mnt/media-backup)

MESSAGE="Deleted the following Plex backup files:\
\n\n\
$DELETED_PLEX_BACKUPS\
\n\n\
===========================================\
\n\n\
Synched the following Plex backup files to external HD:\
\n\n\
$SYNCHED_PLEX_BACKUPS\
\n\n\
===========================================\
\n\n\
Synched the following media files to backup:\
\n\n\
$MEDIA_BACKUPS
"

echo -e "$MESSAGE" | mail -s "cron completed successfully" $TO_EMAIL

echo -e "$MESSAGE"

