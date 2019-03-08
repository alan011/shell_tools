#!/bin/bash

ssh_port=65532
user="$1"
[ -z "$user" ] && echo  "empty user." && exit 1
[ ! -f $user/hosts ] && echo  "Wrong username." && exit 1
[ ! -f $user/id_rsa ] && echo  "private key missing." && exit 1
[ ! -f $user/id_rsa.pub ] && echo  "pub key missing." && exit 1


rsync_pre="rsync -v -e 'ssh -p $ssh_port'"

function main() {
    targetip=$1
    is_root=$2

    ssh_pre="ssh -n -p $ssh_port  root@$targetip"

    echo -e "\n---> To add user '$user' on host '$targetip'..."
    $ssh_pre "useradd $user && mkdir /home/${user}/.ssh && chmod 0700 /home/${user}/.ssh"
    rsync -v -e "ssh -p $ssh_port" $user/id_rsa.pub root@$targetip:/home/${user}/.ssh/authorized_keys
    $ssh_pre "chown -R ${user}:${user} /home/${user}/.ssh/ && chmod 0600 /home/${user}/.ssh/authorized_keys"

    if [ "$is_root" == "root" ]; then
        echo -e "\n---> To add user with nopasswd root..."
        $ssh_pre "echo '$user ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/${user}_to_root && chmod 0400 /etc/sudoers.d/${user}_to_root"
    else
        echo -e "\n---> To join user '$user' into worker group..."
        $ssh_pre "[ -d /home/worker ] && chmod 0755 /home/worker && usermod $user -G worker"
    fi
}

while read file_line; do
    main $file_line
done < $user/hosts
