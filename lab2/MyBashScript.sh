#!/bin/bash -e

lockfile=/tmp/AnikeevLockFile
if (set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
	trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
else
	echo "script is already running in thread No: $(cat $lockfile)"
	exit 2
fi

filename=$1
if [ -n "$1" ]
then
	echo "got parameter: $1"
else
	echo "file undefined"
	exit 10
fi

if [ -e "$filename" ]
then
	echo "$filename exists"
else
	echo "$filename doesn't exist"
	exit 20
fi

if [ -r "$filename" ]
then
	echo "$filename is available for reading"
else
	echo "cannot open $filename for reading"
	exit 3
fi

last=.logparser.last
if [ -e "$last" ]
then
	timestart=$( cat $last) 
else
	touch .logparser.last
	timestart=$( head $filename -n 1 | awk '{print $4}' | cut -c2- )
fi

timestop=$( tail $filename -n 1 | awk '{print $4}' | cut -c2- )
echo $timestop > $last
echo processing log from $timestart to $timestop:
timestart=$( echo $timestart | sed 's|/|\\/|g' | sed 's|:|\\:|g')

echo
echo top 15 IP\'s:
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $1}' | sort | uniq -c | sort -rn| head -n 15

echo
echo top 15 resources:
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 15

echo
echo return codes count:
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $9}' | grep ^[^45] | sort | uniq -c | sort -n

echo
echo error return codes count:
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $9}' | grep ^[45]| sort | uniq -c | sort -n








