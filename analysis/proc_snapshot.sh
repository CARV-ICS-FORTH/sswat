#!/bin/bash
# <copyright file="proc_snapshot.sh" organization="FORTH-ICS, Greece">
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

#$1=output directory
#$2=directory name
#$3=test name
#$4=tool_path
#$5=before/after


stats_dir="$1/$2$3/stats"

proc_select=(`cat $4/config | grep proc_selection`)


for (( i=1; i<${#proc_select[@]}; i++ ));
do
	proc_entry=(`cat $4/config | grep proc_$i`)

	if [ -f ${proc_entry[1]} ]; then
		cat ${proc_entry[1]} > $stats_dir/${proc_entry[2]}_$5_$3
	else
		echo "/proc snapshot failed: ${proc_entry[1]} does not exist.."
	fi
done
