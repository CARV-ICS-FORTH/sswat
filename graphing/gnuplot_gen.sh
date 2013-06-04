#!/bin/bash
# <copyright file="gnuplot_gen.sh" organization="FORTH-ICS, Greece">
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
test_names=( "Blast_noIO" "Blast_withIO" )
top_title="Blast: oprofile breakdown examples"
sub_titles=( "blast_mem" "blast_io" )
graph_name="blast_exmp"
###/USER####

#######################################ColorStylesRGB####################################
color_rgb=( "white" "black" "web-blue" "red" "purple" "green" "brown" "blue" "olive" "orange" "dark-violet" "yellow" "dark-chartreuse" "aquamarine" "plum" "seagreen" "magenta" "dark-turquoise" )
#########################################################################################

#######################################AT&KEY ARRRAY#####################################
at_array=( "0" "-1" "1" "-2" "0" "2" "-2" "-1" "1" "2" )
key_array=( "0.65" "0.41" "0.80" "0.30" "0.62" "0.92" "0.24" "0.50" "0.74" "0.99" )
	     #n1    #n2a   #n2b   #n3a   #n3b   #n3c
#########################################################################################
echo "Gnuplot_gen started."

if [ ! -f ../config ];then
        echo "  SSWAT ERROR: Config file not found."
        exit 0
fi

work_dir=(`grep working_directory ../config | awk '{print $2}'`)
app_name=(`grep application ../config | awk '{print $2}'`)

max_yrange=0
num_of_tests=${#test_names[@]}

for (( z=0 ; z < $num_of_tests ; z++ ));do
	test_dir="$work_dir/$app_name${test_names[$z]}"


        if [ ! -d $test_dir ];then
                echo "  SSWAT ERROR: Target test directory ${test_dir}does not exist. Skipping."
		exit 1
        fi


	#calculate execution time in seconds
	tmp_time=(`cat $test_dir/info_${test_names[$z]} | grep Execution`)

	tmp_time=(`echo ${tmp_time[2]} | tr ':' ' '`)

	tmp_var1=$(( $((${tmp_time[0]} * 60)) + ${tmp_time[1]} ))
	max_y_limit=$tmp_var1

	if [ $max_yrange -lt $max_y_limit ]; then
		max_yrange=$max_y_limit;
	fi

	user=(`cat $test_dir/cpu_stats_${test_names[$z]} | grep user`)
	system=(`cat $test_dir/cpu_stats_${test_names[$z]} | grep system`)
	idle=(`cat $test_dir/cpu_stats_${test_names[$z]} | grep idle`)
	sirq=(`cat $test_dir/cpu_stats_${test_names[$z]} | grep sirq`)
	irq=(`cat $test_dir/cpu_stats_${test_names[$z]} | grep irq`)
	iowait=(`cat $test_dir/cpu_stats_${test_names[$z]} | grep iowait`)

	wait=(`echo "scale=4;${idle[1]} + ${iowait[1]}" | bc`)

	irqs=(`echo "scale=4;${irq[1]} + ${sirq[1]}" | bc`)


	sys_perc=(`echo "scale=4;(${system[1]} + $irqs)/100" | bc`)
	usr_perc=(`echo "scale=4;${user[1]} / 100" | bc`)

	active_sum=(`echo "scale=4;$sys_perc+$usr_perc" | bc`)
	active_time=(`echo "scale=4;$active_sum * $max_y_limit" | bc`)


	#echo "Active sum: $active_sum"


	######################################################################
	##                      OPROFILE ANALYSIS                           ##
	######################################################################
	sh ../utils/preprocess.sh $test_dir ${test_names[$z]} 0

	read line < $test_dir/oprof_results_${test_names[$z]}_aggregate
        step=(`echo $line | tr ':' ' '`)

	if [ ${#step[@]} -eq 4 ]; then
		awk_param="\$4, \$3, (\$2 * $active_sum)"
	else
		awk_param="\$5, \$4, (\$2 * $active_sum)"
	fi

	tmp_oprof=`mktemp`
	awk < $test_dir/oprof_results_${test_names[$z]}_aggregate "{ print $awk_param }" > $tmp_oprof

	limit=(`cat ../config | grep "graph_functions"`)

	top_funcs=(`cat $tmp_oprof | head -n ${limit[1]}`)



	#calculate user other

	tmp_user=`mktemp`
	egrep -v 'vmlinux|.ko' $tmp_oprof > $tmp_user

	tmp_system=`mktemp`
	egrep 'vmlinux|.ko' $tmp_oprof > $tmp_system

	user_all=(`awk < $tmp_user '{ print \$3 }' | awk 'BEGIN {a=0} {a+=$1} END {print a}'`)

	user_top=0
	for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} != "vmlinux" -a ${top_funcs[$((j+1))]: -3} != ".ko" ]; then
			user_top=(`echo "scale=4;$user_top + ${top_funcs[$((j+2))]}" | bc`)
		else
			line_no=(`grep -n "${top_funcs[$j]}" $tmp_oprof | tr ':' ' '`)
	                #echo "${top_funcs[$j]} on line ${line_no[0]}"
	                sed -i "$line_no d" $tmp_system
		fi
	done

	user_other=(`echo "scale=4;$user_all - $user_top" | bc `)

	#echo "user_all = $user_all"
	#echo "user_top = $user_top"
	#echo "user_other = $user_other"
	#echo 

	####calculate filters####
	filters=(`sh multifilter.sh $tmp_system 3`)

	rm -fr $tmp_system $tmp_user $tmp_oprof


	###################################
	##	END OF OPROF             ##
	###################################
	tmp_label=`mktemp`

	data_file="data_${graph_name}.dat"

	data_line=""


	#IDLE_IOWAIT
	time=(`echo "scale=4;($wait/100) * $max_y_limit" | bc`)
	data_line="$time ${data_line}"
	printf "Idle+iowait %.2f%% [%.1f s]\n" $wait $time >> $tmp_label

	
	#user functions
	for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} != "vmlinux" -a ${top_funcs[$((j+1))]: -3} != ".ko" ]; then
			time=(`echo "scale=4; (${top_funcs[$((j+2))]}/100) * $max_y_limit" | bc`)
			data_line="$time ${data_line}"
			printf "%s - %s %.2f%% [%.1f s]\n" ${top_funcs[$j]} ${top_funcs[$((j+1))]} ${top_funcs[$((j+2))]} $time >> $tmp_label
		fi
	done


	#user other
	time=(`echo "scale=4;($user_other/100) * $max_y_limit" | bc `)
	data_line="$time ${data_line}"
	printf "UserOther %.2f%% [%.1f s]\n" $user_other $time >> $tmp_label


	##kernel functions
	for (( j=0; j < ${#top_funcs[@]}; j=$((j+3)) ));
	do
		if [ ${top_funcs[$((j+1))]} == "vmlinux" -o ${top_funcs[$((j+1))]: -3} == ".ko" ]; then
			time=(`echo "scale=4;(${top_funcs[$((j+2))]}/100) * $max_y_limit" | bc`)
			data_line="$time ${data_line}"
			printf "%s - %s %.2f%% [%.1f s]\n" ${top_funcs[$j]} ${top_funcs[$((j+1))]} ${top_funcs[$((j+2))]} $time >> $tmp_label
		fi
	done


	#filters
	filters_other=0
	for ((j=0; j < $((${#filters[@]} - 2)); j=$((j+2)) ));
	do
		perc=${filters[$((j+1))]}
		cond=(`echo "scale=4; $perc > 1" | bc`)
		if [ $cond -eq 1 ];then
			#should be printed
			time=(`echo "scale=4;(${filters[$((j+1))]} / 100) * $max_y_limit" | bc`)
			data_line="$time ${data_line}"
			printf "%s %.2f%% [%.1f s]\n" ${filters[$j]} $perc $time >> $tmp_label
		else
			filters_other=(`echo "scale=4;$filters_other + $perc" | bc`)
		fi
	done

	#system other
	system_other=(`echo "scale=4;${filters[$((j+1))]} + $filters_other" | bc`)
	time=(`echo "scale=4;($system_other/100) * $max_y_limit" | bc`)

	if [[ ${sub_titles[$z]} == *_* ]];then
		tmp_subtitle=(`echo ${sub_titles[$z]} | sed 's/_/\\\\\\\_/g'`)
		sub_titles[$z]=$tmp_subtitle
	fi

	data_line="${sub_titles[$z]} $time ${data_line}"
	printf "SystemOther %.2f%% [%.1f s]\n" $system_other $time >> $tmp_label

	echo "$data_line" >> $data_file

	tmp_reverse=`mktemp`
	tac $tmp_label > $tmp_reverse
	rm -fr $tmp_label

	label_files[$z]=$tmp_reverse


	#FIND A WAY TO PRINT THESE TOO!
	#Execution time: $max_y_limit sec
	#tmp_var=(`echo "scale=4;$sys_perc * $max_y_limit" | bc`)
	#Total system time: $tmp_var sec
	#tmp_var=(`echo "scale=4;$usr_perc * $max_y_limit" | bc`)
	#Total user time: $tmp_var sec

done

#Fix label subscripts with escape characters
#for (( i=0; i < ${#label_files[@]}; i++ ));
#do
#	sed -i 's/_/\\\\_/g' ${label_files[i]}
#done

#COLOR CALCULATION
color_match=`mktemp`

for (( i=0; i < ${#label_files[@]}; i++ ));
do
	awk '{ print $1 }' < ${label_files[$i]} >> $color_match
done

color_pre=(`sort $color_match | uniq`)

rm -fr $color_match
color_match=`mktemp`

k=3
for (( i=0; i < ${#color_pre[@]}; i++ ));
do
	if [ ${color_pre[$i]} == "Idle+iowait" ]; then
		cstr="${color_pre[$i]} 0"
	elif [ ${color_pre[$i]} == "SystemOther" ]; then
		cstr="${color_pre[$i]} 1"
	elif [ ${color_pre[$i]} == "UserOther" ]; then
		cstr="${color_pre[$i]} 2"
	else
		cstr="${color_pre[$i]} $k"
		k=$((k+1))
	fi
	echo $cstr >> $color_match
done

echo $color_match
colors_needed=$i

if [ $colors_needed -gt ${#color_rgb[@]} ];then
	echo "MORE COLORS NEEDED!"
	exit
fi



gnuplot_script="script_$graph_name.gp"
######GNUPLOT SCRIPT GENERATOR#####

echo "set terminal postscript enhanced color \"Helvetica\" 10"		> $gnuplot_script
echo "set output \"graph_$graph_name.ps\"" 				>> $gnuplot_script
echo "set title \"$top_title\""						>> $gnuplot_script
echo "set style data histogram"						>> $gnuplot_script
echo "set style histogram rowstacked"					>> $gnuplot_script
echo "set style fill solid 1.00 border -1"				>> $gnuplot_script
echo "set boxwidth 0.5 relative"					>> $gnuplot_script
echo  									>> $gnuplot_script


#Possibly parametrics
echo "set size ratio 0.5"						>> $gnuplot_script
echo "set origin 0,-0.125"						>> $gnuplot_script

echo "set xtics 10 nomirror"						>> $gnuplot_script
echo "set mxtics 1"							>> $gnuplot_script

if [ $max_yrange -gt 1000 ];then
	ytics=100
	yplus=200
elif [ $max_yrange -lt 1000 -a $max_yrange -gt 500 ];then
	ytics=50
	yplus=100
else
	ytics=10
	yplus=50
fi

echo "set ytics $ytics nomirror"					>> $gnuplot_script
echo "set mytics 1"							>> $gnuplot_script
echo 									>> $gnuplot_script


echo "set yrange [0:$((max_yrange+yplus))]"				>> $gnuplot_script
echo "set ylabel \"Execution time(sec)\""				>> $gnuplot_script
echo									>> $gnuplot_script

#origin of graph box!!
#echo "set origin 0,-0,2"


#determine mount points (goto var) and key font size
case "$num_of_tests" in
	"1")
		goto=0
		;;
	"2")
		goto=1
		;;
	"3")
		goto=3
		echo "set key font \",8\""				>> $gnuplot_script
		;;
	"4")
		goto=6
		echo "set key font \",6.5\""				>> $gnuplot_script
esac



echo "set multiplot"							>> $gnuplot_script
echo 									>> $gnuplot_script

echo "set lmargin at screen .1"						>> $gnuplot_script
echo "set rmargin at screen .9"						>> $gnuplot_script
echo "set tmargin at screen .9"						>> $gnuplot_script
echo "set bmargin at screen .2"						>> $gnuplot_script
echo									>> $gnuplot_script

#colors...
#set style line 1 lc rgb "white"
for (( i=0; i < $colors_needed; i++ ));
do
	echo "set style line $((i+1)) lc rgb \"${color_rgb[$i]}\""	>> $gnuplot_script
done
echo "set style increment user"						>> $gnuplot_script
echo									>> $gnuplot_script

################################
#PLOTTING..
#plot boxes first, without keys
echo "unset key"							>> $gnuplot_script

command_line="plot "
for (( i=0; i < $num_of_tests; i++ ));
do
	
	command_line="${command_line}newhistogram at ${at_array[$((i+goto))]}, '< head -$((i+1)) $data_file | tail -1'"

	col=2
	lines=(`wc -l ${label_files[$i]}`)
	while read line;
	do
		line=(`echo $line | tr [:space:] ' '`)

		cstyle=(`grep ${line[0]} $color_match`)

		if [ $col -eq 2 ];then
			command_line="${command_line} using $col ls $((${cstyle[1]} + 1))"
		elif [ $col -eq $((lines+1)) ];then
			command_line="${command_line} ,'' using $col:xtic(1) ls $((${cstyle[1]} + 1))"
		else
			command_line="${command_line} ,'' using $col ls $((${cstyle[1]} + 1))"
		fi

		col=$((col+1))
	done < ${label_files[$i]}

	if [ $i -lt $(($num_of_tests - 1)) ]; then
		command_line="${command_line}, \\"
	fi

	echo "$command_line"						>> $gnuplot_script
	command_line=""
done

echo 									>> $gnuplot_script
echo 									>> $gnuplot_script
echo "unset xtics"							>> $gnuplot_script
echo 									>> $gnuplot_script
echo 									>> $gnuplot_script



tmp_reverse=`mktemp`
sed_file=`mktemp`
for (( i=0; i < $num_of_tests; i++ ));
do
	tac ${label_files[$i]} > $tmp_reverse
	echo "set key at screen ${key_array[$((goto+i))]},0.14"		>> $gnuplot_script

	command_line="plot "
	lines=(`wc -l ${label_files[$i]}`)
	cnt=0
	while read line;
	do
		tmp=(`echo $line | tr [:space:] ' '`)
                cstyle=(`grep ${tmp[0]} $color_match`)

		echo $line > $sed_file | sed -i 's/_/\\\\_/g' $sed_file

		tmp=(`cat $sed_file`)

		command_line="${command_line} NaN t \"${tmp[@]}\" with boxes ls $((${cstyle[1]}+1))"

		if [ $cnt -lt $((lines-1)) ]; then
			command_line="${command_line}, "
		fi
		cnt=$((cnt+1))

	done < $tmp_reverse

	echo ${command_line}						>> $gnuplot_script
	echo 								>> $gnuplot_script

done
echo "unset multiplot"							>> $gnuplot_script


#CLEANUP
rm -fr $tmp_reverse $color_match $sed_file
for (( i=0; i < ${#label_files[@]}; i++ ));
do
	rm -fr ${label_files[$i]}
done
