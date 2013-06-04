#!/bin/bash
# <copyright file="vmstat_analysis.sh" organization="FORTH-ICS, Greece">
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

#$1=work_dir
#$2=test name


tmp=`mktemp`
tmp2=`mktemp`
grep -v "procs" $1/vmstat_$2 > $tmp
grep -v "b" tmp > $tmp2


i=0
avg_r=0
avg_b=0

while read line
do
	tmp=(`echo $line`)
	avg_r+=${tmp[0]}
	avg_b+=${tmp[1]}

	i=$((i+1))
done < tmp2

tmpVar=(`echo "scale=4;$avg_r/$i" | bc `)
echo "Average # processes waiting for runtime: $tmpVar"

tmpVar=(`echo "scale=4;$avg_b/$i" | bc`)
echo "Average # processes in uninterruptible sleep: $tmpVar"


rm -fr $tmp $tmp2
