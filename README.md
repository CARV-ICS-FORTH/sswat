# SSWAT v1.0: System Wide Analysis Tool

SSWAT is a performance analysis framework, suitable for profiling both
at the user and kernel level. Using oprofile (a system wide profiler)
and multiple GNU/Linux utilities it speeds up data analysis through automation
and offers a novel approach in performance analysis/debugging by visualizing
profiling results combined with CPU statistics.

## Features and use-cases

A short list of the features currently supported by SSWAT
- extensible data capturing framework
- automated data analysis (iostat/vmstat/proc entries, etc.)
- testbed information archiving (kernel version, hardware information, machine info, etc.)
- CPU time stacked-bar graphs using jgraph and gnuplot (aggregate and per-CPU)
- device utilization graphs

SSWAT can be used in performance debugging and performance analysis scenarios.
It is also particularly useful for performance evaluation in kernel module
development cases.

For a complete list of features and a guide on how to use SSWAT, please consult
the [accompanying tutorial](SSWAT_tutorial.pdf) provided with the source files.

## Requirements

SSWAT requires:
- oprofile (0.9.2 or later)
- gnuplot (4.6 or later)
- standard GNU/Linux utilities (grep/egrep, cat/tac, sort, uniq, sed, awk, bs)
- the parser provided requires the C++ boost library

For a full list of dependencies please consult the accompanying tutorial
provided with the source files.

## Known issues

- Fault conditions (e.g. missing files, missing entries in existing files) are
not thoroughly checked in some cases. These faults do not generaly affect
correctness but might print unhandled error messages.

## Contact info

For any bugs or suggestions please contact: sswat@ics.forth.gr

---

**This code is solely the property of FORTH_ICS and is provided under a License from the Foundation of Research and Technology - Hellas (FORTH), Institute of Computer Science (ICS), Greece. Downloading this software implies accepting the [provided license](sswat_license.pdf).**
