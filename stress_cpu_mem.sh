#!/bin/bash -x

# %  of free mem
mem_default=${mem_default:-80}

# num of CPUs
cpus_default=${cpus_default:-$(cat /proc/cpuinfo |grep -c processor)}

# time to load in sec
timeout_default=${timeout_default:-10}

cpus=${1:-$cpus_default}
mem=${2:-$mem_default}
timeout=${3:-$timeout_default}

free_mem=$(free -m | awk '/Mem:/{print($4)}')
(( mem_per_worker=free_mem*mem/cpus/100 ))

stress -c $cpus -m $cpus --vm-bytes ${mem_per_worker}M -t ${timeout}s

