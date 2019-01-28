#! /bin/bash

log_dir='log'

echo "==> run history time_stamps (in format: YYYYmmdd_HHSSMM):"
cat .BATCH_TIME_HISTORY | nl
read -p "==> Choose a time_stamp (DEFAULT: last one.): " answer
case $answer in 
	1|2|3|4|5|6|7|8|9|10)
		time_stamp=`cat .BATCH_TIME_HISTORY | sed -n "${answer}p"`
	;;
	*)
		time_stamp=`tail -1 .BATCH_TIME_HISTORY`
esac

for file in `find $log_dir -name "*-${time_stamp}.log"`; do
	echo -e "\n==== $file : "
	cat $file
	read -p '==> Anything to continue. Or "q" to quit:' answer
	[ "$answer" == "q" ] && exit 0
done
