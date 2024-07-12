#!/bin/bash

###################################
# @author Andrzej Sobel           #
###################################

LOCK=/var/lock/change_pog.lock
DATEFORMAT="%Y.%m.%d %H:%M:%S"

if [ $UID != 0 ]; then
	echo "[$(date +"$DATEFORMAT")] Must be run as root" 1>&2
	exit 1;
fi

# Lock
if /usr/bin/dotlockfile -p -r 1 $LOCK; then
	:
else
	echo "[$(date +"$DATEFORMAT")] Instance already running" 1>&2   
	exit 1;
fi

# data.txt
# 1 - dir
# 2 - user
# 3 - group
# 4 - directory permissions
# 5 - file permissions
# 6 - executable file permissions
# 7 - preserve executable

while read line
do
	j=$(echo $line|tr "|" "\n")
	data=( $(echo $j) )
	
	DIR=${data[0]}
	USER=${data[1]}
	GROUP=${data[2]}
	DIRPERM=${data[3]}
	FILEPERM=${data[4]}
	EXEPERM=${data[5]}
	EXEPRESERVE=${data[6]}
	
	if [ -d $DIR ]; then

		#echo "[$(date +"$DATEFORMAT")] Started processing $DIR"

		if [ ! -z $DIRPERM ]; then
			p=$(stat --format=%a "$DIR")
			if [ $p != $DIRPERM ]; then
				echo "[$(date +"$DATEFORMAT")] changing permission $p -> $DIRPERM for $DIR"
				chmod -s "$DIR"
				chmod $DIRPERM "$DIR"
			fi
		fi
		
		if [ ! -z $USER ]; then
			u=$(stat --format=%U "$DIR")
			if [ $u != $USER ]; then
				echo "[$(date +"$DATEFORMAT")] changing user $u -> $USER for $DIR"
				chown $USER "$DIR"
			fi
		fi
		
		if [ ! -z $GROUP ]; then
			g=$(stat --format=%G "$DIR")
			if [ $g != $GROUP ]; then
				echo "[$(date +"$DATEFORMAT")] changing group $g -> $GROUP for $DIR"
				chgrp $GROUP "$DIR"
			fi
		fi		

		cd "$DIR"
		
		find -type d -print0 | while read -d $'\0' d
		do
			if [ "$d" != '.' ]  && [ "$d" != '..' ]; then
				if [ ! -z $DIRPERM ]; then
					p=$(stat --format=%a "$d")
					if [ $p != $DIRPERM ]; then
						echo "[$(date +"$DATEFORMAT")] changing permission $p -> $DIRPERM for $d"
						chmod -s "$d"
						chmod $DIRPERM "$d"
					fi
				fi
				
				if [ ! -z $USER ]; then
					u=$(stat --format=%U "$d")
					if [ $u != $USER ]; then
						echo "[$(date +"$DATEFORMAT")] changing user $u -> $USER for $d"
						chown $USER "$d"
					fi
				fi
				
				if [ ! -z $GROUP ]; then
					g=$(stat --format=%G "$d")
					if [ $g != $GROUP ]; then
						echo "[$(date +"$DATEFORMAT")] changing group $g -> $GROUP for $d"
						chgrp $GROUP "$d"
					fi
				fi
			fi
		done
		
		find -type f -print0 | while read -d $'\0' f
		do
			if [ ! -z $FILEPERM ]; then
				p=$(stat --format=%a "$f")
				if [ -x "$f" ] && [ $EXEPRESERVE -eq 1 ]; then
					if [ $p != $EXEPERM ]; then
						echo "[$(date +"$DATEFORMAT")] changing permission $p -> $EXEPERM for $f"
						chmod $EXEPERM "$f"
					fi
				else
					if [ $p != $FILEPERM ]; then
						echo "[$(date +"$DATEFORMAT")] changing permission $p -> $FILEPERM for $f"
						chmod $FILEPERM "$f"
					fi
				fi
			fi

			if [ ! -z $USER ]; then
				u=$(stat --format=%U "$f")
				if [ $u != $USER ]; then
					echo "[$(date +"$DATEFORMAT")] changing user $u -> $USER for $f"
					chown $USER "$f"
				fi
			fi
			
			if [ ! -z $GROUP ]; then
				g=$(stat --format=%G "$f")
				if [ $g != $GROUP ]; then
					echo "[$(date +"$DATEFORMAT")] changing group $g -> $GROUP for $f"
					chgrp $GROUP "$f"
				fi
			fi
		done

		#echo "[$(date +"$DATEFORMAT")] Finished processing $DIR"
	fi
done < $1

#echo -e "\n"

# Unlock
/usr/bin/dotlockfile -u $LOCK

exit 0;


