#!/bin/bash
# <copyright file="multifilter.sh" organization="FORTH-ICS, Greece">
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

#$1 = tmp_system file from multigraph.sh
#$2 = awk param depending on cpu
#$3 = file to save "perm_file" name to be used by multigraph..


#Create temporary files for each pass, remove in the end

filter=(`ls -l filters | grep filter | awk '{print $9}'`)

perm_file=`mktemp`
swap=`mktemp`

cat $1 > $perm_file

param="\$$2"

for (( i=0; i<${#filter[@]}; i=$(($i+1)) ))
do
	tmp_brk=`mktemp`

  	fgrep -f filters/${filter[$i]} $perm_file > $tmp_brk

        fgrep -v -f filters/${filter[$i]} $perm_file > $swap
        cat $swap > $perm_file

        echo ${filter[$i]}":"
	
        awk < $tmp_brk "{print $param}" | awk 'BEGIN {a=0} {a+=$1} END {print a}'

	rm -fr $tmp_brk
done


echo "system_other:"
awk < $perm_file "{print $param}" | awk 'BEGIN {a=0} {a+=$1} END {print a}'

rm -fr $perm_file
rm -fr $swap
