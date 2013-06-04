#!/bin/bash
# <copyright file="iostat_analysis.sh" organization="FORTH-ICS, Greece">
# Copyright (c) 2007, 2008 All Right Reserved, http://www.ics.forth.gr/
#
# All rights reserved.
# This file is solely the property of FORTH_ICS and is provided
# under a License from the Foundation of Research and Technology - Hellas
# (FORTH), Institute of Computer Science (ICS), Greece, and cannot be
# used or distributed without explicit permission from FORTH, Greece. 
# If you are interested in obtaining a copy of the code please contact:
#
# Angelos Bilas (bilas@ics.forth.gr)
# FORTH-ICS
# 100 N. Plastira Av., Vassilika Vouton, Heraklion, GR-70013, Greece
# Tel: +4032810391669
# Email: bilas@ics.forth.gr
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#
# </copyright>
# <author>Spyridon Papageorgiou</author>
# <email>spapageo@ics.forth.gr</email>
# <date>04.06.2013</date>

#$1=working dir
#$2=application name
#$3=test number

echo "Calculating device utilization [iostat]...."

if [ ! -f config ];then
        echo "  SSWAT ERROR: config file not found"
        exit 0
fi

devices=(`grep "device_list" config`)
if [ ${#devices[@] -eq 1 ];then
        echo "  SSWAT WARNING: No devices provided in the device_list field [config]."
        echo "  Skipping iostat analysis."
        exit 0
fi

target_file="$1/$2$3/stats/iostat_$3"
if [ ! -f $target_file ];then
	echo "  SSWAT WARNING: Iostat log file iostat_$3 not found."
	echo "  SKipping iostat analysis."
	exit 0
fi

info_file="$1/$2$3/info_$3"
csv_file="$1/$2$3/CSV_$3"

check=(`grep "to_that" ${target_file} | wc -l`)
if [ ${check} -eq 0 ];then
	for (( u=1 ; u<${#devices[@]}; u++ ))
	do
		sed '0,/'${devices[u]}'/s//to_that/' $target_file > tmp
	done
	mv tmp ${target_file}
fi

echo "Devices:" >> $info_file
echo "---------------" >> $info_file

lines=0
sum_util=0
max_util=0
sum_queue=0

##CSV prep
echo " ,Avg util%,Max util%,Avg queue sz" >> ${csv_file}

for (( u=1 ; u<${#devices[@]}; u++ ))
do
	lines=(`grep "${devices[u]} " ${target_file} | wc -l`)
	if [ $lines -eq 0 ];then
		echo "  SSWAT WARNING: device ${devices[u]} not found in iostat file."
		echo "  Skipping device ${devices[u]}"
		continue
	fi

	sum_util=(`grep "${devices[u]} " ${target_file} | awk '{print $12}' | awk 'BEGIN {a=0} {a+=$1} END {print a}'`)
	sum_queue=(`grep "${devices[u]} " ${target_file} | awk '{print $9}' | awk 'BEGIN {a=0} {a+=$1} END {print a}'`)

	avg_util=(`echo "scale=2; ${sum_util}/${lines}" | bc 2> /dev/null`)
	avg_queue=(`echo "scale=2; ${sum_queue}/${lines}" | bc 2> /dev/null`)
	max_util=(`grep "${devices[u]} " ${target_file} | awk '{print $12}' | sort -r -n | head -n 1`)

	echo "${devices[u]}       avg=$avg_util : max=$max_util"	>> $info_file
	echo "			  avg queue size: $avg_queue"		>> $info_file

	###CSV
	echo "${devices[u]},${avg_util},${max_util},${avg_queue}" >> ${csv_file}
done

echo >> $info_file
