#!/bin/bash
# <copyright file="sanity_check.sh" organization="FORTH-ICS, Greece">
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

#$1=tool_path

if [ $# -eq 0 ];then
	echo "  SSWAT ERROR: sanity check called with wrong number of arguments."
	echo "  Usage: ./sanity_check.sh <path_to_sswat_directory>"
	exit 0
fi

tool_path=$1

flag=0
check=(`grep "working_directory" ${tool_path}/config`)
if [ ! -d ${check[1]} ];then
	echo "  SSWAT WARNING - ${check[1]}: target working dir does not exist."
	flag=1
else
	echo "  Target working directory checked: OK"
fi


check=(`grep "oprof_vmlinux_path" ${tool_path}/config`)
if [ ! -f ${check[1]} ];then
	echo "  SSWAT WARNING - ${check[1]}: path to vmlinux image is invalid"
	flag=1
else
	echo "  vmlinux image checked: OK"
fi


check=(`grep "oprof_kernel_module_paths" ${tool_path}/config | tr ',' ' '`)

for (( i=1; i < ${#check[@]}; i++ ));
do
	tmp=(` find ${check[i]} -name *.ko `)
	if [ ${#tmp[@]} -eq 0 ]; then
		echo "  SSWAT WARNING - ${check[i]}: path does not contain any .ko files"
		flag=1
	else
		echo "  ${check[i]} module path checked: OK"
	fi
done

if [ $flag -eq 1 ];then
	printf "  SSWAT WARNING - Detected problems in the config file. Do you still want to continue? (y/n): "
	read user

	if [ $user == 'n' ];then
		echo "  Exiting..."
		exit 1
	fi

	if [ $user == 'y' ];then
		echo "  Continuing execution (with errors)"
		exit 0
	fi

	echo "  Invalid input, exiting anyway.."
	exit 1
fi

echo "  Sanity check passed"
