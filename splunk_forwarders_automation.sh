#################################################################################
#!/bin/sh
#
 HOSTS_FILE="/mnt/nonprod/todelete/host_file"
 SPLUNK_FILE="/mnt/nonprod/todelete/splunkforwarder-6.5.1-Linux-x86_64.tgz"
 INSTALL_DIR="/opt"
 STAGING_DIR="/tmp/staging"
# After installation, the forwarder will become a deployment client of this
# host.  Specify the host and management (not web) port of the deployment server
# that will be managing these forwarder instances.  
#
# DEPLOY_SERV="SplunkDeployMaster:8089"
 DEPLOY_SERV="dev01:8089"
 
# A directory on the current host in which the output of each installation
# attempt will be logged. If installation on a host fails, a
# file will also be created, as $LOG_DIR/<[user@]destination host>.failed.

LOG_DIR="/tmp/splunk-custombox.install"

# ----------- End of user adjustable settings -----------

#################################################################################
faillog() {
  echo "$1" >&2
}

fail() {
  faillog "ERROR: $@"
  exit 1
}

# error checks.


test -z "$HOSTS_FILE" && \
  echo "No hosts configured!  Please populate HOSTS_FILE."
test -z "$INSTALL_DIR" && \
  echo "No installation destination provided!  Please set INSTALL_DIR."
test -z "$SPLUNK_FILE" && \
  echo "No splunk package path provided!  Please populate SPLUNK_FILE."
if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR" || fail "Cannot create log dir at \"$LOG_DIR\"!"
fi

# some setup.

if [ -z "$STAGING_DIR" ]; then
  STAGING_DIR="$INSTALL_DIR"
fi


NEW_INSTANCE="$INSTALL_DIR/splunkforwarder" # this would need to be edited for non-UA...
DEST_FILE="${STAGING_DIR}"

#
#
# create script to run remotely.
#
#

REMOTE_SCRIPT="
  fail() {
    echo ERROR: \"\$@\" >&2
    test -f \"$DEST_FILE\" && rm -f \"$DEST_FILE\"
    exit 1
  }
"

###   try untarring tar file.
REMOTE_SCRIPT="$REMOTE_SCRIPT
  (cd \"$INSTALL_DIR\" && tar -zxf \"$DEST_FILE\") || fail \"could not untar /$DEST_FILE to $INSTALL_DIR.\"
"

###   setup seed file to migrate input records from old instance, and stop old instance.
if [ -n "$OLD_SPLUNK" ]; then
  REMOTE_SCRIPT="$REMOTE_SCRIPT
    echo \"$OLD_SPLUNK\" > \"$NEW_INSTANCE/old_splunk.seed\" || fail \"could not create seed file.\"
    \"$OLD_SPLUNK/bin/splunk\" stop || fail \"could not stop existing splunk.\"
  "
fi

###   setup deployment client if requested.
if [ -n "$DEPLOY_SERV" ]; then
  REMOTE_SCRIPT="$REMOTE_SCRIPT
    \"$NEW_INSTANCE/bin/splunk\" set deploy-poll \"$DEPLOY_SERV\" --accept-license --answer-yes  \
      --auto-ports --no-prompt || fail \"could not setup deployment client\"
  "
fi

###   start new instance.
REMOTE_SCRIPT="$REMOTE_SCRIPT
  \"$NEW_INSTANCE/bin/splunk\" start --accept-license --answer-yes --auto-ports --no-prompt || \
    fail \"could not start new splunk instance!\"
"

###   remove downloaded file.
REMOTE_SCRIPT="$REMOTE_SCRIPT
  rm -f "$DEST_FILE" || fail \"could not delete downloaded file $DEST_FILE!\"
"

#
#
# end of remote script.
#
#

exec 5>&1 # save stdout.
exec 6>&2 # save stderr.

echo "In 5 seconds, will copy install file and run the following script on each"
echo "remote host:"
echo
echo "===================="
echo "$REMOTE_SCRIPT"
echo "===================="
echo
echo "Press Ctrl-C to cancel..."
test -z "$MORE_FASTER" && sleep 5
echo "Starting."

# main loop.  install on each host.

for DST in `cat "$HOSTS_FILE"`; do
  if [ -z "$DST" ]; then
    continue;
  fi

  LOG="$LOG_DIR/$DST"
  FAILLOG="${LOG}.failed"
  echo "Installing on host $DST, logging to $LOG."

  # redirect stdout/stderr to logfile.
  exec 1> "$LOG"
  exec 2> "$LOG" 

  if ! ssh $SSH_PORT_ARG "$DST" \
      "if [ ! -d \"$INSTALL_DIR\" ]; then mkdir -p \"$INSTALL_DIR\"; fi"; then
    touch "$FAILLOG"
    # restore stdout/stderr.
    exec 1>&5 
    exec 2>&6
    continue
  fi

  # copy tar file to remote host.
  if ! scp $SCP_PORT_ARG "$SPLUNK_FILE" "${DST}:${DEST_FILE}"; then
    touch "$FAILLOG"
    # restore stdout/stderr.
    exec 1>&5 
    exec 2>&6
    continue
  fi
    
  # run script on remote host and log appropriately.
  if ! ssh $SSH_PORT_ARG "$DST" "$REMOTE_SCRIPT" "/opt/splunkforwarder/bin/splunk enable boot-start"; then
    touch "$FAILLOG" # remote script failed.
  else
    test -e "$FAILLOG" && rm -f "$FAILLOG" # cleanup any past attempt log.
  fi

  # restore stdout/stderr.
  exec 1>&5 
  exec 2>&6

  if [ -e "$FAILLOG" ]; then
    echo "  -->   FAILED   <--"
  else
    echo "      SUCCEEDED"
  fi
done

FAIL_COUNT=`ls "${LOG_DIR}" | grep -c '\.failed$'`
if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "There were $FAIL_COUNT remote installation failures."
  echo "  ( see ${LOG_DIR}/*.failed )"
else
  echo
  echo "Done."
fi


