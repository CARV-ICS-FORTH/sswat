#!/bin/bash
# <copyright file="exec_calculation.sh" organization="FORTH-ICS, Greece">
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



echo "Calculating execution time.."
info_file="$1/$2$3/info_$3"

begin=(`cat $info_file | grep "begin"`)
end=(`cat $info_file | grep "end"`)


begin=(`echo ${begin[1]} | tr '-' ' '`)
end=(`echo ${end[1]} | tr '-' ' '`)

hour_begin=${begin[0]}
min_begin=${begin[1]}
sec_begin=${begin[2]}

hour_end=${end[0]}
min_end=${end[1]}
sec_end=${end[2]}

sec_diff=`expr $sec_end - $sec_begin`
min_diff=`expr $min_end - $min_begin`
hour_diff=`expr $hour_end - $hour_begin`

if [ $sec_diff -lt 0 ]; then
         min_diff=`expr $min_diff - 1`
         sec_diff=`expr $sec_diff + 60`
fi

if [ $min_diff -lt 0 ]; then
         hour_diff=`expr hour_diff - 1`
         min_diff=`expr $min_diff + 60`
fi

let "exec_mins= $hour_diff * 60"
exec_mins=`expr $exec_mins + $min_diff`

echo >> $info_file
echo "Execution time: $exec_mins:$sec_diff" >> $info_file
echo "---------------" >> $info_file

