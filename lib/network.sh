#!/bin/bash

if [ ! -f lib/lib.sh ]
then
	echo "Error: lib/lib.sh not found!"
	echo "make sure you are in the root of the server repo"
	exit 1
fi

source lib/lib.sh

PORT="$(get_tw_config sv_port 8303)"
CAPPATH=/tmp
CAPFILE="$CAPPATH"/tmp-port-"$PORT".pcap
arg_plain=0

mkdir -p "$CAPPATH"

function w_dumpcap() {
	if [ "$#" != "1" ]
	then
		echo "Error: invalid amount of args to $0"
		exit 1
	fi
	eval "sudo dumpcap $1"
}

function w_tcpdump() {
	if [ "$#" != "1" ]
	then
		echo "Error: invalid amount of args to $0"
		exit 1
	fi
	eval "sudo tcpdump $1"
}

function t_bold() {
	if [ "$arg_plain" == "1" ]
	then
		return
	fi
	tput bold
}

function t_normal() {
	if [ "$arg_plain" == "1" ]
	then
		return
	fi
	tput sgr0
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$#" == "0" ]
then
	echo "usage: $(basename "$0") [OPTIONS]"
	echo "options:"
	echo "  src             show source port ips"
	echo "  dst             show destination port ips"
	echo "  l|listen        capture tcpdump"
	echo "  -t <seconds>    capture tcpdump for seconds"
	echo "  whisper         sniff whisper"
	echo "  15min           record 3x 5 mins"
	echo "  buffer          record file size ring buffer"
	echo "  --plain         use plain txt output (nothing bold)"
	echo "examples:"
	echo ""
	echo "  Listen until pressing ctrl+c then show all destionation ips"
	t_bold
	echo "    $(basename "$0") l && $(basename "$0") dst"
	t_normal
	echo ""
	echo "  Listen 3 seconds then show all source ips"
	t_bold
	echo "    $(basename "$0") -t 2 src"
	t_normal
	exit 0
fi

while true
do
	arg="$1"
	shift

	if [ "$arg" == "" ]
	then
		break
	fi

	if [ "$arg" == "-t" ]
	then
		seconds="$1"
		shift
	if [ "$seconds" == "" ]
	then
		echo "Error: missing arg <seconds>"
		exit 1
	fi
	w_dumpcap "-a duration:\"$seconds\" -w \"$CAPFILE\" -f \"port $PORT\" 2> /dev/null"
	elif [ "$arg" == "--plain" ]
	then
		arg_plain=1
	elif [ "$arg" == "src" ]
	then
		src=1
	elif [ "$arg" == "dst" ]
	then
		dst=1
	elif [ "$arg" == "listen" ] || [ "$arg" == "l" ]
	then
		w_tcpdump "-w \"$CAPFILE\" \"port $PORT\""
	elif [ "$arg" == "whisper" ]
	then
		tshark -x -Y 'udp contains whisper' "udp port $PORT"
	elif [ "$arg" == "15min" ]
	then
		echo "[*] record 15 minues in 3x 5 minutes cap files"
		w_tcpdump "-w \"${CAPPATH}/5min_buffer_$PORT-%F_%H-%M-%S\" -W 3 -G 300 \"port 7303\""
	elif [ "$arg" == "buffer" ]
	then
		echo "[*] record ring buffer"
		w_tcpdump "-w \"${CAPPATH}/${PORT}_\" -W 5 -C 5000 \"port $PORT\""
	else
		echo "unknown arg '$arg' see --help"
		exit 1
	fi
done

if [ "$src" ]
then
	t_bold
	echo "SOURCE"
	t_normal
	w_tcpdump "-nn \"src port $PORT\" -r \"$CAPFILE\"" | \
		cut -d' ' -f5 | cut -d'.' -f1-4 | sort | uniq -c | sort -nr
fi

if [ "$dst" ]
then
	t_bold
	echo "DESTINATION"
	t_normal
	w_tcpdump "-nn \"dst port $PORT\" -r \"$CAPFILE\"" | \
		cut -d' ' -f3 | cut -d'.' -f1-4 | sort | uniq -c | sort -nr
fi

