#!/bin/bash
# <copyright file="run.sh" organization="FORTH-ICS, Greece">
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

#$1=test name

#USER: Enter path to the directory the tool resides and command line to measure
tool_path="/home/user/sswat"
cmd="sleep 10"
#/USER


if [ $# -ne 1 ]; then
	echo "SSWAT ERROR: Wrong number of arguments provided."
	echo "Usage: ./run.sh <test_name>"
	exit 0
fi


if [ ! -d ${tool_path} ];then
	echo "SSWAT ERROR: sswat directory ${tool_path} does not exist."
	echo "Exiting.."
	exit 0
fi

if [ ! -f ${tool_path}/config ];then
	echo "SSWAT ERROR: configuration file not found in ${tool_path}.";
	echo "Edit the tool_path parameter embedded in this script to resolve this issue."
	exit 0
fi


if [ -f ${tool_path}/utils/sanity_check.sh ];then
	${tool_path}/utils/sanity_check.sh ${tool_path}
	if [ $? -eq 1 ]; then
		exit 0
	fi
fi

work_dir=(`grep "working_directory" ${tool_path}/config | awk '{print $2}'`)
if [ ! -d $work_dir ];then
	echo "SSWAT ERROR: Working directory $work_dir does not exist."
	echo "Check the config file field \"working_directory\"."
	exit 0
fi

app_name=(`grep "application" ${tool_path}/config | awk '{print $2}'`)
vmlinux=(`grep "oprof_vmlinux_path" ${tool_path}/config | awk '{print $2}'`)
kernel_mod=(`grep "oprof_kernel_module_paths" ${tool_path}/config | awk '{print $2}'`)
event=(`grep "oprof_event" ${tool_path}/config | awk '{print $2}'`)
threshold=(`grep "oprof_threshold" ${tool_path}/config | awk '{print $2}'`)
oprof_mode=(`grep "oprof_mode" ${tool_path}/config | awk '{print $2}'`)
fs=(`grep "filesystem" ${tool_path}/config | awk '{print $2}'`)
kvm_support=(`grep "kvm_support" ${tool_path}/config | awk '{print $2}'`)

echo "kvm support: $kvm_support"

	test_dir="${work_dir}/${app_name}$1"
	stats_dir="${test_dir}/stats"

	mkdir $test_dir
	if [ ! -d $test_dir ]; then
		echo "SSWAT ERROR: failed to created $test_dir directory."
		echo "Exiting.."
		exit 0
	fi

	mkdir $stats_dir
	if [ ! -d $stats_dir ]; then
		echo "SSWAT ERROR: failed to created $stats_dir directory."
		echo "Exiting.."
		exit 0
	fi

	##Oprofile init##
	sudo opcontrol --reset
	sudo opcontrol --deinit
	sudo su -m -c "echo 0 > /proc/sys/kernel/nmi_watchdog"

	if [ $oprof_mode = "separate" ]; then
		sudo opcontrol --separate=cpu
	else
		sudo opcontrol --separate=none
	fi

	sudo opcontrol --setup --vmlinux=$vmlinux --event=$event:$threshold
	sudo opcontrol --start


	if [ $kvm_support = "on" ]; then
	#snapshot_before
		sh $tool_path/analysis/kvm_analysis/kvm_snapshot.sh $work_dir $app_name $1 before
	fi


	if [ -f ${tool_path}/analysis/proc_snapshot.sh ]; then
		sh $tool_path/analysis/proc_snapshot.sh $work_dir $app_name $1 $tool_path before
	else
		echo "SSWAT ERROR: analysis/proc_snapshot.sh script not found. Exiting.."
		exit 0
	fi

	iostat -x 1 -t > $stats_dir/iostat_$1 &
	PID_iostat=$!
	vmstat 1 > $stats_dir/vmstat_$1 &
	PID_vmstat=$!

	##############
	begin_t=`date +%H-%M-%S`

	#command line
	eval $cmd $i &> $stats_dir/user_output_$1

	end_t=`date +%H-%M-%S`
	##############

	sudo opcontrol --shutdown

	kill $PID_vmstat
	kill $PID_iostat

	if [ -f ${tool_path}/analysis/info_dump.sh ]; then
		sh $tool_path/analysis/info_dump.sh $work_dir $app_name $1 $begin_t $end_t
	else
		echo "SSWAT WARNING: analysis/info_dump.sh script not found. Skipping.."
	fi

	if [ -f ${tool_path}/analysis/proc_snapshot.sh ]; then
		sh $tool_path/analysis/proc_snapshot.sh $work_dir $app_name $1 $tool_path after
	else
		echo "SSWAT ERROR: analysis/proc_snapshot.sh script not found. Exiting.."
		exit 0
	fi

	if [ $kvm_support = "on" ]; then
		#snapshot_after
		sh $tool_path/analysis/kvm_analysis/kvm_snapshot.sh $work_dir $app_name $1 after
	fi
	

	if [ ${oprof_mode} == "none" ];then
		opreport -p /lib/modules/`uname -r`/build,$kernel_mod -l > $test_dir/oprof_results_$1_aggregate
	else
		opreport -p /lib/modules/`uname -r`/build,$kernel_mod -l > $test_dir/oprof_results_$1_separate
		export SSWAT_PATH=${tool_path}
		${tool_path}/utils/aggregate.sh $1
	fi
