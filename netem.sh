#!/bin/bash
  
my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

function usage(){
    echo "Options:"
    echo -e "--nic <nic>        # interface name (mandatory)\n" \
         "[--rate 100]          # rate in mbs\n" \
         "[--delay 100]         # delay in ms\n" \
         "[--loss 10]           # packet loss in %\n" \
         "[--corrupt 10]        # corrupt level in %\n" \
         "[--duplicate 10]      # duplicate level in %\n" \
         "[--cleanup]           # remove all rules %\n"
}

nic=''
rate=''
delay=''
loss=''
corrupt=''
duplicate=''
cleanup=''

while [[ -n "$1" ]] ; do
    case $1 in
        '--nic')
            nic="$2"
            ;;
        '--rate')
            rate="$2"
            ;;
        '--delay')
            delay="$2"
            ;;
        '--loss')
            loss="$2"
            ;;
        '--corrupt')
            corrupt="$2"
            ;;
        '--duplicate')
            duplicate="$2"
        '--cleanup')
            cleanup="true"
            shift 1
            continue
            ;;            
        *)
            echo "ERROR: unknown options '$1'"
            usage
            exit -1
            ;;
    esac
    shift 2
done

if [ -z "$nic" ] ; then
fi

# remove all rules if any
tc qdisc del dev $nic root || true

if [ -n "$cleanup" ] ; then
    exit
fi

netem_opts=''
[ -n "$delay" ] && netem_opts+="delay ${delay}ms"
[ -n "$netem_opts" ] && netem_opts+=" "
[ -n "$loss" ] && netem_opts+="loss ${loss}%"
[ -n "$netem_opts" ] && netem_opts+=" "
[ -n "$corrupt" ] && netem_opts+="corrupt ${corrupt}%"
[ -n "$netem_opts" ] && netem_opts+=" "
duplicate
[ -n "$duplicate" ] && netem_opts+="duplicate ${duplicate}%"

rate_opts=''
if [ -n "$rate" ] ; then
    rate_opts+="rate ${rate}mbit burst 32kbit"
fi

if [[ -z "$netem_opts" && -z "$rate_opts" ]]  ; then 
  usage
  exit -1  
fi

# add delay (egress traffic)
tc qdisc add dev $nic root handle 1:0 netem $netem_opts

# add rate filter if eny (egress traffic)
if [ -n "$rate_opts" ] ; then
    tc qdisc add dev $nic parent 1:1 handle 10: tbf $rate_opts
fi
