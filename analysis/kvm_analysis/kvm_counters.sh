#!/bin/bash
# <copyright file="kvm_counters.sh" organization="FORTH-ICS, Greece">
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

if [ ! -f $1/$2$3/stats/kvm_counters_before ];then
	echo "  SSWAT ERROR: kvm_counters_before file not found."
	exit 0
fi

if [ ! -f $1/$2$3/stats/kvm_counters_after ];then
	echo "  SSWAT ERROR: kvm_counters_after file not found."
	exit 0
fi


kvm_counters[1]="efer_reload"
kvm_counters[2]="exits"
kvm_counters[3]="fpu_reload"
kvm_counters[4]="halt_exits"
kvm_counters[5]="halt_wakeup"
kvm_counters[6]="host_state_reload"
kvm_counters[7]="hypercalls"
kvm_counters[8]="insn_emulation"
kvm_counters[9]="insn_emulation_fail"
kvm_counters[10]="invlpg"
kvm_counters[11]="io_exits"
kvm_counters[12]="irq_exits"
kvm_counters[13]="irq_injections"
kvm_counters[14]="irq_window"
kvm_counters[15]="largepages"
kvm_counters[16]="mmio_exits"
kvm_counters[17]="mmu_cache_miss"
kvm_counters[18]="mmu_flooded"
kvm_counters[19]="mmu_pde_zapped"
kvm_counters[20]="mmu_pte_updated"
kvm_counters[21]="mmu_pte_write"
kvm_counters[22]="mmu_recycled"
kvm_counters[23]="mmu_shadow_zapped"
kvm_counters[24]="mmu_unsync"
kvm_counters[25]="nmi_injections"
kvm_counters[26]="nmi_window"
kvm_counters[27]="pf_fixed"
kvm_counters[28]="pf_guest"
kvm_counters[29]="remote_tlb_flush"
kvm_counters[30]="request_irq"
kvm_counters[31]="signal_exits"
kvm_counters[32]="tlb_flush"


echo "KVM counters:" >> $1/$2$3/info_$3
echo "-------------" >> $1/$2$3/info_$3

for (( i=1 ; i <= ${#kvm_counters[@]}; i++ ));
do
	before=(`grep ${kvm_counters[$i]} $1/$2$3/stats/kvm_counters_before`)
	after=(`grep ${kvm_counters[$i]} $1/$2$3/stats/kvm_counters_after`)

	diff=`expr ${after[1]} - ${before[1]}`

	echo "${kvm_counters[$i]}: $diff" >> $1/$2$3/info_$3
done

