##########################################################
##      init script for docker ddclient                 ##
## sets up system to run ddclient every 5 minutes or    ##
## at interval specified in config file                 ##
##########################################################
# timestamp for docker logs
startuptime=$(date +"%r")
echo "startup at $startuptime"

# create ddclient directories
echo "creating cache and pid directories"
mkdir -p \
    /var/cache/ddclient \
    /var/run/ddclient

[[ ! -e /config/ddclient.conf ]] && \
    cp /defaults/ddclient.conf /config

# copy config to working directory
echo "copying config"
cp /config/ddclient.conf /ddclient.conf

# set perms
echo "setting permissions"
chown -R 0:0 \
    /config \
    /var/cache/ddclient \
    /var/run/ddclient \
    /ddclient.conf

chmod 700 /config
chmod 600 \
    /config/* \
    /ddclient.conf

echo "starting ddclient!"

# get update interval from config
daemon="$(cat ddclient.conf | grep daemon | grep -Eo '[0-9]{1,4}')"

# check if update interval exists in config, otherwise set default 5 minute update
if test -z "$daemon"
then
    timer=300
else
    timer=$daemon
fi

# start loop
while [ 1 ]
do
    now=$(date +"%r")
    echo "[$now]: updating" # timestamp update run for docker logs
    /usr/bin/ddclient -foreground -daemon=0 -noquiet -file /ddclient.conf
    sleep $timer
done