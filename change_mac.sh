#!/bin/bash
mac=$(ifconfig | grep ether | cut -d " " -f 10)
if [[ $mac != "90:2b:34:58:86:b0" ]]; then
       	echo -e "\n\t\t\tнеобходиммо изменить MAC сетевой карты, команды:"
	sudo ip link set dev enp2s0 down
	sudo ip link set dev enp2s0 address 90:2b:34:58:86:b0
	sudo ip link set dev enp2s0 up
	mac=$(ifconfig | grep ether | cut -d " " -f 10)
	echo -e "mac chenged to $mac"
fi
