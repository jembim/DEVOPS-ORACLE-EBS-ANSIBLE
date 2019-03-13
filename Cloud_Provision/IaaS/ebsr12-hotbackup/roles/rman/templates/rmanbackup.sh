#Script name: RmanBackup.sh
# Description: RMAN backup script
#       Usage: nohup ./RmanBackup SID (Full|Incr|Arch)
#     Created: Jovi 08/11/2016
#     Version: V3
#
######################################################################
#----------------------------------------
# FUNCTION DEFINITIONS :
#----------------------------------------

Do_Level0(){
rman target / nocatalog << EOF >$logfile
run {
allocate channel fs1 type disk;
allocate channel fs2 type disk;
allocate channel fs3 type disk;
allocate channel fs4 type disk;
backup format='$BAKDIR/${SID}_FulLvl0_%u.%p'  AS COMPRESSED BACKUPSET incremental level 0 database    include current controlfile;
backup format='$BAKDIR/${SID}_Control_%u.%p' current controlfile ;
sql 'alter system archive log current';
sql 'alter system archive log current';
sql 'alter system archive log current';
sql 'alter system archive log current';
sql 'alter system archive log current';
CROSSCHECK ARCHIVELOG ALL;
backup format='$BAKDIR/${SID}_Archlog_%u.%p' archivelog all ;
backup format='$BAKDIR/${SID}_Control_%u.%p' current controlfile ;
#delete noprompt archivelog all backed up 1 times to DEVICE TYPE disk;
release channel fs1;
release channel fs2;
release channel fs3;
release channel fs4;
}
exit;
EOF
}

Do_Level1(){
rman target / nocatalog << EOF >$logfile
run {
allocate channel fs1 type disk;
allocate channel fs2 type disk;
allocate channel fs3 type disk;
allocate channel fs4 type disk;
backup format='$BAKDIR/${SID}_IncLvl1_%u.%p'  AS COMPRESSED BACKUPSET incremental level 1 database    include current controlfile;
backup format='$BAKDIR/${SID}_Control_%u.%p' current controlfile ;
sql 'alter system archive log current';
sql 'alter system archive log current';
sql 'alter system archive log current';
sql 'alter system archive log current';
sql 'alter system archive log current';
CROSSCHECK ARCHIVELOG ALL;
backup format='$BAKDIR/${SID}_Archlog_%u.%p' archivelog all ;
backup format='$BAKDIR/${SID}_Control_%u.%p' current controlfile ;
#delete noprompt archivelog all backed up 1 times to DEVICE TYPE disk;
release channel fs1;
release channel fs2;
release channel fs3;
release channel fs4;
}
exit;
EOF
}

Do_ArchOnly(){
rman target / nocatalog << EOF >$logfile
run {
allocate channel fs1 type disk;
allocate channel fs2 type disk;
allocate channel fs3 type disk;
allocate channel fs4 type disk;
CROSSCHECK ARCHIVELOG ALL;
backup format='$BAKDIR/${SID}_Archlog_%u.%p' archivelog all ;
backup format='$BAKDIR/${SID}_Control_%u.%p' current controlfile ;
#delete noprompt archivelog all backed up 1 times to DEVICE TYPE disk;
release channel fs1;
release channel fs2;
release channel fs3;
release channel fs4;
}
exit;
EOF
}

Do_BakCleanUp(){
rman target / nocatalog << EOF >$logfileB
run {
allocate channel fs1 type disk;
allocate channel fs2 type disk;
CROSSCHECK BACKUP;
DELETE NOPROMPT EXPIRED BACKUP;
DELETE NOPROMPT OBSOLETE RECOVERY WINDOW OF 8 DAYS;
delete noprompt backup completed before 'sysdate-8';
release channel fs1;
release channel fs2;
}
exit;
EOF
}


#----------------------------------------
# INITIAL PREPARATIONS :
#----------------------------------------
. ~/.bashrc

export ORACLE_BASE={{ oracle_base }}
export ORACLE_HOME={{ oracle_home }}
export ORACLE_SID=$1

ORAENV_ASK=NO
export PATH=/usr/local/bin:$PATH
. /home/oracle/db.env
#. /usr/local/bin/oraenv
# ORAENV sets ORACLE_HOME,TNS_ADMIN,ORA_NLS
echo  $PATH $ORACLE_SID $ORACLE_BASE $ORACLE_HOME

export SID=$1
export BAKTYP=$2
export VDATE={{ date }}
export BAKDIR="{{ rman_backup_dir }}/{{ backup_name }}"
export BAKDIR2="{{ rman_backup_dir }}/RMAN_Summary_Status"
export NOTIFY=/u01/dbscripts/cron
export PETSANOW=`date +%d-%b-%y`
export START_TIME=`date +%T`
export HOST_NAME=$1
export BAKNAME={{ backup_name }}

/bin/ps -ef | grep smon | grep $1 > /dev/null
if [ $? -eq 1 ]
 then
  echo "ATTENTION ! Target SID is Not Reachable"
  exit
fi

/bin/mkdir -p $BAKDIR

logfile="$BAKDIR/rman_${SID}_${BAKTYP}-{{ date }}.log"
logfileB="$BAKDIR/rman_${SID}_${BAKTYP}-{{ date }}B.log"
logfile2="$BAKDIR2/RMAN_Backup_Status_Summary.log"

#----------------------------------------
# MAIN PROGRAM :
#----------------------------------------

case $2 in
    "Full") Do_Level0;;
    "Incr") Do_Level1;;
    "Arch") Do_ArchOnly;;
         *) echo " No Backup Type (Full, Incr or Arch) specified !";;
esac

Do_BakCleanUp

echo $logfile
ls -lrth $BAKDIR >>  $logfile

egrep -i 'ERROR|RMAN-|ORA-' $logfile > /dev/null 2>&1

### NOTES ##########################
# 1. /u02/backup/rman and /u02/backup/SCR should be existing
# 2. database should be in acrhivelog mode
# 3. script should be tested first from commandline and from cron