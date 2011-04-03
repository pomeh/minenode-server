#!/bin/bash
# /etc/init.d/minecraft
# version 0.3.2 2011-01-27 (YYYY-MM-DD)

### BEGIN INIT INFO
# Provides:   minecraft
# Required-Start: $local_fs $remote_fs
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description:    Minecraft server
# Description:    Starts the minecraft server
### END INIT INFO

#Settings
SERVICE='minecraft_server.jar'
USERNAME="pomeh"
MCPATH='/home/pomeh/minecraft'
CPU_COUNT=1
# INVOCATION="java -Xmx1024M -Xms1024M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPU_COUNT -XX:+AggressiveOpts -jar minecraft_server.jar nogui"
INVOCATION="java -Xmx1024M -Xms1024M -jar minecraft_server.jar nogui"
BACKUPPATH='/home/pomeh/minecraft/backup'

ME=`whoami`
as_user() {
  if [ $ME == $USERNAME ] ; then
    bash -c "$1"
  else
    su - $USERNAME -c "$1"
  fi
}

mc_start() {
  if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
  then
    echo "Tried to start but $SERVICE was already running!"
  else
    echo "$SERVICE was not running... starting."
    cd $MCPATH
    as_user "cd $MCPATH && screen -dmS minecraft $INVOCATION"
    sleep 4 
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
      echo "$SERVICE is now running."
    else
      echo "Could not start $SERVICE."
    fi
  fi
}

mc_send() {
  as_user "screen -p 0 -S minecraft -X eval 'stuff \"$1\"\015'"
}

mc_saveoff() {
        if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
	then
		echo "$SERVICE is running... suspending saves"
                mc_send "say SERVER BACKUP STARTING. Server going readonly..."
                mc_send "save-off"
                mc_send "save-all"
                sync
		sleep 10
	else
                echo "$SERVICE was not running. Not suspending saves."
	fi
}

mc_saveon() {
        if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
	then
		echo "$SERVICE is running... re-enabling saves"
                mc_send "save-on"
                mc_send "say SERVER BACKUP ENDED. Server going read-write..."
                # as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-on\"\015'"
                # as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER BACKUP ENDED. Server going read-write...\"\015'"
	else
                echo "$SERVICE was not running. Not resuming saves."
	fi
}

mc_stop() {
        if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
        then
                echo "$SERVICE is running... stopping."
                mc_send "say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map..."
                mc_send "save-all"
                # as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
                # as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-all\"\015'"
                sleep 10
                mc_send "stop"
                # as_user "screen -p 0 -S minecraft -X eval 'stuff \"stop\"\015'"
                sleep 7
        else
                echo "$SERVICE was not running."
        fi
        if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
        then
                echo "$SERVICE could not be shut down... still running."
        else
                echo "$SERVICE is shut down."
        fi
}


mc_update() {
  if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
  then
    echo "$SERVICE is running! Will not start update."
  else
    MC_SERVER_URL=http://minecraft.net/`wget -q -O - http://www.minecraft.net/download.jsp | grep minecraft_server.jar\</a\> | cut -d \" -f 2`
    as_user "cd $MCPATH && wget -q -O $MCPATH/minecraft_server.jar.update $MC_SERVER_URL"
    if [ -f $MCPATH/minecraft_server.jar.update ]
    then
      if `diff $MCPATH/minecraft_server.jar $MCPATH/minecraft_server.jar.update >/dev/null`
        then 
          echo "You are already running the latest version of $SERVICE."
        else
          as_user "mv $MCPATH/minecraft_server.jar.update $MCPATH/minecraft_server.jar"
          echo "Minecraft successfully updated."
      fi
    else
      echo "Minecraft update could not be downloaded."
    fi
  fi
}

mc_backup() {
   echo "Backing up minecraft world"
   if [ -d $BACKUPPATH/world_`date "+%Y.%m.%d"` ]
   then
     for i in 1 2 3 4 5 6
     do
       if [ -d $BACKUPPATH/world_`date "+%Y.%m.%d"`-$i ]
       then
         continue
       else
         as_user "cd $MCPATH && cp -r world $BACKUPPATH/world_`date "+%Y.%m.%d"`-$i"
         break
       fi
     done
   else
     as_user "cd $MCPATH && cp -r world $BACKUPPATH/world_`date "+%Y.%m.%d"`"
     echo "Backed up world"
   fi
   echo "Backing up the minecraft server executable"
   if [ -f "$BACKUPPATH/minecraft_server_`date "+%Y.%m.%d"`.jar" ]
   then
     for i in 1 2 3 4 5 6
     do
       if [ -f "$BACKUPPATH/minecraft_server_`date "+%Y.%m.%d"`-$i.jar" ]
       then
         continue
       else
         as_user "cd $MCPATH && cp minecraft_server.jar \"$BACKUPPATH/minecraft_server_`date "+%Y.%m.%d"`-$i.jar\""
         break
       fi
     done
   else
     as_user "cd $MCPATH && cp minecraft_server.jar \"$BACKUPPATH/minecraft_server_`date "+%Y.%m.%d"`.jar\""
   fi
   echo "Backup complete"
}


#Start-Stop here
case "$1" in
  start)
    mc_start
    ;;
  stop)
    mc_stop
    ;;
  restart)
    mc_stop
    mc_start
    ;;
  update)
    mc_stop
    mc_backup
    mc_update
    mc_start
    ;;
  send)
    shift
    mc_send "$1"
    ;;
  backup)
    mc_saveoff
    mc_backup
    mc_saveon
    ;;
  status)
    if ps ax | grep -v grep | grep -v -i SCREEN | grep $SERVICE > /dev/null
    then
      echo "$SERVICE is running."
    else
      echo "$SERVICE is not running."
    fi
    ;;

  *)
  echo "Usage: /etc/init.d/minecraft {start|stop|update|backup|status|restart}"
  exit 1
  ;;
esac

exit 0
