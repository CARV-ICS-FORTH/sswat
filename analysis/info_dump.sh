#!/bin/bash
#$1=working directory
#$2=application name
#$3=test name
#$4=begin_t
#$5=end_t

# <copyright file="filename" organization="FORTH-ICS, Greece">
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


info_file="$1/$2$3/info_$3"

timestamp=`date +%F`
echo "info_$3 - $timestamp" > $info_file
echo >> $info_file
echo "begin: $4" >> $info_file
echo "end: $5" >> $info_file

cpus=(`grep "processor" /proc/cpuinfo | wc -l`)

memory=(`grep "MemTotal" /proc/meminfo`)

echo >> $info_file
echo -e "System info:\n------------" >> $info_file
uname -a >> $info_file
echo "Cpus: $cpus" >> $info_file
echo "Memory: ${memory[1]} kB" >> $info_file 


echo -e "\nHardware info\n------------\n" >> $info_file
devices=(`cat ../config | grep device_list`)

for ((i=1 ; i < ${#devices[@]}; i++));
do
  	model=(`cat /sys/block/${devices[$i]}/device/model`);
        echo "${devices[$i]}: $model"; >> $info_file
done



controllers=`lspci | grep RAID`
echo -e "\nControllers\n-----------\n${controllers[@]}" >> $info_file


#Live modules
module_info=`cat /proc/modules`
echo -e "\n\nLive modules\n------------\n${module_info[@]}" >> $info_file
