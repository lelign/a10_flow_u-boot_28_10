#!/bin/bash
home=$('pwd')
rm -rf $home/log


########## check compiler
compiler="/media/ignat/sda-7/macnica_styhead/a10_flow_u-boot_28_10/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf"
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
	echo -e "PATH=$PATH"
else
	echo -e "\n\t\t\INSTALL COMPILER !!!\n" | tee -a $home/log
	exit
fi

a10_example_sdmmc=$('pwd')/a10_example.sdmmc
if [ -d $a10_example_sdmmc ]; then
	cd $a10_example_sdmmc
	TOP_FOLDER=`pwd`
	echo -e "\t\tTOP_FOLDER=$TOP_FOLDER" | tee -a $home/log
else
	echo -e "\t$a10_example_sdmmc direcitory doesn't exist, \n\tdo build manually" | tee -a $home/log
	exit
fi

############### find Quartus
except=("old_yocto" "lost+found" "windows" "old_ubuntu")
for q in $(lsblk --pairs | grep 'RM="0"' | grep -v 'MOUNTPOINTS=""' | grep -v loop | grep -v "/boot/efi" | cut -d '"' -f 14); do
	if [ $q == "/" ]; then
		this_path="/home/$(whoami)"
	else
		this_path="$q"
	fi	
	basename_this_path=$(basename $this_path)	
	unset cicle_exit
	if [[ (-d "$this_path") && ! " ${except[@]} " =~ " ${basename_this_path} " ]]; then
		cd $this_path
		for file in $(find ./ -maxdepth 5 -type f -name 'quartus_sh'); do
			if [[ -f $file ]]; then
				QUARTUS_ROOTDIR=$(realpath $(dirname $(dirname $file)))
				cicle_exit="OK"
				break
			else
				unset cicle_exit
			fi
		done
	fi
	if [[ -n $cicle_exit ]]; then
		break
	fi
done

if [ -d "$QUARTUS_ROOTDIR" ]; then
	export QUARTUS_ROOTDIR=$(realpath $QUARTUS_ROOTDIR)
	export PATH=$QUARTUS_ROOTDIR/bin:$QUARTUS_ROOTDIR/linux64:$QUARTUS_ROOTDIR/../qsys/bin:$PATH
else
	echo -e "\tQUARTUS dir not found, check is disk partion with QUARTUS mounted" | tee -a $home/log
	exit
fi
cd $home
