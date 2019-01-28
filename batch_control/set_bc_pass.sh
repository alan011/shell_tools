#! /bin/bash

passwd_salt="THIS_IS_JUST_SOME_SALT"
passwd_file="/etc/batch_control/password.setting"

function check_passwd() {
	[ ! -f $passwd_file ] && echo "===> ERROR: Password file missing." && exit 1
	bc_passwd=`cat $passwd_file|head -1`

	read -p "old password: " -s input_1
	printf "\n"
	p1=`echo $input_1 | md5sum | awk '{print $1}'`
	p2=`echo ${p1}${passwd_salt} | md5sum | awk '{print $1}'`
	if [ "$p2" != "$bc_passwd" ]; then
		echo "Password incorrect. Exit now." 
		exit 0
	fi
	
}

function set_passwd() {
	read -p "new password: " -s input_2
	printf "\n"
	read -p "confirm new password:" -s input_3
	printf "\n"
	[ "$input_2" != "$input_3" ] && echo "New password confirm failed. Exit now." && exit 1
	new_p1=`echo $input_2 | md5sum | awk '{print $1}'`
	new_p2=`echo ${new_p1}${passwd_salt} | md5sum | awk '{print $1}'`
	echo $new_p2 >  $passwd_file
}

#------------------------------- main ------------------

check_passwd
set_passwd 
