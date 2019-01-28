#! /bin/bash

ip_list=$1
script=$2
args="$3 $4 $5 $6 $7"

time_now=`date +'%Y%m%d_%H%M%S'`
log_dir='log'

no_passwd='--no-passwd'
echo "$args" | grep '\-\-passwd' > /dev/null
[ $? -eq 0  ] && no_passwd='--passwd' && args=`echo $args | sed 's/--passwd//g'`

function control_single_ip() {
	echo $1 | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' > /dev/null
	if [ $? -eq 0 ]; then
		mkdir -p $log_dir/$1
		log_file=$log_dir/$1/${script_real}-${time_now}.log
		echo -e "\n==== $1:"
        
        if [ "$no_passwd" == '--passwd' ]; then
		    /usr/bin/expect sub/auto_ssh.exp $1 $2 | tee -a $log_file 
        else
		    /bin/bash sub/auto_ssh.sh $1 $2 | tee -a $log_file
        fi 
	else
		echo -e "\n===> ERROR: not a ip: $1"
	fi
}

function exe_confirm() {
	echo -e "\n======== script contents:"
	cat $script
	echo -e "\n======== target ip list:"
	if [ "$1" == 'ip' ]; then
		echo $ip_list
	elif [ "$1" == 'ip_list' ]; then
		cat $ip_list
	else	
		echo "===> ERROR: exe_confirm() wrong usage."
		exit 1
	fi

	read -p "===> continue? [y/n]" answer
        if [ "$answer" != 'y' ]; then
                echo "OK, Now quit with nothing change."
                exit 0
	fi
}

passwd_salt="THIS_IS_JUST_SOME_SALT"
passwd_file="/etc/batch_control/password.setting"
function check_passwd() {
        [ ! -f $passwd_file ] && echo "===> ERROR: Password file missing." && exit 1
	echo "===> Password check..."
        bc_passwd=`cat $passwd_file|head -1`

        read -p "Password: " -s input_1
	printf "\n"
        p1=`echo $input_1 | md5sum | awk '{print $1}'`
        p2=`echo ${p1}${passwd_salt} | md5sum | awk '{print $1}'`
        if [ "$p2" != "$bc_passwd" ]; then
                echo "Password incorrect. Exit now." 
                exit 0
        fi

}

function grep_dangerous_command() {
	echo "===> Checking script contents..."
	cat $script | egrep 'init[[:blank:]]*|reboot[[:blank:]]*|halt[[:blank:]]*|shutdown[[:blank:]]*|rm[[:blank:]]+.*-(rf|fr)'
	if [ $? -eq 0 ]; then
		echo "===> ERROR: Dangerous command found in script: '$script'"
		echo "Remote control will not be execute. Exit now."
		exit 1
	else
		echo "Script contents is OK."
	fi
}

function end_work() {
	echo -e "\n===> RUN TIME: $time_now"
	[ ! -f .BATCH_TIME_HISTORY ] && touch .BATCH_TIME_HISTORY
	next_num=`cat .BATCH_TIME_HISTORY | nl | awk '{print $1}' | tail -1`
	if [ "$next_num" == "" ]; then
		echo $time_now > .BATCH_TIME_HISTORY
	elif [ $next_num -eq 10 ]; then
		cat .BATCH_TIME_HISTORY | tail -9 > .BATCH_TIME_HISTORY.tmp
		echo $time_now >> .BATCH_TIME_HISTORY.tmp
		cat .BATCH_TIME_HISTORY.tmp > .BATCH_TIME_HISTORY
		rm -f .BATCH_TIME_HISTORY.tmp
	else
		echo $time_now >> .BATCH_TIME_HISTORY
	fi
	
}
	


#----------------------- main ------------------------

[ -z $ip_list ] && echo "===> ERROR: Need ip or ip_list_file, as '\$1'." && exit 1
[ -z $script ] && echo "===> ERROR: Need a script for remote execute, as '\$2'." && exit 1
script_real=`basename $script`
[ ! -f "/home/sre/batch_control/server_init/$script_real" ] && echo "===> ERROR: Script assigned must be in dir: /home/sre/batch_control/server_init/" && exit 1

check_passwd
#grep_dangerous_command

if [ ! -f $ip_list ]; then
	exe_confirm  ip 
	control_single_ip $ip_list $script_real
else
	exe_confirm  ip_list
	for target_ip in `cat $ip_list`; do
		control_single_ip $target_ip $script_real
	done
fi

end_work
