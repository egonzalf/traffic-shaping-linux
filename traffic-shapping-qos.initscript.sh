#!/bin/sh

# Define your interfaces
WAN='eth0'
LAN='br-lan'

rc_done="  done"
rc_failed="  failed"

lim=9500 # Set you upload limit
unit="kbit"
limite="$lim$unit"
# Limits for each class
lim110="$((lim*5/100))$unit"
lim120="$((lim*20/100))$unit"
lim130="$((lim*25/100))$unit"
lim140="$((lim*15/100))$unit"
lim150="$((lim*20/100))$unit"
lim160="$((lim*5/100))$unit"
lim170="$((lim*5/100))$unit"


return=$rc_done

TC=$(which tc)

tc_reset ()
{
	# Resets to a clear state
	$TC qdisc del dev $WAN root 2> /dev/null > /dev/null
}

tc_status ()
{
	#echo "[qdisc - $WAN]"
	#$TC -s qdisc show dev $WAN
	#echo "------------------------"
	#echo
	echo "[class - $WAN]"
	$TC -s class show dev $WAN
}

tc_showfilter ()
{
	echo "[filter - $WAN]"
	$TC -s filter show dev $WAN
}

case "$1" in

	start)
	echo -n "Starting traffic shaping"
	tc_reset
	# Creates qdisc
	$TC qdisc add dev $WAN root handle 1: htb default 170

	# Add classes
	$TC class add dev $WAN parent 1: classid 1:10 htb rate $limite ceil $limite
	$TC class add dev $WAN parent 1:10 classid 1:110 htb rate $lim110 ceil $limite prio 0
	$TC class add dev $WAN parent 1:10 classid 1:120 htb rate $lim120 ceil $limite prio 1
	$TC class add dev $WAN parent 1:10 classid 1:130 htb rate $lim130 ceil $limite prio 2
	$TC class add dev $WAN parent 1:10 classid 1:140 htb rate $lim140 ceil $limite prio 3
	$TC class add dev $WAN parent 1:10 classid 1:150 htb rate $lim150 ceil $limite prio 4
	$TC class add dev $WAN parent 1:10 classid 1:160 htb rate $lim160 ceil $limite prio 5 
	$TC class add dev $WAN parent 1:10 classid 1:170 htb rate $lim170 ceil $limite prio 6

	# Dont forget toinvoke filter scripts, either here or another script

	tc_status
	;;

	 stop)
	echo -n "Stopping traffic shaper"
	tc_reset || return=$rc_failed
	echo -e "$return"
	;;

	restart|reload)
	$0 stop && $0 start || return=$rc_failed
	;;

	stats|status)
	tc_status
	;;

	filter)
	tc_showfilter
	;;

	*)
	echo "Usage: $0 {start|stop|restart|stats|filter}"
	exit 1

esac

test "$return" = "$rc_done" || exit 1
