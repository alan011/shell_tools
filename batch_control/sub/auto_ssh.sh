#! /bin/bash

host_ip=$1
script=$2

ssh sre@$host_ip -i /home/sre/.ssh/id_rsa "sudo wget http://10.232.0.72/server_init/$script -O /tmp/$script && sudo /bin/bash /tmp/$script && sudo rm -f /tmp/$script"
