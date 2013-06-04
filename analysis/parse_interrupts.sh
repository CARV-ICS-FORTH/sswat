#!/bin/bash
# <copyright file="parse_interrupts.sh" organization="FORTH-ICS, Greece">
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

#$1 working directory
#$2 application name
#$3 test name



echo "Calculating interrupts....."

info_file="$1/$2$3/info_$3"
stats_dir="$1/$2$3/stats"

i=0

if [ -f $stats_dir/ints_before_$3 ];then
	while read line 
	do
		before[i++]=$line
	done < $stats_dir/ints_before_$3
else
	echo "  SSWAT ERROR: interrupt file ints_before_$3 not found"
	exit 0
fi

if [ -f $stats_dir/ints_after_$3 ];then
	i=0
	while read line
	do
		after[i++]=$line
	done < $stats_dir/ints_after_$3
else
	echo "  SSWAT ERROR: interrupt file ints_after_$3 not found."
	exit 0
fi

hd=(`echo ${before[0]} | tr -t ' ' ''`)
header="";
for ((i=0; i < ${#hd[@]}; i++));
do
	header+="${hd[i]}\t"
done


echo -e $header >> $info_file

cpus=(`grep "processor" /proc/cpuinfo | wc -l`)

proc_line=""

for ((i=1; i < ${#before[@]}; i++)) do
	#echo ${before[i]}

	b=(`echo ${before[i]} | tr ':' ' '`)
	a=(`echo ${after[i]} | tr ':' ' '`)

	len=${#b[@]}

	tmpVar=(`echo ${b[0]} | grep [0-9]`)

	if [ -z $tmpVar ]; then
		#string

		for ((j=1; j < len; j++));
		do
			tmpNum=$((${a[j]} - ${b[j]}))
			proc_line+="$tmpNum\t"
		done

		proc_line+="${b[0]}\t\t"

	else
		for ((j=1; j <= cpus; j++));
		do
			tmpNum=$((${a[j]}- ${b[j]}))
			proc_line+="$tmpNum\t"
		done

		for ((j=cpus+1; j < len; j++));
		do
			proc_line+="${a[j]}"
		done

	fi

	echo -e $proc_line >> $info_file

	proc_line=""	
done
