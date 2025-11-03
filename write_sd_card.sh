#!/bin/bash
#echo -e "\n"
#echo -e "\n\tПишем образ на SD карту? y/n"
#read continue
#if [ $continue == "y" ]; then
if [ true ]; then
	echo -e "\n\tEnter full path to sd card image"
	read path_sd_card_image
	dev_exist=false
	unset device
	if [ -f $path_sd_card_image ]; then
		while true; do
			device=$(lsblk --pairs | grep 'RM="1"' | grep -v 'SIZE="0B"' | cut -d " " -f 1 | head -1 | cut -d '"' -f 2)
			device_size=$(lsblk --pairs | grep "$device" | grep 'TYPE="disk"' | cut -d " " -f 4)
            if [[ "$device" == *"sd"* && -n "$device_size" ]]; then
				echo -e "\n\tfound device dev/$device $device_size"
				break
			else
				echo -e "\t\tSD карта не найдена! Вставьте SD карту!"
				sleep 1
				clear
			fi
		done


		#device=$(lsblk --pairs | grep 'RM="1"' | grep -v 'SIZE="0B"' | cut -d " " -f 1 | head -1 | cut -d '"' -f 2)
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
			##########################################################################
			###################  write sd card #######################################
			##########################################################################
				sudo dd if=$path_sd_card_image of=/dev/$device status=progress
				sync
			##########################################################################	
				#echo -e "\n\t\t$path_sd_card_image"
				echo ""
				sudo fdisk -l | grep $device  | tee -a $home/log
				#cp $home/log $(dirname $path_sd_card_image)/used_files
				root_path=$(sudo fdisk -l | grep $device | grep Linux | cut -d " " -f 1)
				rm -rf tmp_dir && mkdir tmp_dir
				sudo mount $root_path tmp_dir
				cp $(find $(dirname $path_sd_card_image)/used_files -maxdepth 1 -type f) ./tmp_dir/home/root -r
				if  [ -d "./tmp_dir/home/root" ]; then
                    echo -e "\n\t SUCCESS !!!\n"
					echo -e "\n\t использованные файлы добавлены в root область SD карты /home/root:"
					for f in $(ls ./tmp_dir/home/root); do
					echo -e "\t\t$f"
					done
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
else
	exit
fi
exit
