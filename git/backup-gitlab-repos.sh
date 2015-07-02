#!/bin/bash
# this script should pack git repos into bundle file
# restoration:
# git clone --mirror backup_file new_empty_dir/.git"
REPOSDIR="/home/git/repositories"
DSTDIR="/data0/backup/git"
log="/opt/backuptool/backup.log"

#DSTDIR="${REPOSERVER}:mycompany/${PRJNAME}.git"
DATEFMT=$(LC_ALL=C date +'%Y%m%d%H%M%S')


[[ -d "${DSTDIR}" ]] || mkdir $DSTDIR

if [[ ! -d "${REPOSDIR}" ]]; then
    exit 1
fi

# iterating over dir list
for user in "${REPOSDIR}"/*; do
    for i in "$user"/*.git; do
        # cutting off ".git" suffix
        uname=$(basename $user)
        rname=${i//.git/}
        rname=$(basename "$rname")
        if [[ $rname = "*" ]]; then
            continue
        fi
        [[ -d "${DSTDIR}/${uname}" ]] || mkdir -p "${DSTDIR}/${uname}"
        CMD="cd $i && git bundle create ${DSTDIR}/${uname}/${rname}.${DATEFMT}.gitbundle --all --remotes"
        sh -c "$CMD" >/dev/null 2>&1
    done
done

echo "$(date '+%Y-%m-%d %T') :git repos local backup done" >>$log

# Remove backups older than 2 days
/usr/bin/find $DSTDIR -maxdepth 3 -type f -mtime +2 -exec rm -rf {} \;
echo "$(date '+%Y-%m-%d %T') :git repos remote backup begin" >>$log
rsync -a -r -e 'ssh -p 22' --timeout=300 --delete-after $DSTDIR root@remote.server:/backup/git
if [ $? -eq 0 ]; then
   echo "$(date '+%Y-%m-%d %T') :git repos remote backup done" >>$log
else
   echo "$(date '+%Y-%m-%d %T') :git repos remote backup failed" >>$log
fi
