#!/bin/bash
# backup git and mysql to local & remote
log="/opt/backuptool/backup.log"
echo "$(date '+%Y-%m-%d %T') :begin to backup git repos" >>$log
/opt/backuptool/git/backup-gitlab-repos.sh >>$log 2>&1
echo "$(date '+%Y-%m-%d %T') :git backup done,begin to backup mysql" >>$log
/opt/backuptool/mysql/mysql_backup.sh >>$log 2>&1
echo "$(date '+%Y-%m-%d %T') :mysql backup done" >>$log
echo "" >>$log
sync;sync;sync
