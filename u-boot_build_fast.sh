#!/bin/bash
############# u_boot ################ Arria 10 SoC - Boot from SD Card
#some changes 01_11
home=$('pwd')
title=$(date "+%d-%B_%H_%M_%S_fast")
rm -rf $home/log
########## check compiler
compiler="./gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf"
if [ ! -d $compiler ]; then
	echo -e "\n\tнеобходимо установить компайлер, команды:" | tee -a $home/log
	echo -e "wget https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz"
	wget https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz
	echo -e "tar xf gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz"
	tar xf gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz
	echo -e "rm gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz"
fi
if [ -d "./gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin" ]; then
	export PATH=`pwd`/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin:$PATH
else
	echo -e "\n\t\t\INSTALL COMPILER !!!\n" | tee -a $home/log
	exit
fi

a10_example_sdmmc=$('pwd')/a10_example.sdmmc

if [ -d $a10_example_sdmmc ]; then
	cd $a10_example_sdmmc
	TOP_FOLDER=`pwd`
#	echo -e "\t\tTOP_FOLDER=$TOP_FOLDER" | tee -a $home/log
else
	echo -e "\t$a10_example_sdmmc direcitory doesn't exist, \n\tdo build manually" | tee -a $home/log
	exit
fi

a10_soc_devkit_ghrd_pro="a10_soc_devkit_ghrd_pro"
cd $TOP_FOLDER && cd $a10_soc_devkit_ghrd_pro
gsrd_dir=`pwd`

u_boot_ver="u-boot-socfpga_v2025.07"
if [ ! -d $home/$u_boot_ver ]; then
#if [ ! -d "../../u-boot-socfpga" ]; then
	echo "\tнеобходимо установить u-boot toolchan, команды:" | tee -a $home/log
	cd ../../
	echo -e "\tgit clone https://github.com/altera-opensource/u-boot-socfpga"
	git clone https://github.com/altera-opensource/u-boot-socfpga
	echo "cd u-boot-socfpga"
	cd u-boot-socfpga
	echo -e "\n\tтекущая директория = $(pwd)"
	echo -e "u-boot версия = $(git branch)"
	sleep 5
fi

cd $TOP_FOLDER/$a10_soc_devkit_ghrd_pro
rm -rf software/bootloader && mkdir -p software/bootloader && cd software/bootloader
#echo -e "\n\t1 текущая директория = $(pwd)"
cp $home/$u_boot_ver u-boot-socfpga -r
cd u-boot-socfpga
u_boot_dir=`pwd`
#echo -e "\n\t2 текущая директория = $(pwd)"
echo -e "\n\t\tU-BOOT git версия = $(git branch)\n" | tee -a $home/log
info="U-BOOT git версия = $(git branch)"
### for fast only
if [ -f "$home/.fast_uboot_input_files" ]; then
	hps_isw_handoff_dir=$(cat $home/.fast_uboot_input_files | head -1)
	output_files=$(cat $home/.fast_uboot_input_files | tail -1) 
else
	echo -e "\n\t\tEnter full path to directory hps_isw_handoff"
	read hps_isw_handoff_dir
	echo $hps_isw_handoff_dir > $home/.fast_uboot_input_files
	echo -e "\n\t\tEnter full path to directory <output_files>"
	read output_files
	echo $output_files >> $home/.fast_uboot_input_files
fi

echo -e "\n\thps_isw_handoff_dir => $hps_isw_handoff_dir"
echo -e "\toutput_files => $output_files"
echo ""


#echo -e "???  /home/$(whoami)/Quartus_projects/AR_PROV1_2_compiled_with_some_changes/hps_isw_handoff" 
#echo -e "\n\t\tEnter full path to directory hps_isw_handoff"
#read hps_isw_handoff_dir
#hps_isw_handoff_dir="/home/$(whoami)/Quartus_projects/AR_PROV1_2_compiled_with_some_changes/hps_isw_handoff"
if [[ -d $hps_isw_handoff_dir && -f $hps_isw_handoff_dir/hps.xml ]]; then
	rm -rf hps_xml_link
	ln -s $hps_isw_handoff_dir/hps.xml hps_xml_link
	./arch/arm/mach-socfpga/qts-filter-a10.sh hps_xml_link	./arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h
    re_recorded=$(date -r ./arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h  +"%B-%d %H:%M:%S")	
    recorded_hps_xml=$(date -r $(realpath hps_xml_link)  +"%B-%d %H:%M:%S")
    echo -e "Проверка\n\tИсподьзован hps.xml из $hps_isw_handoff_dir создан $recorded_hps_xml " | tee -a $home/log
    echo -e "\t$(file arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h) re-recorded at $re_recorded" | tee -a $home/log
    handoff_h=$(realpath arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h)
else
	rm -rf $home/.fast_uboot_input_files
	echo -e "Error : directory hps_isw_handoff on path $hps_isw_handoff_dir not found !\nпросто запусти скрипт еще раз и введи правильный путь"
	exit
fi


sleep 5
clear
export CROSS_COMPILE=arm-none-linux-gnueabihf-

echo "" > $home/u-boot.log
make socfpga_arria10_defconfig | tee $home/u-boot.log

################### u-boot compile
sleep 3

make -j ${nproc}  > $home/u-boot.log 2>&1 &
while [ $(($(wc -l $home/u-boot.log | cut -d " " -f 1)*100/871)) -lt 100 ]; do
	clear
	echo -e "\n\t\t\tU-BOOT сборка, лог пишем в u-boot.log"
	echo -e "\t\t\tготово $(($(wc -l $home/u-boot.log | cut -d " " -f 1)*100/871))%"
	if [[ $(ls | grep -c u-boot) -gt 6 ]]; then
		sleep 1
		break
	fi
	sleep .5
done
clear
echo -e "\n\t\t\tU-BOOT собран, лог записан u-boot.log"

#if [[ -f $gsrd_dir/output_files/ghrd_10as066n2.core.rbf  && -f $gsrd_dir/output_files/ghrd_10as066n2.periph.rbf ]]; then
#	ln -s $gsrd_dir/output_files/ghrd_10as066n2.core.rbf .
#	ln -s $gsrd_dir/output_files/ghrd_10as066n2.periph.rbf .
#else
#	echo -e "error : files ghrd_10as066n2.core.rbf or ghrd_10as066n2.periph.rbf not found in path $gsrd_dir" | tee -a $home/log
#	exit
#fi

#tools/mkimage -E -f board/altera/arria10-socdk/fit_spl_fpga.its fit_spl_fpga.itb
#fit_spl_fpga_itb=$(realpath ./fit_spl_fpga.itb)
#date_fit_spl_fpga_itb=$(date -r $fit_spl_fpga_itb  +"%B-%d %H:%M:%S")
#echo -e "\t$fit_spl_fpga_itb \t$date_fit_spl_fpga_itb" | tee -a $home/log


####################################################################
################ generate fit_spl_fpga.itb #########################
####################################################################
echo -e "??? /home/$(whoami)/temp_output_quartus"
#echo -e "\n\t\tEnter full path to directory <output_files>"
#read output_files
#output_files="/home/$(whoami)/temp_output_quartus"
if [ -d $output_files ]; then
    sof_file=$(find $output_files -maxdepth 1 -type f -name *.sof)
	quartus=$(find /home/$(whoami) -maxdepth 3 -type d -name "quartus")
	if [ ! -d "$quartus" ]; then
		quartus=$(find /home/$(whoami)/Quartus/ -maxdepth 3 -type d -name "quartus" | grep "Quartus_pro_21_4/quartus")
		if [ ! -d "$quartus" ]; then
			echo -e "Quartus not found!!!"
			exit
		fi
	fi  
	quartus_cpf=$quartus/bin/quartus_cpf
    #quartus_cpf="/home/$(whoami)/Quartus/Quartus_pro_21_4/quartus/bin/quartus_cpf"
    if [[ -f $sof_file && -f $quartus_cpf ]]; then
        flags="-c --hps -o bitstream_compression=on "
        output_rbf=$title
	    output_rbf+=".rbf"
        output_rbf=$output_files/$output_rbf
        ############ convert sof to core $ periph .rbf
        $quartus_cpf $flags $sof_file $output_rbf
    else
        echo -e "Error : quartus_cpf on path $quartus_cpf not found or file  .sof doesn't exist in $output_files!"
	    exit
    fi
else
	echo -e "Error : directory output_files on path $output_files not found or file  .sof doesn't exist in it!"
	exit
fi
#### check core && periph && ln them
core=$title
core+=".core.rbf"
periph=$title
periph+=".periph.rbf"
if [[ -f $output_files/$core &&  -f $output_files/$periph ]]; then
    #cd ../../../output_files
    rm -rf ghrd_10as066n2.core.rbf
    rm -rf ghrd_10as066n2.periph.rbf
    #cd $u_boot_dir
    #echo -e "now here :$(pwd)"

    ln -s $output_files/$core ghrd_10as066n2.core.rbf
    ln -s $output_files/$periph ghrd_10as066n2.periph.rbf

    echo -e "\n\t\\ttart tools/mkimage\n"    
    
    tools/mkimage -E -f board/altera/arria10-socdk/fit_spl_fpga.its fit_spl_fpga.itb | tee -a $home/fit_log
    fit_spl_fpga_itb=$(realpath ./fit_spl_fpga.itb)
    date_fit_spl_fpga_itb=$(date -r $fit_spl_fpga_itb  +"%B-%d %H:%M:%S")
    echo -e "\n\t$(file $fit_spl_fpga_itb) \n\t$date_fit_spl_fpga_itb" | tee -a $home/log
else
    echo -e "Error : file $core or file $periph on path $output_files not found !"
fi



build=false
if [[ -f ./fit_spl_fpga.itb && -f ./u-boot.img ]]; then
	build=true
	echo -e "\n\n\t\t\tУСПЕШНО !!!\n"  | tee -a $home/log
	u_boot_img=$(find $(pwd) -maxdepth 1 -type f -name "u-boot.img") # ok full path
	u_boot_spl=$(find $(pwd) -maxdepth 2 -type f -name "u-boot-splx4.sfp") # ok full path
	#echo "u_boot_img = $u_boot_img u_boot_spl = $u_boot_spl" 

	echo -e "u-boot использовал файлы из:" | tee -a $home/log
    date_sof_file=$(date -r $sof_file  +"%B-%d %H:%M:%S")
    echo -e "\t\t.sof = $sof_file $date_sof_file" | tee -a $home/log
    echo -e "\t\thps.xml = $hps_isw_handoff_dir/hps.xml $recorded_hps_xml" | tee -a $home/log
    echo -e "Проверка \n\t$(file ./fit_spl_fpga.itb)\t"$(date -r ./fit_spl_fpga.itb  +"%B-%d %H:%M:%S") | tee -a $home/log
else
	echo -e "\n\n\t\t\tУВЫ...\n" | tee -a $home/log
fi


#################################################################################################
######################### generate SD CARD IMAGE ################################################

unset path_sd_card_image
if $build; then
	echo -e "\n\t\t\tmake image for SD card"  | tee -a $home/log
	u_boot_dir=$`pwd`


	tar_root=$(find $home/core_and_root -maxdepth 1 -type f -name "*rootfs.tar.gz")
	linux_kernel=$(find $home/core_and_root -maxdepth 1 -type f -name "zImage*.bin")
	file_dtb=$(find $home/core_and_root -maxdepth 1 -type f -name "*.dtb")
	if [[ ! -f $tar_root || ! -f $linux_kernel || ! -f $file_dtb ]]; then
		echo -e "\n\terror : some files <root.tar.gz> or <zImage.bin> or <.dtb> not found in path $home/core_and_root !!!" | tee -a $home/log
		echo -e "\t\t\ttar_root $tar_root" | tee -a $home/log
		echo -e "\t\t\tlinux_kernel $linux_kernel" | tee -a $home/log
		echo -e "\t\t\tfile_dtb $file_dtb" | tee -a $home/log
		exit
	fi
	if [ ! -d $home/sd_card_images ]; then
		mkdir $home/sd_card_images
	fi
	cd $home/sd_card_images
	#title_sd=$title
	#title_sd+="_sd_card"
	rm -rf $title && mkdir $title && cd $title
	path_sd_card=$(pwd)
	mkdir sdfs &&  cd sdfs
	
	cp $linux_kernel $(pwd)/zImage
	cp $file_dtb $(pwd)/socfpga_arria10_socdk_sdmmc.dtb
	cp $u_boot_img $(pwd)/u-boot.img
	cp $fit_spl_fpga_itb $(pwd)/fit_spl_fpga.itb

    cp $home/log $(pwd)/build_log.txt
 
	mkdir extlinux
	echo "LABEL Arria10 SOCDK SDMMC" > extlinux/extlinux.conf
	echo "    KERNEL ../zImage" >> extlinux/extlinux.conf
	echo "    FDT ../socfpga_arria10_socdk_sdmmc.dtb" >> extlinux/extlinux.conf
	echo "    APPEND root=/dev/mmcblk0p2 rw rootwait earlyprintk console=ttyS0,115200n8" >> extlinux/extlinux.conf
	cd ..
	mkdir rootfs && cd rootfs
	tar xf $tar_root
	rm -rf lib/modules/zImage

	cd $path_sd_card
	cp $u_boot_spl $(pwd)

	########################### make img
    # for raw 1M enough
    # for sdfs 32 M
    # for rootfs 130M
    # total 1+32+132=164M
	cd $path_sd_card
	sudo python3 $home/make_sdimage_p3.py -f \
	-P $u_boot_spl,num=3,format=raw,size=1M,type=A2  \
	-P sdfs/*,num=1,format=fat32,size=32M \
	-P rootfs/*,num=2,format=ext3,size=172M \
	-s 210M \
    -n $title.img
	#-n sdcard_a10.img
fi
unset path_sd_card_image
if [[ -n $(file $title.img | grep -c "partition 1") && \
	-n $(file $title_a10.img | grep -c "partition 2") && \
	-n $(file $title.img | grep -c "partition 3") ]]; then
	mkdir used_files && cd used_files
	cp $sof_file $(pwd)
	cp $u_boot_spl $(pwd)
	cp $hps_isw_handoff_dir/hps.xml $(pwd)
	cp $home/log $(pwd)
	cp $handoff_h $(pwd)
	cp $fit_spl_fpga_itb $(pwd)
	echo -e "Path to sd_card image: \n\t$path_sd_card/$title.img\n" | tee -a $home/log
	unset path_sd_card_image
	path_sd_card_image=$path_sd_card/$title.img
fi

echo -e "\n\tПишем образ на SD карту? y/n"
read continue
if [ $continue == "y" ]; then
	if [ -z $path_sd_card_image ]; then
		echo -e "\n\tEnter full path to sd card image"
		read path_sd_card_image
	fi
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
