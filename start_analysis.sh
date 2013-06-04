#!/bin/bash

# <copyright file="start_analysis.sh" organization="FORTH-ICS, Greece">
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

#$1 = test number/name

if [ $# -ne 1 ];then
	echo "SSWAT ERROR: Wrong number of arguments provided!"
	echo "Usage: ./start_analysis.sh <test_name>"
	exit 1;
fi

if [ ! -f config ];then
	echo "SSWAT ERROR: configuration file not found."
	exit 1;
fi

work_dir=(`grep working_directory config | awk '{print $2}'`)
if [ ! -d $work_dir ];then
	echo "SSWAT ERROR: Working directory ${work_dir} does not exist."
	echo "Check the config file field \"working_directory\"."
	exit 1
fi

app_name=(`grep application config | awk '{print $2}'`)
if [ ! -d ${work_dir}/${app_name}$1 ];then
	echo "SSWAT ERROR: Test directory ${work_dir}/${app_name}$1 not found."
	exit 1
fi

kvm=(`grep kvm_support config | awk '{print $2}'`)


#1) Execution time calculation
sh analysis/exec_calculation.sh $work_dir $app_name $1
if [ $? -eq 0 ];then
	echo "  SSWAT ERROR: Execution time calculation failed."
	echo "  Aborting analysis.."
	exit 0
fi

#2) Sampling information
sh analysis/samples.sh $work_dir $app_name $1

#3) CPU statistics
sh analysis/cpu_analysis.sh $work_dir $app_name $1
if [ $? -eq 0 ];then
	echo "  SSWAT ERROR: CPU times calculation failed."
	echo "  Aborting analysis.."
	exit 0
fi

#4) Calculate interrupts
sh analysis/parse_interrupts.sh $work_dir $app_name $1

#5) iostat
sh analysis/iostat_analysis.sh $work_dir $app_name $1

#6) diskstats + xfs counters
sh analysis/device_analysis.sh $work_dir $app_name $1

#7) kvm counters
if [ $kvm = "on" ]; then
	sh analysis/kvm_analysis/kvm_counters.sh $work_dir $app_name $1
fi

