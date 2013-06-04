#!/bin/bash
# <copyright file="autograph.sh" organization="FORTH-ICS, Greece">
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

####USER####
test_names=( "exmp_test" )
top_title=( "Example oprofile breakdown" )
sub_titles=( "Exmp Sub" )
graph_name=( "exmpgrph" )
###/USER####

#######################################COLOUR SCHEMES####################################
c_s_size=15
colour_scheme[0]="newcurve marktype xbar cfill 1 1 1 marksize 4"			#white
colour_scheme[1]="newcurve marktype xbar cfill 1 0 0 marksize 4"                        #red
colour_scheme[2]="newcurve marktype xbar cfill 0 0 1 marksize 4"                        #blue
colour_scheme[3]="newcurve marktype xbar cfill 0 1 0 marksize 4"                        #green
colour_scheme[4]="newcurve marktype xbar fill .20 pattern stripe 90 marksize 4"		#blackish stripped		
colour_scheme[5]="newcurve marktype xbar cfill 1 1 0 marksize 4"                        #yellow
colour_scheme[6]="newcurve marktype xbar cfill 0 0 1 pattern stripe 120 marksize 4"     #blue stripped
colour_scheme[7]="newcurve marktype xbar cfill 1 0 1 marksize 4"                        #magenta
colour_scheme[8]="newcurve marktype xbar fill .80 pattern stripe 60 marksize 4"		#blackish stripped
colour_scheme[9]="newcurve marktype xbar cfill 0 1 0 pattern stripe 120 marksize 4"     #green stripped
colour_scheme[10]="newcurve marktype xbar cfill 1 1 0 pattern stripe 120 marksize 4"     #yellow stripped
colour_scheme[11]="newcurve marktype xbar cfill 1 0 1 pattern stripe 120 marksize 4"    #red stripped
colour_scheme[12]="newcurve marktype xbar fill .50 pattern stripe 60 marksize 4"	#blackish stripped
colour_scheme[13]="newcurve marktype xbar cfill 0 1 1 marksize 4"                       #siel
colour_scheme[13]="newcurve marktype xbar cfill 1 0 1 pattern stripe 120 marksize 4"    #magenta stripped
colour_scheme[14]="newcurve marktype xbar cfill 0 1 1 pattern stripe 120 marksize 4"    #siel stripped
#########################################################################################

echo "Autograph started."

if [ ! -f ../config ];then
        echo "  SSWAT ERROR: Config file not found."
        exit 0
fi

work_dir=(`grep working_directory ../config | awk '{print $2}'`)
app_name=(`grep application ../config | awk '{print $2}'`)

for (( z=0; z < ${#test_names[@]}; z++ ));
do
	echo "  Processing test $z: ${test_names[$z]}"
	test_dir="$work_dir/$app_name${test_names[$z]}"

	if [ ! -d ${test_dir} ]; then
		echo "  SSWAT ERROR: Target test directory ${test_dir} does not exist."
		echo "  Exiting."
		exit 1
	fi

	tmp_data=`mktemp`

	#calculate execution time in seconds
	tmp_time=(`cat $test_dir/info_${test_names[$z]} | grep Execution`)
	tmp_time=(`echo ${tmp_time[2]} | tr ':' ' '`)

	tmp_var1=$(( $((${tmp_time[0]} * 60)) + ${tmp_time[1]} ))
	max_y_limit=$tmp_var1

	exec_track[$z]=$max_y_limit
	

	cpu_file="cpu_stats_${test_names[z]}"
	user=(`cat $test_dir/$cpu_file | grep user`)
	system=(`cat $test_dir/$cpu_file | grep system`)
	idle=(`cat $test_dir/$cpu_file | grep idle`)
	sirq=(`cat $test_dir/$cpu_file | grep sirq`)
	irq=(`cat $test_dir/$cpu_file | grep irq`)
	iowait=(`cat $test_dir/$cpu_file | grep iowait`)

	wait=(`echo "scale=4; ${idle[1]} + ${iowait[1]}" | bc`)

	printf "Idle+iowait %.2f %.1f\n" $wait `echo "scale=4; ($wait/100) * $max_y_limit" | bc` >> $tmp_data

	sys_perc=(`echo "scale=4;(${system[1]} + ${irq[1]} + ${sirq[1]})/100" | bc`)
	usr_perc=(`echo "scale=4;${user[1]} / 100" | bc`)

	times[$((z*2))]=`echo "scale=4; $sys_perc*$max_y_limit" | bc`
	times[$((z*2+1))]=`echo "scale=4; $usr_perc*$max_y_limit" | bc`

	active_sum=(`echo "scale=4; $sys_perc+$usr_perc" | bc`)
	######################################################################
	##                      OPROFILE ANALYSIS                           ##
	######################################################################

	#cp $test_dir/oprof_results_$1_aggregate $test_dir/oprof_results_$1_original

	sh ../utils/preprocess.sh $test_dir ${test_names[$z]} 0

	read line < $test_dir/oprof_results_${test_names[$z]}_aggregate
	step=(`echo $line | tr ':' ' '`)
	echo $step
	if [ ${#step[@]} -eq 4 ]; then
		awk_param="\$4, \$3, ( \$2 * $active_sum )"
	else
		awk_param="\$5, \$4, (\$2 * $active_sum)"
	fi


	tmp_oprof=`mktemp`
	awk < $test_dir/oprof_results_${test_names[z]}_aggregate "{ print $awk_param }" > $tmp_oprof

	limit=(`cat ../config | grep "graph_functions"`)
	top_funcs=(`cat $tmp_oprof | head -n ${limit[1]}`)



	#calculate user other
	tmp_user=`mktemp`
	egrep -v 'vmlinux|.ko' $tmp_oprof > $tmp_user

	user_all=(`awk < $tmp_user '{ print \$3 }' | awk 'BEGIN {a=0} {a+=$1} END {print a}'`)

	user_top=0
	for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} != "vmlinux" -a ${top_funcs[$((j+1))]: -3} != ".ko" ]; then
			user_top=(`echo "scale=4; $user_top + ${top_funcs[$((j+2))]}" | bc`)
			printf "%s~%s %.2f %.1f\n" ${top_funcs[$j]} ${top_funcs[$((j+1))]} ${top_funcs[$((j+2))]} `echo "scale=4; (${top_funcs[$((j+2))]}/100) * $max_y_limit" | bc` >> $tmp_data
		else
			line_no=(`grep -n "${top_funcs[$j]}" $tmp_oprof | tr ':' ' '`)
        	        sed -i "$line_no d" $tmp_oprof
		fi
	done

	user_other=(`echo "scale=4; $user_all - $user_top" | bc`)

	printf "User_Other %.2f %.1f\n" $user_other `echo "scale=4; ($user_other/100) * $max_y_limit" | bc` >> $tmp_data


	for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} = "vmlinux" -o ${top_funcs[$((j+1))]: -3} = ".ko" ]; then
			printf "%s~%s %.2f %.1f\n" ${top_funcs[$j]} ${top_funcs[$((j+1))]} ${top_funcs[$((j+2))]} `echo "scale=4; (${top_funcs[$((j+2))]}/100) * $max_y_limit" | bc ` >> $tmp_data
		fi
	done

	####calculate filters####
	tmp_system=`mktemp`
	egrep 'vmlinux|.ko' $tmp_oprof > $tmp_system

	filters=(`sh /home1/public/spapageo/sswat/graphing/multifilter.sh $tmp_system 3`)


	#have to calculate filters_other here!

	filters_other=0
	for (( i=0 ; i < $((${#filters[@]} - 2)); i=$((i+2)) ));
	do

		if [[ ${filters[$((i+1))]} == *e* ]];then
			cond=1;
		else
			cond=`echo "${filters[$((i+1))]} < 1" | bc`;
		fi

		if [ $cond -eq 1 ];then
			filters_other=(`echo "scale=4; $filters_other + ${filters[$((i+1))]}" | bc 2> /dev/null`)
		else
			printf "%s %.2f %.1f\n" ${filters[i]} ${filters[$((i+1))]} `echo "scale=4; (${filters[$((i+1))]} / 100) * $max_y_limit" | bc ` >> $tmp_data
		fi
	done

	system_other=(`echo "scale=4; ${filters[$((i+1))]} + $filters_other" | bc 2> /dev/null`)
	printf "System_Other %.2f %.1f\n" $system_other `echo "scale=4; ($system_other / 100) * $max_y_limit" | bc 2> /dev/null` >> $tmp_data

	data_files[$z]=$tmp_data

	rm -fr $tmp_oprof $tmp_system $tmp_user

	###################################
	##	END OF OPROF             ##
	###################################

done



if [ ${#test_names[@]} -eq 1 ];then
	file="$test_dir/graph_$graph_name.jgr"
else
	file="graph_$graph_name.jgr"
fi


xmax=$(((${#test_names[@]}-1)*13 + 7))

ymax=0
for (( i=0; i < ${#exec_track[@]}; i++ ));
do
	if [ $ymax -lt ${exec_track[$i]} ];then
		ymax=${exec_track[$i]}
	fi
done

#DO SOMETHING ABOUT THE axis SIZES!!!
case "${#test_names[@]}" in
        "1")
		xsize=5
		;;
        "2")
		xsize=7
                ;;
        "3")
                xsize=10
                ;;
        "4")
		xsize=14
		;;
	"5")
		xsize=18
		;;
esac


if [ "$ymax" -lt 30 ]; then
        ysize=4
elif [ "$ymax" -lt 70 ]; then
       	ysize=5
elif [ "$ymax" -lt 150 ]; then
	ysize=7
elif [ "$ymax" -lt 500 ]; then
       	ysize=10
else
   	ysize=20
fi


echo "newgraph" 											> $file
echo	 												>> $file

echo "xaxis size $xsize min 0 max $xmax" 								>> $file
echo "xaxis no_auto_hash_marks no_auto_hash_labels" 							>> $file
echo 													>> $file

echo "yaxis size $ysize hash 12.5 mhash 0 min 0 max $ymax label fontsize : Execution Time (sec)"	>> $file
echo "yaxis hash_labels fontsize 12" 									>> $file
echo " " 												>> $file

echo "legend custom midspace 3.5 linelength 0.5" >> $file
echo "newstring x $((xmax/2)) y $((ymax+10)) font Times-Roman-Bold fontsize 14 : $top_title" 		>> $file


calc_y=-2
for (( z=0; z < ${#test_names[@]}; z++ ));
do
	tmp_sub=${exec_track[$z]}

	echo "(* ${test_names[$z]} *)" 									>> $file

	mount_point=$((z*13+4))

	echo "newstring x $mount_point y $((ymax+5)) font Times-Roman fontsize 12 : ${sub_titles[z]}" >> $file

	#Ola ta data vriskontai sta data_files. Arkei na diavazw kai na afairw...
	k=0 #number of tests read so far..
	calc_y=-2

	total_lines=(`wc -l ${data_files[$z]}`)
	total_lines=$((total_lines-1))

	while read line;
	do
		line=(`echo $line | tr [:space:] ' '`)
		len=${#line[@]}

		tmp=(`echo ${line[0]} | tr '~' ' '`)

		time=${line[len-1]}
		perc=${line[len-2]}
		if [ $k -lt $total_lines ];then
			str="${colour_scheme[$((k % c_s_size))]} label x $mount_point y $calc_y hjl vjc : ${tmp[@]} $perc% [$time s]"
		else
			str="newcurve marktype xbar fill .0 pattern stripe 60 marksize 4 label x $mount_point y $calc_y hjl vjc : ${tmp[@]} $perc% [$time s]"
		fi

		echo $str									 >> $file
		echo "pts"									 >> $file
		echo "$mount_point	$tmp_sub"						 >> $file

		if [ $k -gt 0 ];then
			echo "newcurve marktype box marksize 5.5 0.001 pts $mount_point $tmp_sub fill 0" >> $file
		fi

		tmp_sub=(`echo "scale=4;$tmp_sub - $time" | bc `)
		k=$((k+1))
		calc_y=$((calc_y-2))

	done < ${data_files[$z]}
	

	calc_y=$(($calc_y-4))
	echo "newstring x $mount_point y $calc_y : Execution time: ${exec_track[$z]} sec" >> $file

	calc_y=$(($calc_y-2))
	echo "newstring x $mount_point y $calc_y : Total system time: ${times[$((z*2))]}" >> $file

	calc_y=$(($calc_y-2))
	echo "newstring x $mount_point y $calc_y : Total user time: ${times[$((z*2+1))]} sec" >> $file

	echo >> $file
	echo >> $file

	calc_y=-2
	tmp_sub=$ymax

	rm -fr ${data_files[$z]}

done

echo "Graph created successfully."


