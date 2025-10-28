#!/bin/bash
for object in $(ls $HOME/Quartus/VIKTOR); do
	if [ -d $HOME/Quartus/VIKTOR/$object ]; then
		project=$(find $HOME/Quartus/VIKTOR/$object -maxdepth 1 -type f -name *.qpf)
		if [ -n $project ]; then
			project_name=$(cat $project | grep PROJECT_REVISION | cut -d '"' -f 2)
			echo "$project_name  in  $HOME/Quartus/VIKTOR/$object"
		fi
	fi
done

title=$(date "+%d-%m_%H_%M_%S")
echo -e "\n\t\t\tEnter full path to Quartus project"
read project_path
if [[ -f $project_path/output_files/$project_name.sof && -d $project_path/hps_isw_handoff ]]; then
#	echo $(file $project_path/output_files/$project_name.sof)
	sof_path=$project_path/output_files/$project_name.sof
	output_rbf=$title
	output_rbf+=".rbf"
	quartus_cpf="/home/$(whoami)/Quartus/Quartus_pro_21_4/quartus/bin/quartus_cpf"
	if [ -f $quartus_cpf ]; then
		flags="-c --hps -o bitstream_compression=on "
		$quartus_cpf $flags $sof_path $output_rbf
		rm -rf ghrd_10as066n2.core.rbf
		ln -s $title.periph.rbf ghrd_10as066n2.core.rbf
		rm -rf ghrd_10as066n2.periph.rbf
		ln -s $title.periph.rbf ghrd_10as066n2.periph.rbf
		rm -rf hps_isw_handoff
		ln -s $project_path/hps_isw_handoff hps_isw_handoff
		echo -e "\n\t\t\t DONE !!!"
	else
		echo -e "\n\t\t\tScript <quartus_cpf> NOT FOUND !!!"
		exit
	fi


else
	echo -e "\n\t\t\tInput file <sof> in path $read_sof not found"
	exit
fi
