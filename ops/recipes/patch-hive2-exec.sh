#!/bin/sh
set -e

# setup a script that when executed, will check that the current hive-exec jar is the correct one, if not, it will replace the jar
cat >/tmp/auto-patch-hive-exec.sh <<"EOL"
#!/bin/sh
set -e

# Download the patched hive-exec jar from s3 if it's not already there
HIVE_EXEC_JAR=hive-exec-2.1.0.2.6.1.0-f3f96b4c2d6bc7edff537a817ef2ac5a053b16c6.jar
HIVE_EXEC=/tmp/$HIVE_EXEC_JAR
if [ ! -f "$HIVE_EXEC" ]; then
    echo "Downloading new hive-exec jar to $HIVE_EXEC"
    aws s3 cp s3://bdap-private-artifacts/lib/hive-exec/$HIVE_EXEC_JAR $HIVE_EXEC 
fi

# Compare the current and the remote version, if they are not the same file, then replace them
CURRENT_HIVE_EXEC_JAR=/usr/hdp/2.6.1.0-129/hive2/lib/hive-exec-2.1.0.2.6.1.0-129.jar
CURRENT_HIVE_EXEC=`ls -l $CURRENT_HIVE_EXEC_JAR | awk '{print $5}'`
REMOTE_HIVE_EXEC=`ls -l $HIVE_EXEC | awk '{print $5}'`

if [ "$CURRENT_HIVE_EXEC" -ne "$REMOTE_HIVE_EXEC" ]; then
    echo "Replace the current hive-exec at $CURRENT_HIVE_EXEC_JAR with a new lib at $HIVE_EXEC"
    cp -f $HIVE_EXEC $CURRENT_HIVE_EXEC_JAR
fi
EOL

# add execute permission to the script
chmod +x /tmp/auto-patch-hive-exec.sh

# register the script to run every minute
echo "* * * * * root /tmp/auto-patch-hive-exec.sh >> /var/log/auto-patch-hive-exec.log 2>&1" > /etc/cron.d/auto-patch-hive-exec-monitor
