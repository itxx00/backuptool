#!/bin/bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
log="/opt/backuptool/backup.log"
if [ -f $TOP_DIR/backup.conf ]; then
    source $TOP_DIR/backup.conf
else
    echo "cannot find backup.conf"
    exit
fi
# MySQL username and password. chmod this script to 0700.
MYSQL_BASE="/usr/bin/mysql -u $USERNAME -p$PASSWORD"
BACKUP_DATE=$(date +'%Y%m%d%H%M%S')

# If you want to exclude databases, just add them to the egrep expression, pipe separated
#BACKUP_DBS=$($MYSQL_BASE -e 'show databases;'|/bin/egrep -vi "(\+|database|information_schema|performance_schema|mysql|sonar)")

# Backup
for db in $BACKUP_DBS; do
    DB_DIR="$BACKUP_DIR/$BACKUP_DATE/$db"
    TABLES=$($MYSQL_BASE -D $db -e 'show tables;'|/bin/egrep -vi "(\+|tables)")

    # Creating directory and dumping tables
    /bin/mkdir -p $DB_DIR

    for table in $TABLES; do
        /usr/bin/mysqldump -u $USERNAME -p$PASSWORD --add-drop-table $db $table|/bin/gzip -9 > $DB_DIR/$table.gz
    done
done

echo "$(date '+%Y-%m-%d %T') :mysql local backup done" >>$log

# Remove backups older than 4 days
/usr/bin/find $BACKUP_DIR -maxdepth 1 -type d -mtime +4 -exec rm -rf {} \;
echo "$(date '+%Y-%m-%d %T') :mysql remote backup begin" >>$log
rsync -a -r -e 'ssh -p 22' --timeout=300 --delete-after $BACKUP_DIR root@remote.server:/backup/git
if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %T') :mysql remote backup done" >>$log
else
    echo "$(date '+%Y-%m-%d %T') :mysql remote backup failed" >>$log
fi
