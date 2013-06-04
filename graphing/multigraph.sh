#!/bin/bash
# <copyright file="multigraph.sh" organization="FORTH-ICS, Greece">
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

#$1 = test name

#####################################COLOUR SCHEMES######################################
c_s_size=15
colour_scheme[0]="newcurve marktype xbar cfill 1 0 0 marksize 4"                        #red
colour_scheme[1]="newcurve marktype xbar cfill 0 0 1 marksize 4"                        #blue
colour_scheme[2]="newcurve marktype xbar cfill 0 1 0 marksize 4"                        #green
colour_scheme[3]="newcurve marktype xbar fill .20 pattern stripe 90 marksize 4"         #blackish stripped
colour_scheme[4]="newcurve marktype xbar cfill 1 1 0 marksize 4"                        #yellow
colour_scheme[5]="newcurve marktype xbar cfill 0 0 1 pattern stripe 120 marksize 4"     #blue stripped
colour_scheme[6]="newcurve marktype xbar cfill 1 0 1 marksize 4"                        #magenta
colour_scheme[7]="newcurve marktype xbar fill .80 pattern stripe 60 marksize 4"         #blackish stripped
colour_scheme[8]="newcurve marktype xbar cfill 0 1 0 pattern stripe 120 marksize 4"     #green stripped
colour_scheme[9]="newcurve marktype xbar cfill 1 1 0 pattern stripe 120 marksize 4"     #yellow stripped
colour_scheme[10]="newcurve marktype xbar cfill 1 0 1 pattern stripe 120 marksize 4"    #red stripped
colour_scheme[11]="newcurve marktype xbar fill .50 pattern stripe 60 marksize 4"        #blackish stripped
colour_scheme[12]="newcurve marktype xbar cfill 0 1 1 marksize 4"                       #siel
colour_scheme[13]="newcurve marktype xbar cfill 1 0 1 pattern stripe 120 marksize 4"    #magenta stripped
colour_scheme[14]="newcurve marktype xbar cfill 0 1 1 pattern stripe 120 marksize 4"    #siel stripped
#########################################################################################

work_dir=(`grep working_directory ../config | awk '{print $2}'`)
app_name=(`grep application ../config | awk '{print $2}'`)
test_dir="$work_dir/$app_name$1"
if [ ! -d $test_dir ];then
	echo "Target test directory $test_dir does not exist.";
	echo "Exiting.."
	exit 1
fi



echo "Multigraph started."

sh ../utils/preprocess.sh $test_dir $1 1

cores=(`grep -w "Cpus" $test_dir/info_$1 | tr ':' ' ' | awk '{print $2}'`)
echo "Number of cores: $cores"

limit=(`grep "graph_functions" ../config`)

for (( i=0; i < $cores; i++ ));
do
	col=$(($i*2+1))
	tmp=(`grep cpu$i $test_dir/info_$1`)

	idle_wait=(`echo "scale=4;${tmp[3]} + ${tmp[6]}" | bc 2> /dev/null`)
	system=(`echo "scale=4; (${tmp[2]} + ${tmp[4]} + ${tmp[5]}) / 100" | bc 2> /dev/null`)
	user=(`echo "scale=4; ${tmp[1]} / 100" | bc 2> /dev/null`)

	active_cpu=(`echo "scale=4; $system + $user" | bc 2> /dev/null`)

	tmp_oprof=`mktemp`
	sort -k$col -n -r $test_dir/oprof_results_$1_separate > $tmp_oprof

	tmp_system=`mktemp`
	egrep 'vmlinux|.ko' $tmp_oprof > $tmp_system

	tmp_user=`mktemp`
	egrep -v 'vmlinux|.ko' $tmp_oprof > $tmp_user


	#top function calculation
	tmp=`mktemp`
	for (( j=0; j < 2; j++));do
		k=0
		if [ $j -eq 0 ]; then
			file=$tmp_system
		else
			file=$tmp_user
		fi

		while read line
		do	
			line=(`echo $line | tr [:space:] ' '`)
			len=$((${#line[@]}-1))

			percent=(`echo "scale=4;${line[$col]} * $active_cpu" | bc 2> /dev/null`)
			f_name=${line[$len]}
			space=${line[$(($len-1))]}

			echo "$f_name $space $percent" >> $tmp

			k=$(($k+1));
			if [ "$k" -eq "${limit[1]}" ]; then
				break
			fi
		done < $file
	done

	top_funcs=(`sort -k3 -n -r $tmp | head -n ${limit[1]}`)

	rm -fr $tmp #tmp file contains top function at this point

	user_top=0
	for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} == "vmlinux" -o ${top_funcs[$((j+1))]: -3} == ".ko" ]; then
			#remove individual system functions from file
			line_no=(`grep -n "${top_funcs[$j]}" $tmp_system | tr ':' ' '`)
			echo "${top_funcs[$j]} on line ${line_no[0]}"
			sed -i "$line_no d" $tmp_system
		else
			user_top=(`echo "scale=4; $user_top + ${top_funcs[$j+2]}" | bc`)
		fi
	done

	param="\$$((col+1))"
	tmp_awk=(`awk < $tmp_user "{print $param}" | awk 'BEGIN {a=0} {a+=$1} END {print a}'`)

	user_all=(`echo "scale=4;$tmp_awk *  $active_cpu" | bc 2> /dev/null`)
	user_other=(`echo "scale=4; $user_all - $user_top" | bc 2> /dev/null`)

	filters=(`sh multifilter.sh $tmp_system "$((col+1))"`)


	rm -fr $tmp_user $tmp_oprof $tmp_system

	mount_point=$(($i*13 + 4))

	graph_file=`mktemp`

	echo "(* $1 CPU$i *)" >> $graph_file
	echo "newstring x $mount_point y 104 font Times-Roman fontsize 12 : CPU$i" >> $graph_file

	#idle+iowait
	echo "newcurve marktype xbar cfill 1 1 1 marksize 4 label x $mount_point y -2 hjl vjc : Idle+iowait $idle_wait%" >> $graph_file
	echo "pts" >> $graph_file
	echo "$mount_point	100" >> $graph_file

	k=0
	calc_y=-4
	tmp_sub=100

	last_usr=-1
	#user functions
	for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} != "vmlinux" -a ${top_funcs[$((j+1))]: -3} != ".ko" ]; then
			if [ $last_usr -eq -1 ];  then
				tmp_sub=(`echo "scale=4;$tmp_sub - $idle_wait" | bc 2> /dev/null`)
				last_usr=$j
			else
				tmp_sub=(`echo "scale=4; $tmp_sub - ${top_funcs[$((last_usr+2))]}" | bc 2> /dev/null`)
				last_usr=$j
			fi

			echo "${colour_scheme[$(($k % $c_s_size))]} label x $mount_point y $calc_y hjl vjc : ${top_funcs[$((j+1))]} - ${top_funcs[$j]}  ${top_funcs[$((j+2))]}%" >> $graph_file
			echo "pts" >> $graph_file
			echo "$mount_point	$tmp_sub" >> $graph_file
			echo "newcurve marktype box marksize 5.5 0.001 pts $mount_point $tmp_sub fill 0" >> $graph_file

			k=$((k+1))
			calc_y=$((calc_y - 2))
		fi
	done


	#user other
	if [ $last_usr -eq -1 ]; then
		tmp_sub=(`echo "scale=4; $tmp_sub - $idle_wait" | bc 2> /dev/null`)
	else
		tmp_sub=(`echo "scale=4; $tmp_sub - ${top_funcs[$((last_usr+2))]}" | bc 2> /dev/null`)
	fi

	echo "${colour_scheme[$(($k % $c_s_size))]} label x $mount_point y $calc_y hjl vjc : User Other $user_other%" >> $graph_file
	echo "pts" >> $graph_file
	echo "$mount_point	$tmp_sub" >> $graph_file
	echo "newcurve marktype box marksize 5.5 0.001 pts $mount_point $tmp_sub fill 0" >> $graph_file

	k=$((k+1))
	calc_y=$((calc_y - 2))



	last_sys=-1
	#kernel functions
        for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} == "vmlinux" -o ${top_funcs[$((j+1))]: -3} == ".ko" ]; then
                        if [ $last_sys -eq -1 ];  then
                                tmp_sub=(`echo "scale=4; $tmp_sub - $user_other" | bc 2> /dev/null`)
                                last_sys=$j
                        else
                                tmp_sub=(`echo "scale=4; $tmp_sub - ${top_funcs[$((last_sys+2))]}" | bc 2> /dev/null`)
                                last_sys=$j
                        fi

                        echo "${colour_scheme[$(($k % $c_s_size))]} label x $mount_point y $calc_y hjl vjc : ${top_funcs[$((j+1))]} - ${top_funcs[$j]}  ${top_funcs[$((j+2))]}"
                        echo "pts" >> $graph_file
                        echo "$mount_point      $tmp_sub" >> $graph_file
                        echo "newcurve marktype box marksize 5.5 0.001 pts $mount_point $tmp_sub fill 0" >> $graph_file

                        k=$((k+1))
                        calc_y=$((calc_y - 2))
                fi

	done	



	#filters
	filters_other=0
	last_filter=-1

	for (( j=0; j < $((${#filters[@]}-2)); j=$((j+2)) ));
	do
		perc=(`echo "scale=4; ${filters[$((j+1))]} * $active_cpu" | bc 2> /dev/null`)
		#echo ${filters[$j]} $perc

		cond=(`echo "scale=4; $perc > 1" | bc 2> /dev/null`)
		if [ $cond -eq 1 ]; then
			#should be printed
			if [ $last_filter -eq -1 ]; then
				#first filter printed
				if [ $last_sys -eq -1 ];then
					tmp_sub=(`echo "scale=4; $tmp_sub - $user_other" | bc 2> /dev/null`)
				else
					tmp_sub=(`echo "scale=4; $tmp_sub - ${top_funcs[$((last_sys + 2))]}" | bc 2> /dev/null`)
				fi

				last_filter=$j
			else
				tmp_sub=(`echo "scale=4; $tmp_sub - (${filters[$((last_filter+1))]} * $active_cpu)" | bc 2> /dev/null`)
				last_filter=$j
			fi

			echo "${colour_scheme[$(($k % $c_s_size))]} label x $mount_point y $calc_y hjl vjc : ${filters[$j]} $perc%" >> $graph_file
			echo "pts" >> $graph_file
			echo "$mount_point	$tmp_sub" >> $graph_file
			echo "newcurve marktype box marksize 5.5 0.001 pts $mount_point $tmp_sub fill 0" >> $graph_file

			k=$((k+1))
			calc_y=$((calc_y-2))
		else
			#low percentage, add to filters_other
			filters_other=(`echo "scale=4; $filters_other + $perc" | bc 2> /dev/null`)
		fi
	done

	system_other=(`echo "scale=4;${filters[$((j+1))]} + $filters_other" | bc 2> /dev/null`)

	if [ $last_sys -eq -1 -a $last_filter -eq -1 ]; then
		#user other - (no system,. no filters)
		tmp_sub=(`echo "scale=4;$tmp_sub - $user_other" | bc`)
	elif [ $last_filter -eq -1 ]; then
		#last_sys - (system, no filters)
		tmp_sub=(`echo "scale=4;$tmp_sub - ${top_funcs[$(($last_sys+2))]}" | bc`)
	else
		#last_filter - (both system and filters)
		tmp_sub=(`echo "scale=4; $tmp_sub - ${filters[$(($last_filter+1))]}" | bc`)
	fi
	
	
	#echo "newcurve marktype xbar fill .0 pattern stripe 60 marksize 4 label x $mount_point y $calc_y hjl vjc : System Other $system_other%" >> $graph_file
	echo "newcurve marktype xbar fill .0 pattern stripe 60 marksize 4 label x $mount_point y $calc_y hjl vjc : System Other $tmp_sub%" >> $graph_file
        echo "pts" >> $graph_file
        echo "$mount_point	$tmp_sub" >> $graph_file
       	echo "newcurve marktype box marksize 5.5 0.001 pts $mount_point $tmp_sub fill 0" >> $graph_file



	graph_array[$i]=$graph_file
done


file="$test_dir/multigraph_$1.jgr"

echo "newgraph" >> $file
echo >> $file

echo "xaxis size 19 min 0 max 100" >> $file
echo "xaxis no_auto_hash_marks no_auto_hash_labels" >> $file
echo >> $file

echo "yaxis size 5 hash 12.5 mhash 0 min 0 max 100 label fontsize : CPU(%)" >> $file
echo "yaxis hash_labels fontsize 12" >> $file
echo >> $file

echo "legend custom midspace 3.5 linelength 0.5" >> $file

echo "newstring x 50 y 108 font Times-Roman-Bold fontsize 14 : TITLE" >> $file
echo >> $file

for (( i=0; i < $cores; i++ ));
do
	cat ${graph_array[$i]} >> $file
	rm -fr ${graph_array[$i]}
done

