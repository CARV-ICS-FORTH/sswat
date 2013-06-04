#!/bin/bash
# <copyright file="oprof_comparator.sh" organization="FORTH-ICS, Greece">
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


#user
output_file="indexer_comparison"
test_names=( bladefs_1cache_24GB_modIndexer bladefs_4caches_24GB_indexerMod )
function_threshold=0.1
#/user

####################################String Beautification...#####################################
function build_string(){
        local fix=$1
        local range

        range=$((${#1} / 8))
        local diff=$(($max_range - $range + 1))

        for (( z=0; z < $diff; z++ ));
        do
                fix="${fix}\t"
        done
        echo $fix
}

#########################################################################################


num_tests=${#test_names[@]}
work_dir=(`grep working_directory ../config | awk '{print $2}'`)
app_name=(`grep application  ../config | awk '{print $2}'`)

relative_path="${work_dir}/${app_name}"

tmp=`mktemp`
tmp_f_merge=`mktemp`

for (( i=0; i < $num_tests; i++ ));
do
	read line < "${relative_path}${test_names[i]}"/oprof_results_${test_names[i]}
	step=(`echo $line | tr ':' ' '`)

	if [ ${#step[@]} -eq 5 ]; then
		awk -F' ' '{ print $5 }' "${relative_path}${test_names[i]}"/oprof_results_${test_names[i]} >> $tmp
	else
		awk -F' ' '{ print $4 }' "${relative_path}${test_names[i]}"/oprof_results_${test_names[i]} >> $tmp
	fi
done

sort $tmp | uniq | grep -v '^$' > $tmp_f_merge #this removes all duplicate lines lines. tmp_f_merge now contains the union of all functions
					       #reported by oprof accross all experiments


tmp2=`mktemp`
#scan tmp_f_merge to find the functions worth printing and preprocess text
max_length=0
while read line
do
	sum=0
	for (( k=0 ; k < $num_tests; k++ ));
	do
		result=(`grep -w $line "${relative_path}${test_names[k]}"/oprof_results_${test_names[k]}`)

		if [[ ${#result[@]} -eq 0 ]]; then
			#function absent - 0 in cell
			continue
		fi

		test=(`echo "scale=4; ${result[1]} < $function_threshold" | bc`)

		if [[ "${result[1]}" == *e* ]]; then
			#found e in percentage. extremely small - 0 in cell
			continue
		elif [ $test -eq 1 ]; then
			continue
		fi

		#function found and percentage is big enough to be printed
		sum=(`echo "scale=4; $sum + ${result[1]}" | bc`)
	done

	test=(`echo "scale=4; $sum !=0" | bc`)
	if [ $test -eq 1 ];then
		echo $line >> $tmp2

		if [ ${#line} -gt $max_length ]; then
			max_length=${#line}
			max_elem=$line
		fi

	fi

done < $tmp_f_merge

max_range=$(($max_length / 8))

header="\t"
for (( i=0; i < $num_tests; i++ ));
do
	header="${header} \t ${test_names[i]}"
done

rm -fr $tmp
tmp=`mktemp`

#1) read $tmp_f_merge file line by line
#2) for each function grep oprof result files
#3) if not found, or percentage too small put 0 in the appropriate cell
while read line
do
	create_line=$(build_string $line)
	sum=0
	for (( k=0 ; k < $num_tests; k++ ));
	do
		result=(`grep -w $line "${relative_path}${test_names[k]}"/oprof_results_${test_names[k]}`)

		if [[ ${#result[@]} -eq 0 ]]; then
			#function absent - 0 in cell
			create_line="${create_line}0\t\t\t\t"
			continue
		fi

		test=(`echo "scale=4; ${result[1]} < $function_threshold" | bc`)
		if [[ "${result[1]}" == *e* ]]; then
			#found e in percentage. extremely - 0 in cell
			create_line="${create_line}0\t\t\t\t"
			continue
		elif [ $test -eq 1 ]; then
			create_line="${create_line}0\t\t\t\t"
			continue
		fi

		#function found and percentage is big enough to be printed
		create_line="${create_line}${result[1]}"
		sum=(`echo "scale=4; $sum + ${result[1]}" | bc`)
		create_line="${create_line}\t\t\t\t"
	done

	test=(`echo "scale=4; $sum !=0" | bc`)
	if [ $test -eq 1 ];then
		echo -e $create_line >> $tmp
	fi

done < $tmp2


sort -k2 -n -r $tmp > $tmp2
echo -e $header > $output_file
cat $tmp2 >> $output_file


rm -fr $tmp_f_merge
rm -fr $tmp
rm -fr $tmp2




##################################################################################################################
#TO BE ADDED LATER: need to distinguish between kernel and user space functions in order to do this properly...
#Acquire cpu stats and execution time for each experiment
#only interested in user and system times
#for (( i=0 ; i < $num_tests ; i++ ))
#do
#        tmp_var=(`cat info_${test_names[i]} | grep Execution`)
#        tmp_var=(`echo ${tmp_var[2]} | tr ':' ' '`)
#        exec_time_mins=${tmp_var[0]}
#        exec_time_secs=${tmp_var[1]}
#        execution[i]=$(( $(($exec_time_mins * 60)) + $exec_time_secs ))
	#cpu stats
#	tmp_var=(`cat cpu_stats_${test_names[i]} | grep user`)
#	user[i]=(`echo "scale=4;${tmp_var[1]} / 100}" | bc`)
#	tmp_var=(`cat cpu_stats_${test_names[i]} | grep system`)
#	system[i]=(`echo "scale=4;${tmp_var[1]} / 100}" | bc`)
#done

