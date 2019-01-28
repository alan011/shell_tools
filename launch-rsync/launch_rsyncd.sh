#! /bin/bash

DEFAULT_PORT=873

function write_config() {
    cat > /etc/rsyncd.conf << EOF
uid=nobody
gid=nobody
use chroot=no
max connections=4
pid file = /var/run/rsync.pid
lock file = /var/run/rsync.lock
log file = /var/log/rsyncd.log
secrets file = /etc/rsync.passwd

[files]
path = /data1/files/
uid = root
gid = root
read only = yes
hosts allow = 127.0.0.1

[rsync]
path = /data1/rsync/
auth users = lei
uid = root
gid = root
read only = no
EOF
}

function launch_rsyncd() {
    rsyncd_port=$1
    if [ -f /var/run/rsync.pid ]; then
        true_pid=`ps -ef | grep rsyncd | grep -v grep | awk '{print $2}'`
        record_pid=`cat /var/run/rsync.pid`
        if [ "$true_pid" == "$record_pid" ]; then
            kill -9 $record_pid
        fi
        rm -f /var/run/rsync.pid
    fi
    mkdir -p /data1/files/
    mkdir -p /data1/rsync/
    echo 'lei:1234.lei.com' > /etc/rsync.passwd && chmod 600 /etc/rsync.passwd
    rsync --daemon --config=/etc/rsyncd.conf --port=$rsyncd_port

    echo "===> INFO: rsyncd started.
config_file: /etc/rsyncd.conf
server_side_path: /data1/files/
client_side_path:  '::files/'"
server_side_auth_path: /data1/rsync/
client_side_auth_path:  '::rsync/'
user: lei
password: 1234.lei.com
"

}

#----------------- main --------------------

if [ ! -f /etc/rsyncd.conf ]; then
    write_config
fi

port=$DEFAULT_PORT
if [ -n "$1" ]; then
    if [[ $1 =~ [0-9]{4,5} ]]; then
        port=$1
    else
        echo "===> ERROR: Wrong port assigned: $1"
        echo -e "Please use 1000~65535 as server port.\n"
        echo  "Now use default port: 873"
    fi
fi

launch_rsyncd $port
