#!/bin/bash
# <copyright file="samples.sh" organization="FORTH-ICS, Greece">
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

#$1=working directory
#$2=application name
#$3=test_number

echo "Calculating sampling rates."

test_dir="$1/$2$3"
info_file="$test_dir/info_$3"

if [ -f $test_dir/oprof_results_$3_aggregate ];then
	oprof_file="$test_dir/oprof_results_$3_aggregate"
elif [ -f $test_dir/oprof_results_$3_none ];then
	oprof_file="$test_dir/oprof_results_$3_none"
else
	echo "  SSWAT ERROR: oprofile report (aggregate) not found!"
	echo "  Skipping samling rate calculation."
	exit 0
fi

samples=(`awk '{print $1}' $oprof_file | awk 'BEGIN {a=0} {a+=$1} END {print a}' `)

#calculate execution time in seconds
tmp_time=(`cat $test_dir/info_$3 | grep Execution`)

tmp_time=(`echo ${tmp_time[2]} | tr ':' ' '`)
exec_time_mins=${tmp_time[0]}
exec_time_secs=${tmp_time[1]}

in_seconds=$(( $(($exec_time_mins * 60)) + $exec_time_secs ))

samples_per_sec=(`echo "scale=2;$samples / $in_seconds" | bc 2> /dev/null`)

echo						>> $info_file
echo "Oprofile sampling information"		>> $info_file
echo "-----------------------------"		>> $info_file
echo "Total samples: $samples"			>> $info_file
echo "Samples per second: $samples_per_sec"	>> $info_file
