.#!/bin/bash
home=$('pwd')
rm -rf $home/log
########## check compiler
compiler="./gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf"
if [ ! -d $compiler ]; then
	echo -e "\n\tнеобходимо установить компайлер, команды:" | tee -a $home/log
	echo "wget https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz"
	wget https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz
	echo "tar xf gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz"
	tar xf gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz
	echo "rm gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz"
fi
if [ -d "./gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin" ]; then
	export PATH=`pwd`/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin:$PATH
else
	echo -e "\n\t\t\INSTALL COMPILER !!!\n" | tee -a $home/log
	exit
fi

a10_example_sdmmc=$('pwd')/a10_example.sdmmc
#echo $a10_example_sdmmc
#find_dir=$(find . -maxdepth 1 -type d -name $a10_example_sdmmc)
#dir_exist=$(find_dir ". -maxdepth 1 -type d -name $a10_example_sdmmc")

#check=$(file $a10_example_sdmmc | cut -d ":" -f 2-)
#echo "check=$check"
if [ $(file $a10_example_sdmmc | cut -d ":" -f 2-) == "directory" ]; then
	cd $a10_example_sdmmc
	TOP_FOLDER=`pwd`
	echo -e "\t\tTOP_FOLDER=$TOP_FOLDER" | tee -a $home/log
else
	echo -e "\t$a10_example_sdmmc direcitory doesn't exist, \n\tdo build manually" | tee -a $home/log
	exit
fi
QUARTUS_ROOTDIR=/home/ignat/Quartus/Quartus_pro_21_4/quartus
if [ -d "$QUARTUS_ROOTDIR" ]; then
	export QUARTUS_ROOTDIR=/home/ignat/Quartus/Quartus_pro_21_4/quartus
	export PATH=$QUARTUS_ROOTDIR/bin:$QUARTUS_ROOTDIR/linux64:$QUARTUS_ROOTDIR/../qsys/bin:$PATH
else
	echo -e "\tQUARTUS dir not found, check is disk partion with QUARTUS mounted" | tee -a $home/log
	exit
fi

cd $TOP_FOLDER
a10_soc_devkit_ghrd_pro=a10_soc_devkit_ghrd_pro
if [ $(file $a10_soc_devkit_ghrd_pro | cut -d ":" -f 2-) == "directory" ]; then
	cd a10_soc_devkit_ghrd_pro
else
	echo -e "\t\ta10_soc_devkit_ghrd_pro direcitory doesn't exist, \n\tdo build manually"
	exit
fi
clear
cl_ean="n"
save="n"
name=""
compile="n"
gen_gsrd="n"
echo -e "\n\tОчистить проект? Будут удалены файлы .qsf .qpf .v и все, что касается u-boot?\n\t\t y/n" | tee -a $home/log
read cl_ean #| tee -a $home/log
echo "\t\t\t$cl_ean" >> $home/log
echo -e "\n\tГенерировать проект (<make generate_from_tcl> ~3 минуты)?\n\tБудут созданы файлы .qsf .qpf .v.\n\t\t y/n" | tee -a $home/log
read gen_gsrd #| tee -a $home/log
echo -e"\t\t\t$gen_gsrd" >> $home/log
#if [ $gen_gsrd != "n" ]; then
	echo -e "\n\tСохранить проект?\n y/n" | tee -a $home/log
	read save #| tee -a $home/log
	echo -e "\t\t\t$save" >> $home/log
	if [ $save != "n" ]; then
        	echo -e "\tИмя проекта ?:" | tee -a $home/log
        	read name #| tee -a $home/log
		echo -e "\t\t\t$name" >> $home/log
	fi
	echo -e "\n\tКомпилировать проект (<make rbf> ~10 минут)?\n\tБудут перезаписаны файлы в output_files и hps_isw_handoff.\n\t\ty/n" | tee -a $home/log
	read compile #| tee -a $home/log
	echo -e "\t\t\t$compile" >> $home/log
#fi
if [ $cl_ean != "n" ]; then
	if [ -d "./output_files" ]; then
		mv ./output_files ./.$(date "+%d-%m_%H_%M_%S_output_files")
		echo -e '\toutput_files сохранены как $(date "+%d-%m_%H_%M_%S_output_files")' | tee -a $home/log
	fi
	if [ -d "./hps_isw_handoff" ]; then
		mv ./hps_isw_handoff ./.$(date "+%d-%m_%H_%M_%S_hps_isw_handoff")
		echo -e '\thps_isw_handoff сохранены как $(date "+%d-%m_%H_%M_%S_hps_isw_handoff")' | tee -a $home/log
	fi
	echo -e "\n\n\n\\t\t\tОЧИСТКА ПРОЕКТА\n\t\t\tmake clean && make scrub_clean && rm -rf software" | tee -a $home/log
	make clean && make scrub_clean && rm -rf software | tee -a $home/log
	sleep 5
fi
title=$(date "+%d-%m_%H_%M_%S"_"$name")

	echo -e "что-то изменить после очистки? y/n"
 	read change_after_clean
	if [ $change_after_clean == "y" ]; then
		echo -e "продолжим? y/n"
		read go_after_clean
		if [ $go_after_clean == "y" ]; then
			echo "\t\t\t go!!!"
		fi
	fi

if [ $gen_gsrd != "n" ]; then
	clear
	echo "" > ../../gsrd_gen.log
	make generate_from_tcl > ../../gsrd_gen.log 2>&1 &
	while [ true ]; do
		echo -e "\n\t\t\tГЕНЕРАЦИЯ ПРОЕКТА согласно design_config.tcl, лог пишем в gsrd_gen.log\n\t\t\t<make generate_from_tcl>" | tee -a $home/log
		echo -e "\t\t\twait for pid $(pgrep -u ignat -l | grep quartus* | tail -1 | cut -d " " -f 1)" #| tee -a $home/log
		sleep 2
		clear
		if [ -n $(pgrep -u ignat -l | grep quartus* | tail -1 | cut -d " " -f 1) ]; then
			break
		fi
	done
	while [ true ]; do
		clear
		echo -e "\n\t\t\tГЕНЕРАЦИЯ ПРОЕКТА согласно design_config.tcl, лог пишем в gsrd_gen.log\n\t\t\t<make generate_from_tcl>" # | tee -a $home/log
		echo -e "\t\t\ttotal quartus pids : $(pgrep -u ignat -l | grep quartus* | wc -l)"
		echo -e "\t\t\tготово $(($(wc -l ../../gsrd_gen.log | cut -d " " -f 1)*100/920))%\n\t\t\t" # | tee -a $home/log
#		echo -e "\t\t\tpid $(pgrep -u ignat -l | grep quartus* | head -1 | cut -d " " -f 1)" #| tee -a $home/log
#		echo -e "\t\t\tpid $(pgrep -u ignat -l | grep quartus* | tail -1 | cut -d " " -f 1)" #| tee -a $home/log
		sleep 3
		clear
		if [ -z $(pgrep -u ignat -l | grep quartus* | tail -1 | cut -d " " -f 1) ]; then
			break
		fi
	done
	echo -e "\n\t\t\tГЕНЕРАЦИЯ ПРОЕКТА согласно design_config.tcl, лог пишем в gsrd_gen.log\n\t\t\t<make generate_from_tcl>"
	echo -e "\t\t\tготово 100%" | tee -a $home/log
	############### REPORT
	echo -e "\n\t\tмодифицированные файлы в $TOP_FOLDER/$a10_soc_devkit_ghrd_pro" | tee -a $home/log
	f_ar=()
	for f in $(find $TOP_FOLDER/$a10_soc_devkit_ghrd_pro -mmin -5); do
		if echo "${f_ar[@]}" | grep -qw "$f"; then
  			:
		else
			if [ -f $f ]; then
  				f_ar=("${f_ar[@]}" $f)
			fi
		fi
	done
	for el in "${f_ar[@]}"; do
		echo -e "$(basename "$el") \t$el" | tee -a $home/log
	done

	if [ $save != "n" ]; then
        	cd ../../ && mkdir $title && cd $title && echo -e "\t\tgenerated $title" > info_$title
        	for el in "${f_ar[@]}"; do
                	cp $el .
                	echo -e "$(basename "$el") \t\t$el" >> info_$title
        	done
        	echo -e "\n\t\t\tПроект сохранен как $(pwd)" | tee -a $home/log
	fi
fi

cd $TOP_FOLDER && cd $a10_soc_devkit_ghrd_pro
if [ $compile != "n" ]; then
	mac=$(ifconfig | grep ether | cut -d " " -f 10)
	if [ $mac != "90:2b:34:58:86:b0" ]; then
        	echo -e "\n\t\t\tнеобходиммо изменить MAC сетевой карты, команды:" | tee -a $home/log
		sudo ip link set dev enp2s0 down
		sudo ip link set dev enp2s0 address 90:2b:34:58:86:b0
		sudo ip link set dev enp2s0 up
		mac=$(ifconfig | grep ether | cut -d " " -f 10)
	fi
	q_chek=$(find . -maxdepth 1 -iname "*.q*" | wc -l)
#	if [ $q_chek -ge 4 ]; then
	if [ $q_chek -ge 3 ]; then # for ar_provi
		clear
		echo -e "\n\t\t\tУстановлен MAC = $mac" | tee -a $home/log
		echo -e "\n\t\t\tчто-то изменить после генерации? y/n"
 		read change_after_gen
		if [ $change_after_gen == "y" ]; then
			echo -e "продолжим? y/n"
			go_after_gen=""
			read go_after_gen
			if [ $go_after_gen == "y" ]; then
				echo "\t\t\t go!"
			fi
		fi


		sleep 3
		echo "" > ../../gsrd_build.log
		clear
		echo -e "\n\n\n\t\t\tСборка проекта, лог пишем в gsrd_build.log\n\t\t\t<make rbf>" | tee -a $home/log
		quartus_pids=$(pgrep -u $(whoami) -l | grep quartus* -c)
		make rbf > ../../gsrd_build.log 2>&1 &
		while [ true ]; do
			echo -e "\n\t\t\tСборка проекта , лог пишем в gsrd_build.log\n\t\t\t\<make rbf>"
			echo -e "\t\t\twait for pid $quartus_pids"
			sleep 2
			clear
			if [[ $(pgrep -u $(whoami) -l | grep quartus* -c) -gt $quartus_pids ]]; then
				break
			fi
		done
		while [ true ]; do
			clear
			# ls -al gsrd_build.log | cut -d " " -f 5 => 1051895
			echo -e "\n\t\t\tСборка проекта, лог пишем в gsrd_build.log\n\t\t\t<make rbf>"
			echo -e "\t\t\ttotal quartus pids :" $(pgrep -u $(whoami) -l | grep "quartus*" -c)
			if [ -f "../../gsrd_build.log" ]; then
				progress=$(cat ../../gsrd_build.log)
				echo -e "\t\t\tготово $(( ${#progress}*100/1060000 ))%"
				echo -e "\tlog tail <5> : $(cat ../../gsrd_gen.log | tail -5)"
			fi

			if [ $(pgrep -u $(whoami) -l | grep "quartus*" -c) == $quartus_pids ]; then
				if [ -f ./output_files/*core.rbf ]; then
					break
				fi
			fi
			sleep 3
		done
		echo -e "\n\t\t\tСборка проекта, лог пишем в gsrd_build.log\n\t\t\t<make rbf>"
		echo -e "\t\t\tготово 100%" | tee -a $home/log
		clear
		############# save build
		if [ ! -d "../../$title" ]; then
			mkdir ../../$title
		fi
		cp output_files ../../$title/output_files -r
		cp hps_isw_handoff ../../$title/hps_isw_handoff -r
	else
		echo -e "\n\n\n\t\t\tПроект <gsrd> невозможно собрать, т.к. он несгенерирован" | tee -a $home/log
		echo "q_chek = $q_chek" | tee -a $home/log
		sleep 10
	fi
fi
############# u_boot ################ Arria 10 SoC - Boot from SD Card
cd $TOP_FOLDER && cd $a10_soc_devkit_ghrd_pro
if [ ! -d "../../u-boot-socfpga" ]; then
	echo "\tнеобходимо установить u-boot toolchan, команды:" | tee -a $home/log
	cd ../../
	echo "\tgit clone https://github.com/altera-opensource/u-boot-socfpga"
	git clone https://github.com/altera-opensource/u-boot-socfpga
	echo "cd u-boot-socfpga"
	cd u-boot-socfpga
	echo -e "\n\tтекущая директория = $(pwd)"
echo "u-boot версия = $(git branch)"
#	echo "текущая директория = $(pwd)"
	sleep 5
fi
cd $TOP_FOLDER/$a10_soc_devkit_ghrd_pro
rm -rf software/bootloader && mkdir -p software/bootloader && cd software/bootloader
#echo -e "\n\tтекущая директория = $(pwd)"
cp ../../../../u-boot-socfpga . -r
cd u-boot-socfpga
echo -e "\n\t\tU-BOOT git версия = $(git branch)\n" | tee -a $home/log
#echo -e "текущая директория = $(pwd)"
hps_isw_handoff="hps_isw_handoff"
output_files="output_files"
if [ ! -f "../../../hps_isw_handoff/hps.xml" ]; then
	hps_isw_handoff=$(find $TOP_FOLDER/$a10_soc_devkit_ghrd_pro -maxdepth 1 -name ".*hps_isw_handoff" | sort | tail -1)
	cp -r $hps_isw_handoff ../../../hps_isw_handoff
else
	hps_isw_handoff="$TOP_FOLDER/$a10_soc_devkit_ghrd_pro/hps_isw_handoff/hps.xml"
fi
if [ ! -d "../../../output_files" ]; then
	output_files=$(find $TOP_FOLDER/$a10_soc_devkit_ghrd_pro -maxdepth 1 -name ".*output_files" | sort | tail -1)
	cp -r $output_files ../../../output_files
else
	output_files="$TOP_FOLDER/$a10_soc_devkit_ghrd_pro/output_files"
fi
echo -e "\n\tu-boot будет использовать сборку из :\n$hps_isw_handoff \n$output_files"| tee -a $home/log

./arch/arm/mach-socfpga/qts-filter-a10.sh \
../../../hps_isw_handoff/hps.xml \
arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h
echo -e "\n\t\tпроверка\nfile $(file arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h)\n"  | tee -a $home/log
sleep 5
clear
export CROSS_COMPILE=arm-none-linux-gnueabihf-
#echo -e "т\n\t\tтекущая директория = \n$(pwd)"
#echo -e "\n\t\t\t U-BOOT конфигурация, лог пишем в u-boot.log"
#sleep 3
################### u-boot configure
echo "" > ../../../../../u-boot.log
make socfpga_arria10_defconfig | tee ../../../../../u-boot.log
#make socfpga_arria10_defconfig  > ../../../../../u-boot.log 2>&1
#cicle=0
################### u-boot compile
sleep 3
#make -j ${nproc} | tee ../../../../../u-boot.log
make -j ${nproc}  > ../../../../../u-boot.log 2>&1 &
while [ $(($(wc -l ../../../../../u-boot.log | cut -d " " -f 1)*100/871)) -lt 100 ]; do
	clear
	echo -e "\n\t\t\tU-BOOT сборка, лог пишем в u-boot.log"
	echo -e "\t\t\tготово $(($(wc -l ../../../../../u-boot.log | cut -d " " -f 1)*100/871))%"
	sleep .5
done
clear
rm -rf ghrd_10as066n2.core.rbf
ln -s ../../../output_files/ghrd_10as066n2.core.rbf .
rm -rf ghrd_10as066n2.periph.rbf
ln -s ../../../output_files/ghrd_10as066n2.periph.rbf .
tools/mkimage -E -f board/altera/arria10-socdk/fit_spl_fpga.its fit_spl_fpga.itb

build=false
if [ -f ./fit_spl_fpga.itb ]; then
	build=true
	echo -e "\n\n\t\t\tУСПЕШНО !!!\n"  | tee -a $home/log
	echo -e "\n\t\tu-boot использовал файлы из \n$hps_isw_handoff \n$output_files"  | tee -a $home/log
	echo -e "\n\tПроверка \n$(file ./fit_spl_fpga.itb)"  | tee -a $home/log
else
	echo -e "\n\n\t\t\tУВЫ...\n" | tee -a $home/log
fi
if $build; then
	echo -e "\n\t\t\tSD card write"  | tee -a $home/log
	echo -e "\n\tтекущая директория = $(pwd)"
#	TOP_FOLDER=/media/ignat/sda-7/rocket_boards_a10/a10_example.sdmmc
#	текущая директория =
#	/media/ignat/sda-7/rocket_boards_a10/a10_example.sdmmc/a10_soc_devkit_ghrd_pro/software/bootloader/u-boot-socfpga
	cd $TOP_FOLDER/..
	title_sd=$title
	title_sd+="_sd_card"
	rm -rf $title_sd && mkdir $title_sd && cd $title_sd
	path_sd_card=$(pwd)
	mkdir sdfs &&  cd sdfs
	cp ~/mac_styhead_sda-7/images_arria10/zImage .
	cp ~/mac_styhead_sda-7/images_arria10/socfpga_arria10_socdk_sdmmc-arria10.dtb .
	cp $TOP_FOLDER/a10_soc_devkit_ghrd_pro/software/bootloader/u-boot-socfpga/fit_spl_fpga.itb .
	cp $TOP_FOLDER/a10_soc_devkit_ghrd_pro/software/bootloader/u-boot-socfpga/u-boot.img .
	mkdir extlinux
	echo "LABEL Arria10 SOCDK SDMMC" > extlinux/extlinux.conf
	echo "    KERNEL ../zImage" >> extlinux/extlinux.conf
	echo "    FDT ../socfpga_arria10_socdk_sdmmc.dtb" >> extlinux/extlinux.conf
	echo "    APPEND root=/dev/mmcblk0p2 rw rootwait earlyprintk console=ttyS0,115200n8" >> extlinux/extlinux.conf
	cd ..
	mkdir rootfs && cd rootfs
	tar xf ~/mac_styhead_sda-7/images_arria10/core-image-minimal-arria10.rootfs-20251008080119.tar.gz
	rm -rf lib/modules/*
	cd $path_sd_card
	cp $TOP_FOLDER/a10_soc_devkit_ghrd_pro/software/bootloader/u-boot-socfpga/spl/u-boot-splx4.sfp .

	########################### make img
	cd $path_sd_card
	sudo python3 ../make_sdimage_p3.py -f \
	-P u-boot-splx4.sfp,num=3,format=raw,size=10M,type=A2  \
	-P sdfs/*,num=1,format=fat32,size=32M \
	-P rootfs/*,num=2,format=ext3,size=132M \
	-s 600M \
	-n sdcard_a10.img
fi
if [[ -n $(file sdcard_a10.img | grep -c "partition 1") && \
	-n $(file sdcard_a10.img | grep -c "partition 2") && \
	-n $(file sdcard_a10.img | grep -c "partition 3") ]]; then
	echo -e "\n\t\t\tPath to sd_card image: \n\t\t\\t$path_sd_card/sdcard_a10.img\n"
fi
