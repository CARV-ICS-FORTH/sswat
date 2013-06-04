#!/bin/bash
# <copyright file="aggregate.sh" organization="FORTH-ICS, Greece">
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

#$1=name


work_dir=(`grep working_directory $SSWAT_PATH/config | awk '{print $2}'`)
app_name=(`grep application  $SSWAT_PATH/config | awk '{print $2}'`)

test_dir="$work_dir/$app_name$1"

sh $SSWAT_PATH/utils/preprocess.sh $test_dir $1 1

#read the number of cores from the info file
cores=(`grep "processor" /proc/cpuinfo | wc -l`)
sum=0
k=1

for (( i=0 ; i < $cores; i++ ))
do
	param="\$$k"
        samples=(`awk < $test_dir/oprof_results_$1_separate "{print $param}" | awk 'BEGIN {a=0} {a+=$1} END {print a}'`)
		#echo "CPU$i samples: $samples"
	sum=$((sum+samples))
	k=$((k+2))
done
total_samples=$sum

#echo "Total samples: $total_samples"

tmp_file=`mktemp`
while read line;
do
	tmp=(`echo $line | tr [:space:] ' '`)

	sum=0
	k=0
	for (( i=0; i < $cores; i++ ));
	do
		sum=$(($sum + ${tmp[k]}))
		k=$((k+2))
	done

	perc=(`echo "scale=4; $sum*100 / $total_samples" | bc`)
	len=${#tmp[@]}
	#kane output samples, percentage, application name, function name
	printf "%d\t%.4f\t%s\t%s\n" $sum $perc ${tmp[len-2]} ${tmp[len-1]} >> $tmp_file
done < $test_dir/oprof_results_$1_separate

sort -k2 -n -r $tmp_file > $test_dir/oprof_results_$1_aggregate
