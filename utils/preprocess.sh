#!/bin/bash
# <copyright file="preprocess.sh" organization="FORTH-ICS, Greece">
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

#$1=test dir
#$2=name
#$3=mode



cores=(`grep "processor" /proc/cpuinfo | wc -l`)
del=$(($cores+3))

#First time automation - clean first 3 lines
if [ $3 -eq 0 ];then
	mode="aggregate"
	read line < $1/oprof_results_$2_aggregate
else
	mode="separate"
	read line < $1/oprof_results_$2_separate
fi

if [[ $line = *CPU* ]]; then
	if [ $3 -eq 0 ];then
		#aggregate
		sed -i "1,3 d" $1/oprof_results_$2_aggregate
	else
		#separate
		sed -i "1,$del d" $1/oprof_results_$2_separate
	fi
fi


#clear unwanted chars
sed "s/(.*)//" $1/oprof_results_$2_${mode} > out
sed '/\[*\]/d' out > $1/oprof_results_$2_${mode}
