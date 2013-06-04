#!/bin/bash
# <copyright file="cpu_analysis.sh" organization="FORTH-ICS, Greece">
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
#$3=test name

echo "Calculating CPU utilization..."

CPU_before='CPU_before'_$3
CPU_after='CPU_after'_$3

#2.27x10^9 = 227x10^7 => /100 (USER_HZ) 227x10^5
freq=200	#was 227
f=$((freq*100000))

if [ ! -f $1/$2$3/stats/$CPU_before ];then
	echo "SSWAT ERROR: $CPU_before file not found in the test directory."
	echo "Exiting.."
	exit 0
fi

if [ ! -f $1/$2$3/stats/$CPU_after ];then
	echo "SSWAT ERROR: $CPU_after file not found in the test directory."
	echo "Exiting.."
	exit 0
fi


CPU1=(`grep '^cpu ' $1/$2$3/stats/$CPU_before`)
CPU2=(`grep '^cpu ' $1/$2$3/stats/$CPU_after`)

user1=${CPU1[1]};
nice1=${CPU1[2]}
system1=${CPU1[3]}
idle1=${CPU1[4]}
iowait1=${CPU1[5]}
irq1=${CPU1[6]}
sirq1=${CPU1[7]}

user2=${CPU2[1]}
nice2=${CPU2[2]}
system2=${CPU2[3]}
idle2=${CPU2[4]}
iowait2=${CPU2[5]}
irq2=${CPU2[6]}
sirq2=${CPU2[7]}

user=$((user2-user1))
nice=$((nice2-nice1))
system=$((system2-system1))
idle=$((idle2-idle1))
iowait=$((iowait2-iowait1));
irq=$((irq2-irq1))
sirq=$((sirq2-sirq1))
total=$((user+system+idle+iowait+irq+sirq))

set -f

irq_f=(`echo "scale=4;$irq*100/$total" | bc 2> /dev/null`)
user_f=(`echo "scale=4;$user*100/$total" | bc 2> /dev/null`)
idle_f=(`echo "scale=4;$idle*100/$total" | bc 2> /dev/null`)
sirq_f=(`echo "scale=4;$sirq*100/$total" | bc 2> /dev/null`)
system_f=(`echo "scale=4;$system*100/$total" | bc 2> /dev/null`)
iowait_f=(`echo "scale=4;$iowait*100/$total" | bc 2> /dev/null`)


#cpu utilization
work_over_period=$((user+nice+system))
total_over_period=$((work_over_period+idle+iowait+irq+sirq))


tmp=(`echo "scale=4 ; $work_over_period / $total_over_period" | bc 2> /dev/null`)
cpu_percentage=(`echo "scale=4;$tmp * 100" | bc 2> /dev/null`)

file="$1/$2$3/cpu_stats_$3"

echo "CPU statistics:"		> $file
echo "---------------"		>> $file
echo "user: "$user_f		>> $file
echo "system: "$system_f	>> $file
echo "idle: "$idle_f		>> $file
echo "irq: "$irq_f		>> $file
echo "sirq: "$sirq_f		>> $file
echo "iowait: "$iowait_f	>> $file
echo "cpu%: "$cpu_percentage	>> $file
echo				>> $file

#Calculate per cpu stats
cpus=(`grep "processor" /proc/cpuinfo | wc -l`)

echo "Per CPU statistics:" >> $file
echo "-------------------" >> $file

header="\t\t user\t\t system\t\t idle\t\t irq\t\t sirq\t\t iowait\t\tcpu_util"
echo -e $header >> $file

for (( i=0 ; i < cpus ; i++ ))
do
	CPU1=(`grep cpu$i $1/$2$3/stats/$CPU_before`)
	CPU2=(`grep cpu$i $1/$2$3/stats/$CPU_after`)

	user1=${CPU1[1]}; system1=${CPU1[3]}; idle1=${CPU1[4]};
	iowait1=${CPU1[5]}; irq1=${CPU1[6]}; sirq1=${CPU1[7]}
	nice1=${CPU1[2]}


	user2=${CPU2[1]}; system2=${CPU2[3]}; idle2=${CPU2[4]};
	iowait2=${CPU2[5]}; irq2=${CPU2[6]}; sirq2=${CPU2[7]}
	nice2=${CPU2[2]}

	user=$((user2-user1)); system=$((system2-system1));
	idle=$((idle2-idle1)); iowait=$((iowait2-iowait1));
	irq=$((irq2-irq1)); sirq=$((sirq2-sirq1))
	nice=$((nice2-nice1))
	total=$((user+system+idle+iowait+irq+sirq))

	set -f

	irq_f=(`echo "scale=4;$irq*100/$total" | bc 2> /dev/null`)
	user_f=(`echo "scale=4;$user*100/$total" | bc 2> /dev/null`)
	idle_f=(`echo "scale=4;$idle*100/$total" | bc 2> /dev/null`)
	sirq_f=(`echo "scale=4;$sirq*100/$total" | bc 2> /dev/null`)
	system_f=(`echo "scale=4;$system*100/$total" | bc 2> /dev/null`)
	iowait_f=(`echo "scale=4;$iowait*100/$total" | bc 2> /dev/null`)


	#cpu utilization
	work_over_period=$((user+nice+system))
	total_over_period=$((work_over_period+idle+iowait+irq+sirq))


	tmp=(`echo "scale=4;$work_over_period / $total_over_period" | bc 2> /dev/null`)
	cpu_percentage=(`echo "scale=4; $tmp * 100" | bc 2> /dev/null`)

	cpu_line="cpu$i\t\t $user_f"

        cond=(`echo "$user_f < 10" | bc 2>/dev/null`)
	if [ $cond -eq 1 ];then
		cpu_line="${cpu_line} \t\t$system_f"
	else
		cpu_line="${cpu_line} \t$system_f"
	fi

        cond=(`echo "$system_f < 10" | bc 2>/dev/null`)
	if [ $cond -eq 1 ];then
		cpu_line="${cpu_line} \t\t$idle_f"
	else
		cpu_line="${cpu_line} \t$idle_f"
	fi

        cond=(`echo "$idle_f < 10" | bc 2>/dev/null`)
	if [ $cond -eq 1 ];then
		cpu_line="${cpu_line} \t\t$irq_f"
	else
		cpu_line="${cpu_line} \t$irq_f"
	fi

        cond=(`echo "$irq_f < 10" | bc 2>/dev/null`)
	if [ $cond -eq 1 ];then
		cpu_line="${cpu_line} \t\t$sirq_f"
	else
		cpu_line="${cpu_line} \t$sirq_f"
	fi

        cond=(`echo "$sirq_f < 10" | bc 2>/dev/null`)
	if [ $cond -eq 1 ];then
		cpu_line="${cpu_line} \t\t$iowait_f"
	else
		cpu_line="${cpu_line} \t$iowait_f"
	fi

        cond=(`echo "$iowait_f < 10" | bc 2>/dev/null`)
	if [ $cond -eq 1 ];then
		cpu_line="${cpu_line} \t\t$cpu_percentage%"
	else
		cpu_line="${cpu_line} \t$cpu_percentage%"
	fi

	echo -e $cpu_line >> $file

done

echo		>> $1/$2$3/info_$3
cat $file	>> $1/$2$3/info_$3
echo		>> $1/$2$3/info_$3

#echo "Calculating interrupts..."
#irq1=(`grep 'intr' $1/$2$3/stats/$CPU_before`)
#irq2=(`grep 'intr' $1/$2$3/stats/$CPU_after`)
#diff=$((${irq2[1]} - ${irq1[1]}))
#echo "# of interrupts $diff" >> $1/$2$3/info_$3
