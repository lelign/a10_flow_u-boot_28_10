#!/bin/bash
############# u_boot ################ Arria 10 SoC - Boot from SD Card
home=$('pwd')
title=$(date "+%d-%B_%H_%M_%S_ask")
rm -rf $home/log
#########################################################################
###################### Quartus project choice ###########################
#########################################################################
possible_path=()
for q in $(lsblk --pairs | grep 'RM="0"' | grep -v 'MOUNTPOINTS=""' | grep -v loop | grep -v "/boot/efi" | cut -d '"' -f 14); do
if [ $q == "/" ]; then
	this_path="/home/$(whoami)"
else
	this_path="$q"
fi
if [[ (-d "$this_path") && ("$this_path" != *"old_"*) && ("$this_path" != *"lost+found") ]]; then
	cd $this_path
	for file in $(find ./ -maxdepth 5 -type f -name 'hps.xml'); do
		if [[ -f $file ]]; then
			hps_isw_handoff=$(basename $(dirname $file))
			project_name=$(basename $(dirname $(dirname $file)))
			project_path=$(realpath $(dirname $(dirname $file)))
			output_files=$(realpath "$project_path/output_files")
			if [ -d $output_files ]; then
				sof=$(find $output_files -maxdepth 1 -type f -name "*.sof")
				if [ -f $sof ]; then
						possible_path+=("$project_name $project_path")
				fi
			fi
		fi
	done
fi
done
 
count=0
echo -e "Выберите проект (ввести номер)"
printf "\t%-3s | %-50s | %-50s\n" "№  " "   имя проекта   " "дата создания"
for el in "${possible_path[@]}"; do
	name_pr=$(echo $el | cut -d " " -f 1)
	date_pr=$(date -r $(echo $el | cut -d " " -f 2) +"%m-%d %H:%M:%S")
	#echo -e "$count\t$el"
	printf "\t%-3s | %-50s | %-10s\n" "$count" "$name_pr" "$date_pr"
	((count+=1))
done
#echo -e "\n\tНомер проекта ?"
read -p "Номер проекта: " pr_num
#if  [[ "$pr_num" =~ ^[0-"$count"]+$ ]]; then
if  [[ "$pr_num" =~ ^[0-9]+$ && $pr_num -le $count ]]; then
	project="${possible_path[$pr_num]}"
	name_pr=$(echo $project | cut -d " " -f 1)
	echo -e "\n\tвыбран $pr_num\t$name_pr\n\t$project"
	project=$(echo $project | cut -d " " -f 2)
else
	echo -e "\n\tError : ошибка выбора проекта $pr_num <= ??? \n\texit..."
	exit
fi


########## check compiler u-boot
cd $home
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

u_boot_ver="u_boot_ver"
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
cp $(realpath $home/$u_boot_ver) u-boot-socfpga -r
cd u-boot-socfpga
u_boot_dir=`pwd`
#echo -e "\n\t2 текущая директория = $(pwd)"
echo -e "\n\t\tU-BOOT git версия = $(git branch)\n" | tee -a $home/log
info="U-BOOT git версия = $(git branch)"
#echo -e "???  /home/$(whoami)/Quartus_projects/AR_PROV1_2_compiled_with_some_changes/hps_isw_handoff" 
#echo
#echo -e "\n\t\tEnter full path to directory hps_isw_handoff"
#read gsrd_hps_isw_handoff
#hps_isw_handoff_dir="/home/$(whoami)/Quartus_projects/AR_PROV1_2_compiled_with_some_changes/hps_isw_handoff"

############################################################################################################
############################### qts-filter-a10.sh ##########################################################
############################################################################################################
#if [ -s $gsrd_hps_isw_handoff ]; then
#	echo "link"
#	hps_isw_handoff_dir=$(realpath $gsrd_hps_isw_handoff)
#fi
echo "project=$project"
hps_isw_handoff_dir="$project/hps_isw_handoff"
if [[ -d "$hps_isw_handoff_dir" && -f "$hps_isw_handoff_dir/hps.xml" ]]; then
	rm -rf hps_xml_link
	ln -s $hps_isw_handoff_dir/hps.xml hps_xml_link
	./arch/arm/mach-socfpga/qts-filter-a10.sh hps_xml_link	./arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h
    re_recorded=$(date -r ./arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h  +"%B-%d %H:%M:%S")	
    recorded_hps_xml=$(date -r $(realpath hps_xml_link)  +"%B-%d %H:%M:%S")
    echo -e "Проверка\n\tИсподьзован hps.xml из $hps_isw_handoff_dir создан $recorded_hps_xml " | tee -a $home/log
    echo -e "\t$(file arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h) re-recorded at $re_recorded" | tee -a $home/log
    handoff_h=$(realpath arch/arm/dts/socfpga_arria10_socdk_sdmmc_handoff.h)
else
	echo -e "\n\tError : directory hps_isw_handoff on path $hps_isw_handoff not found !"
	echo -e "\texit ..."
	exit
fi


sleep 5
clear
export CROSS_COMPILE=arm-none-linux-gnueabihf-

echo "" > $home/u-boot.log
#echo "pwd=$(pwd)"
##################################################################################
############## u-boot config choice ##############################################
##################################################################################
me_co_ar=()
#unset make_task
unset choice
if [ ! -d "$home/menu_config" ]; then 
	echo -e "\n\tНет доступных конфигураций для u-boot!"
	echo -e "\n\tБудет сгенерирована конфигурация <default> для u-boot!"
	echo -e "\n\t<make socfpga_arria10_defconfig>"
	sleep 1
	
	make socfpga_arria10_defconfig
	if [ -f "$(pwd)/.config" ]; then
		mkdir $home/menu_config
		cp $(pwd)/.config $home/menu_config/.config_default
		rm $(pwd)/.config
		ln -s $home/menu_config/.config_default $(pwd)/.config
	else
		echo -e "/n/tError: Что-то не так, отсутсвует файл .config после выполнения <make socfpga_arria10_defconfig>"
	fi
fi
if [[ -d "$home/menu_config" && $(find $home/menu_config -iname ".config_*" | wc -l) -gt 0 ]]; then
	#echo found
	echo -e "\n\tВариант конфигурации u-boot (ввести номер)"
	printf "\t%-3s | %-50s | %-10s\n" "№  " "конфигурация" "дата создания"
	count=0
	#echo -e "\t$count\tcreate default <make socfpga_arria10_defconfig>"
	#me_co_ar+=("default")
	#((count+=1))
	#echo -e "\t$count\tcreate new <make menuconfig>"
	#me_co_ar+=("create_new_config")
	for f_c in $(find $home/menu_config -type f); do		
		me_co_ar+=("$f_c")
		printf "\t%-3s | %-50s | %-10s\n" "$count" "$(basename $f_c)" "$(date -r $f_c +"%m-%d %H:%M:%S")"
		#echo -e "\t$count\tиспользовать $(basename $f_c)\t\t\t\tот $(date -r $f_c +"%m-%d %H:%M:%S")"
		((count+=1))
	done
	#echo -e "\n\tНомер конфигурации ?"
	read -p "Номер конфигурации: " num
	#if [ $num == 0 ]; then
	#	make_task="socfpga_arria10_defconfig"
	#elif [ $num == 1 ]; then
	#	make_task="menuconfig"
	#elif  [[ ("$num" =~ ^[0-9]+$) && "$num" -le "$count" && "$num" -gt 1 ]]; then
	if  [[ ("$num" =~ ^[0-9]+$) && "$num" -le "$count" ]]; then
		echo -e "\n\tвыбран номер $num\tконфигурация $(basename ${me_co_ar[$num]})"
		#unset make_task
		choice="${me_co_ar[$num]}"
	elif  [[ ! "$num" =~ ^[0-9]+$ || "$num" -gt "$count" ]]; then # [[ "$my_var" =~ ^[0-9]+$ ]]
		#echo "count=$count"
		echo -e "\n\tError : ошибка выбора варианта конфигурации $num <= ??? \n\texit..."
		exit
	fi
		
fi
#echo -e "\tВыбрана конфигурация : $choice"
#cp $choice .config
#echo -e "\n\tИзменить конфигурацию <make menuconfig> для $(basename $choice) ? (y/n)"
read -p "Изменить конфигурацию <make menuconfig> для $(basename $choice) ? (y/n)" change_config
if [ "$change_config" == "y" ]; then
###################### process to cp config
	while true; do
	for f in $(file $(find ./ -maxdepth 1 -type f ) | grep "ASCII text" | grep -v "with very long lines" | grep -v ".old" | cut -d ":" -f 1); do 
		if [[ "$(cat $f | head -3)" == *"U-Boot"*"Configuration"* ]]; then
			if [[ ! -f "$home/$(basename $f)" ]]; then
				cp $(basename $f) "$home/menu_config"
				rm -rf $(pwd)/.config
				ln -s $home/menu_config/$(basename $f) $(pwd)/.config
			fi
		fi
	done
	sleep .2
	done &
	pid_process=$!

	rm -rf $(pwd).config
	ln -s $choice $(pwd)/.config
	make menuconfig
	sleep .4
	kill $pid_process

	#if [ ! -f "$(pwd)/.config" ]; then
	#	echo -e "\n\tError : file $(pwd)/.config doesn't exist!\n\tContinue ? (any key)"
	#	read continue
	#fi
	#cp $(pwd)/.config $choice
else
	rm -rf .config
	ln -s $choice $(pwd)/.config
fi
if [ ! -s "$(pwd)/.config" ]; then
	#echo -e "\n\tError :file $(pwd)/.config doesn't exist\n\tContinue ? (any key)"
	read -p "Error :file $(pwd)/.config doesn't exist, continue ? (any key) " continue
fi
echo $(file $(pwd)/.config)
sleep 3



############################################################################################################
############################ make socfpga_arria10_defconfig  ###############################################
############################################################################################################
# if [ -n "$make_task" ]; then echo -e "Continue make $make_task? (hit any key)" read continue if [ "$make_task" == "menuconfig" ]; then clear echo -e "\n\tПеред изменением конфигурации сначала обязательно загрузить валидную конфигурацию\n\tиначе сборка будет невозможна!!!" echo -e "\n\tскопируйте полный путь к валидной конфигурации для последующей загрузки" echo -e "\tновую конфигурацию сохраняйте в той же директории, откуда брали валидную\n" for f in $(find $home/menu_config -maxdepth 1 -type f); do echo -e "\t\t$(realpath $f)" done echo -e "\n\tобязательно сделайте терминал большого размера\n" echo -e "Continue ? (any key)" read continue make $make_task fi if [ ! -d "$home/menu_config" ]; then mkdir $home/menu_config fi cp $(find $home/menu_config -iname ".config*" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d " " -f 2 ) .config if [ ! -f ".config" ]; then echo -e "PROBLEM!! file .config not found!!!" echo -e "Continue ? (any key)" read continue #make $make_task fi #cp $(find . -iname ".config*" -mmin 1) .config fi

#if [ -n "$choice" ]; then #echo -e "Continue cp $choice .config? (hit any key)" read continue cp $choice .config make menuconfig if [ ! -f "$(pwd)/.config" ]; then echo -e "\n\tError : file $(pwd)/.config doesn't exist!\n\tContinue ? (any key)" read continue fi cp .config $choice fi
#if [[ -z "$make_task" && -z "$choice" ]]; then echo -e "\n\tкакая-то херня, не может быть такого\n\t exit ..." exit fi
#reassign choice
#choice=$(realpath .config)
#	ln -s $menu_config .config
#	echo -e "\n\tБудет использована конфигурация $(basename $menu_config)" | tee -a $home/log
#else
#	echo -e "\n\tБудет использована конфигурация default" | tee -a $home/log
#	make socfpga_arria10_defconfig | tee $home/u-boot.log
#fi
 
#make socfpga_arria10_defconfig | tee $home/u-boot.log
#diff /media/ignat/sda-7/macnica_styhead/a10_flow_u-boot_28_10/menu_config/.config_default .config

#cp /media/ignat/sda-7/macnica_styhead/a10_flow_u-boot_28_10/menu_config/.config_add_fpga_reprogramming .config


############################################################################################################
############################ make -j ${nproc}     ##########################################################
############################################################################################################

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
#echo -e "??? /home/$(whoami)/temp_output_quartus"
#if [ ! -d $(dirname $hps_isw_handoff_dir)/output_files ]; then
#	echo -e "\n\t\tEnter full path to directory <output_files>"
#	read output_files
#	if [ -s $output_files ]; then
#		output_files=$(realpath $output_files)
#	fi
#else
#	output_files=$(dirname $hps_isw_handoff_dir)/output_files
#fi

if [ -d "$project/output_files" ]; then
#    sof_file=$(find $(realpath $output_files) -maxdepth 1 -type f -name *.sof)
	sof_file=$(find "$project/output_files" -maxdepth 1 -type f -name *.sof)
	quartus=$(find /home/$(whoami) -maxdepth 3 -type d -name "quartus")
	if [ ! -d "$quartus" ]; then
		quartus=$(find /home/$(whoami)/Quartus/ -maxdepth 3 -type d -name "quartus" | grep "Quartus_pro_21_4/quartus")
		if [ ! -d "$quartus" ]; then
			echo -e "Quartus not found!!!"
			exit
		fi
	fi 
    quartus_cpf=$quartus/bin/quartus_cpf
    if [[ -f $sof_file && -f $quartus_cpf ]]; then
        flags="-c --hps -o bitstream_compression=on "
        output_rbf=$title
	    output_rbf+=".rbf"
        output_rbf=$output_files/$output_rbf
#####################################################################################################
########################### convert sof to core $ periph .rbf #######################################
#####################################################################################################
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

    echo -e "\n\t\tstart tools/mkimage\n"    
    echo $title > $home/fit_log
    tools/mkimage -E -f board/altera/arria10-socdk/fit_spl_fpga.its fit_spl_fpga.itb | tee -a $home/fit_log
    fit_spl_fpga_itb=$(realpath ./fit_spl_fpga.itb)
    date_fit_spl_fpga_itb=$(date -r $fit_spl_fpga_itb  +"%B-%d %H:%M:%S")
	fit_spl_fpga_itb_prf=$(file u-boot/fit_spl_fpga.itb | cut -d ":" -f 2)
    echo -e "\n\tfit_spl_fpga.itb <= $fit_spl_fpga_itb_prf \n\t$date_fit_spl_fpga_itb" | tee -a $home/log
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

	echo -e "\tu-boot использовал файлы из:" | tee -a $home/log
    date_sof_file=$(date -r $sof_file  +"%B-%d %H:%M:%S")
    echo -e "\t\t.sof = $(dirname $sof_file) $date_sof_file" | tee -a $home/log
    echo -e "\t\thps.xml = $(dirname $hps_isw_handoff_dir/hps.xml) $recorded_hps_xml" | tee -a $home/log
    #echo -e "Проверка \n\t$(file ./fit_spl_fpga.itb)\t"$(date -r ./fit_spl_fpga.itb  +"%B-%d %H:%M:%S") | tee -a $home/log
else
	echo -e "\n\n\t\t\tУВЫ...\n" | tee -a $home/log
	exit
fi


#################################################################################################
######################### generate SD CARD IMAGE ################################################

unset path_sd_card_image
if $build; then
	echo -e "\n\t\t\tmake image for SD card\n"  | tee -a $home/log
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
	cp $choice $(pwd)
	echo -e "\n\tPath to sd_card image: \n\t$path_sd_card/$title.img\n" | tee -a $home/log
	unset path_sd_card_image
	path_sd_card_image=$path_sd_card/$title.img
fi

#echo -e "\n\tПишем образ на SD карту? y/n"
read -p "Пишем образ на SD карту? y/n " continue
if [ $continue == "y" ]; then
	if [ -z $path_sd_card_image ]; then
		#echo -e "\n\tEnter full path to sd card image"
		read -p "Enter full path to sd card image" path_sd_card_image
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
			#echo -e "\n\tПишем на /dev/$device? y/n"
			read -p "Пишем на /dev/$device? y/n " do_it
			
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
					for f in $(find ./tmp_dir/home/root -maxdepth 1 -type f); do
					echo -e "\t\t$(basename $f)"
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
