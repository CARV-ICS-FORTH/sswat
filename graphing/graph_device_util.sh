#!/bin/bash
# <copyright file="graph_device_uti.sh" organization="FORTH-ICS, Greece">
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

#USER
test_name="Test1"
devices=( "sda" "sdb" )
#/USER

#grep config file
work_dir=(`grep working_directory ../config | awk '{print $2}'`)
app_name=(`grep application ../config | awk '{print $2}'`)

test_dir="${work_dir}/${app_name}${test_name}"

if [ ! -d ${test_dir} ];then
	echo "SSWAT ERROR: Target test directory ${test_dir} does not exist."
	echo "Exiting.."
	exit 0
fi

iostat_f="${test_dir}/stats/iostat_${test_name}"
echo $iostat_f;

echo "Started device utilization graph!"

#CHECK IF MORE THEN ONE DEVICES PRESENT!!!

for (( i=0; i < ${#devices[@]}; i++ ))
do
	tmp=`mktemp`
	grep ${devices[$i]} $iostat_f > $tmp

	dev_files[$i]=$tmp
done


src=`mktemp`
dest=`mktemp`
for (( i=0; i < ${#devices[@]}; i++ ))
do
	#first pass: print time and utilization for first device to a file
	if [ $i -eq 0 ];then
		k=0;
		while read line;
		do
			line=(`echo $line | tr [:space:] ' '`)
			line_len=${#line[@]};

			echo $k ${line[$line_len-1]} >> $src
			k=$((k+1))

		done < ${dev_files[$i]}

		continue;
	fi

	#on subsequent passes, read lines from $src, add util and echo back to $dest
	tmp=(`awk '{ print $12 }' ${dev_files[$i]}`)

	k=0
	echo > $dest
	while read line;
	do
		line=(`echo $line | tr [:space:] ' '`)
		echo ${line[@]} ${tmp[k]} >> $dest
		k=$((k+1))

	done < $src

	tmp=$src
	src=$dest
	dest=$src
done

if [ ${#devices[@]} -eq 1 ]; then
	cat $src > Dev_data.dat
else
	cat $dest > Dev_data.dat
fi

rm -fr $src $dest
for (( i=0; i < ${#dev_files[@]}; i++ ))
do
	rm -fr ${dev_files[$i]}
done

#CREATE GNUPLOT SCRIPT!
gnuplot_script="Dev_script.gp";

echo "set terminal postscript enhanced color \"Helvetica\" 10"	>> $gnuplot_script
echo "set output \"device_util_${test_name}.ps\""		>> $gnuplot_script
echo "set title \"$test_name\""					>> $gnuplot_script
echo 								>> $gnuplot_script
echo "set yrange [0:105]"					>> $gnuplot_script
echo								>> $gnuplot_script
echo "set xlabel \"Time [sec]\""				>> $gnuplot_script
echo "set ylabel \"Device utilization %\""			>> $gnuplot_script
echo 								>> $gnuplot_script


plot_line="plot \"Dev_data.dat\" using 1:2 title \"${devices[0]}\" with lines";

for (( i=1; i < ${#devices[@]}; i++ ));
do
	plot_line="${plot_line}, '' using 1:$((i+2)) title \"${devices[$i]}\" with lines"
done

echo $plot_line							>> $gnuplot_script
