#!/bin/bash
#echo -e "\n"
home=`pwd`
echo -e "\n\tEnter full path to sd card image"
read path_sd_card_image
dev_exist=false
unset device
if [ -f $path_sd_card_image ]; then
 	device=$(lsblk --pairs | grep 'RM="1"' | grep -v 'SIZE="0B"' | cut -d " " -f 1 | head -1 | cut -d '"' -f 2)
	if [ -n $device ]; then
	        if [[ -n $(df | grep "/media/$(whoami)" | grep -o "/dev/$device[0-9]") ]]; then
        	        echo -e "\n\t Needs umount!"
                	for dev in $(df | grep "/media/$(whoami)" | grep -o "/dev/$device[0-9]"); do
                        sudo umount $dev
						echo -e "\t\tUmounted $dev"
                	done
        	fi
		echo -e "\n\tПишем на /dev/$device? y/n"
		read do_it
		
		if [ $do_it == "y" ]; then
			sudo dd if=$path_sd_card_image of=/dev/$device status=progress
			sync
			#echo -e "\n\t\t$path_sd_card_image"
			echo ""
			sudo fdisk -l | grep $device  | tee -a $home/log
			cp $home/log $(dirname $path_sd_card_image)/used_files
			root_path=$(sudo fdisk -l | grep $device | grep Linux | cut -d " " -f 1)
			rm -rf tmp_dir && mkdir tmp_dir
			sudo mount $root_path tmp_dir
			cp $(dirname $path_sd_card_image)/used_files ./tmp_dir/home/root -r
			if  [ -d "./tmp_dir/home/root/used_files" ]; then
				echo -e "\n\t\t used files added to sd card on path /home/root/used_files"
			fi
			sudo umount $root_path
		else
			echo -e "...exit"
			sleep 3
			exit
		fi
	else
		echo -e "SD карта не найдена"
	fi
else
	echo -e "\t\t\Path\n $path_sd_card_image\n\t\t\tNOT EXIST!!!"
fi
exit

