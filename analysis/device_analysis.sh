#!/bin/bash
# <copyright file="device_analysis.sh" organization="FORTH-ICS, Greece">
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

echo "Calculating device statistics....."

info_file="$1/$2$3/info_$3"
stats_dir="$1/$2$3/stats"

gb=1073741824

#diskstats
if [ ! -f config ];then
	echo "  SSWAT ERROR: config file not found"
	exit 0
fi

devices=(`grep "device_list" config`)
if [ ${#devices[@] -eq 1 ];then
	echo "  SSWAT WARNING: No devices provided in the device_list field [config]"
	echo "  Skipping device analysis."
	exit 0
fi

for (( u=1 ; u<${#devices[@]}; u++ ))
do
  	disk_list[$(($u-1))]=${devices[u]}
done


sum_read_ops=0
sum_write_ops=0
sum_read_sects=0
sum_write_sects=0

echo			>> $info_file
echo "Disk stats:"	>> $info_file
echo "-----------"	>> $info_file


if [ ! -f $stats_dir/dev_before_$3 ];then
	echo "  SSWAT WARNING: Device stats file dev_before_$3 not found."
	echo "  Skipping device analysis."
	exit 0
fi

if [ ! -f $stats_dir/dev_after_$3 ];then
	echo "  SSWAT WARNING: Device stats file dev_after_$3 not found."
	echo "  Skipping device analysis."
	exit 0
fi

for (( i=0 ; i < ${#disk_list[@]} ; i=$(($i+1)) ))
do
	tmp_after=(`grep ${disk_list[$i]} $stats_dir/dev_after_$3`)
	if [ ${#tmp_after[@]} -eq 0 ];then
		echo "  SSWAT WARNING: Device ${disk_list[$i]} not found in dev_after_$3"
		echo "  Skipping device ${disk_list[$i]}"
		continue
	fi

	tmp_before=(`grep ${disk_list[$i]} $stats_dir/dev_before_$3`)
	if [ ${#tmp_before[@]} -eq 0 ];then
		echo "  SSWAT WARNING: Device ${disk_list[$i]} not found in dev_before_$3"
		echo "  Skipping device ${disk_list[$i]}"
		continue
	fi

	#compute read and write operations, sectors read and written
	read_ops=$((${tmp_after[3]}-${tmp_before[3]}))
	read_sectors=$((${tmp_after[5]}-${tmp_before[5]}))

	write_ops=$((${tmp_after[7]}-${tmp_before[7]}))
	write_sectors=$((${tmp_after[9]}-${tmp_before[9]}))

	echo "Device: ${disk_list[$i]}"			>> $info_file
	echo -e "\tWrite operations: $write_ops"	>> $info_file
	echo -e "\tSectors written: $write_sectors"	>> $info_file
	echo -e "\tRead operations: $read_ops"		>> $info_file
	echo -e "\tSectors read: $read_sectors"		>> $info_file

	sum_read_ops=$(($read_ops+$sum_read_ops))
	sum_write_ops=$(($write_ops+$sum_write_ops))

	sum_read_sects=$(($read_sectors+$sum_read_sects))
	sum_write_sects=$(($write_sectors+$sum_write_sects))

	echo "-----"					>> $info_file
done

	if [ $sum_write_ops -eq 0 ];then
		avg_wr_rq=0
	else
		avg_wr_rq=(`echo "scale=2; $sum_write_sects / $sum_write_ops" | bc 2> /dev/null`)
	fi

	if [ $sum_read_ops -eq 0 ];then
		avg_re_rq=0
	else
		avg_re_rq=(`echo "scale=2; $sum_read_sects / $sum_read_ops" | bc 2> /dev/null`)
	fi

	echo "Total write ops: $sum_write_ops"		>> $info_file
	echo "Total sectors written: $sum_write_sects"	>> $info_file
	echo "Average write rq size: $avg_wr_rq"	>> $info_file
	echo "Total read ops: $sum_read_ops"		>> $info_file
	echo "Total sectors read: $sum_read_sects"	>> $info_file
	echo "Average read rq size: $avg_re_rq"		>> $info_file
	echo						>> $info_file

#xfs counters
#compute write and read ops
#compute xpc stuff

fs=(`grep filesystem config | awk '{print $2}'`)

if [ $fs = "xfs" ]; then
	if [ -f $stats_dir/xfs_counters_after_$3 ];then
		rw_after=(`grep rw $stats_dir/xfs_counters_after_$3`)
		rw_before=(`grep rw $stats_dir/xfs_counters_before_$3`)
		xpc_after=(`grep xpc $stats_dir/xfs_counters_after_$3`)
		xpc_before=(`grep xpc $stats_dir/xfs_counters_before_$3`)
	

		write_calls=$((${rw_after[1]} - ${rw_before[1]}))
		read_calls=$((${rw_after[2]} - ${rw_before[2]}))

		bytes_flushed=$((${xpc_after[1]}-${xpc_before[1]}))
		GB_flushed=(`echo "scale=2; $bytes_flushed / $gb" | bc 2> /dev/null`)

		bytes_written=$((${xpc_after[2]}-${xpc_before[2]}))
		GB_written=(`echo "scale=2; $bytes_written / $gb" | bc 2> /dev/null`)

		bytes_read=$((${xpc_after[3]}-${xpc_before[3]}))
		GB_read=(`echo "scale=2;$bytes_read / $gb" | bc 2> /dev/null`)

		echo							>> $info_file
		echo "XFS counters:"					>> $info_file
		echo "-------------"					>> $info_file
		echo "Write calls: $write_calls"			>> $info_file
		echo "Read calls: $read_calls"				>> $info_file
		echo "Bytes flushed: $bytes_flushed ($GB_flushed GB)"	>> $info_file
		echo "Bytes written: $bytes_written ($GB_written GB)"	>> $info_file
		echo "Bytes read: $bytes_read ($GB_read GB)"		>> $info_file
	fi
fi
