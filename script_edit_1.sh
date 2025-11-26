#!/bin/bash
reset
generated_quartus_projects=$(realpath $(find ./ -maxdepth 4 -type f -name "*.fit.rpt" | grep "edited"))
file_fit_rpt=$(ls -tr $generated_quartus_projects | tail -1)
if [ ! -f $file_fit_rpt ]; then # error
        echo -e "\n\tError : file *.fit.rpt not found, exit..."
        exit
fi
errors_files="errors_files"
rm -rf $errors_files && mkdir $errors_files
project=$(basename $(dirname $(dirname $file_fit_rpt)))
project_path=$(realpath $(dirname $(dirname $file_fit_rpt)))
if [ ! -f $project_path/create_ghrd_quartus.tcl ]; then # error
        echo -e "\n\t\Error: $project_path/create_ghrd_quartus.tcl\n\tnot found, exit..."
fi
total_pin_assigment_in_create_ghrd_quartus=$(cat $project_path/create_ghrd_quartus.tcl | grep "PIN_"[A-Z] -c)
echo -e "\n\tPROJECT: $project PIN assign on start $total_pin_assigment_in_create_ghrd_quartus"
device=$(cat $generated_quartus_projects | grep "; Device  " | head -1 | cut -d ";" -f 3)
echo -e "\n\tDevice = $device"
if [ ! -d $(pwd)/gsrd_native ]; then # error
        echo -e "\n\t\Error: needs $(pwd)/gsrd_native, exit..."
else
        native=$(pwd)/gsrd_native
fi

read -p $'\n\t'"Покавыать подробный вывод? y/n " detailed_out

if [ "$detailed_out" == "y" ]; then # показать сводку
        tot_lines=$(wc -l < $file_fit_rpt)
        echo -e "\n\tВсего записей $tot_lines"
        echo -e "\tВсего <Info> $(cat $file_fit_rpt | grep "Info ([0-9]*" -c)"
        echo -e "\tВсего <Error> $(cat $file_fit_rpt | grep "Error ([0-9]*" -c)"
        echo -e "\tВсего <Critical Warning> $(cat $file_fit_rpt | grep "Critical Warning ([0-9]*" -c)"
fi

error_ar=()
cr_warn_ar=()
while IFS= read -r line; do # собрать массивы error_ar cr_warn_ar
        pin=""
        if [[ "$line" == *"Error ("* ]]; then
                error_ar+=("$line")
        fi
        if [[ "$line" == *"Critical Warning ("* ]]; then
                cr_warn_ar+=("$line")
        fi        
done <$file_fit_rpt

if [ "$detailed_out" == "y" ]; then # показать размеры массивов error_ar cr_warn_ar
        error_ar_length=${#error_ar[@]}
        cr_warn_ar=${#cr_warn_ar[@]}
        echo -e "\n\terror_ar_length=$error_ar_length\tcr_warn_ar=$cr_warn_ar"
        echo -e "\n\t\t\tERRORS"
fi

if [ "$detailed_out" == "y" ]; then # заголовок таблицы
        SYMBOL='='
        printf " %-35s | %-85s | %-35s |\n" "" | tr ' ' "$SYMBOL"
        printf " %-35s | %-85s | %-35s |\n" "PIN ASIGMENT" " ASSIGMENT USED " "FILE NAME"
        printf " %-35s | %-85s | %-35s |\n" "" | tr ' ' "$SYMBOL"
fi

err_num=0
files_for_edit=(" ")
arr_pin_excluded=(" ")

for err in "${error_ar[@]}"; do # сбор данных согласно error_ar
	pin_1=$(echo $err | grep -oE "PIN_[^;]*" | cut -d " " -f 1)
        pin=$(echo ${pin_1//\"/})
        #signal_=$(echo $err | cut -d " " -f 6) signal=$(echo $signal_ | cut -d "~" -f 1 ) signal=$(echo ${signal//\"/})        
        if [[ -n "${pin}" ]]; then
                # add pin to arr_pin_excluded()
                #found=0; for p in "${arr_pin_excluded[@]}"; do if [ "$p" == "$pin" ]; then found=1; break; fi; done; if [[ $found -eq 0 ]]; then arr_pin_excluded+=("$pin"); fi
                for file in $(find $native -type f); do
                        pin_assign=$(cat $file | grep -oE "$pin[^;]*")
                        #pin_assign=$(cat $file | grep $pin)
                        line_n="line_n"
                        if [[ -n "${pin_assign}" ]]; then
                                ((err_num+=1))
                                for pin_to in $(cat $file | grep -oE "$pin[^;]*" | cut -d " " -f 3); do
                                        
                                        b_n_f=$(basename $file | tr -d '\n')
                                        
                                        mapfile -t arr_with_pin_to < <(cat $(find $native -type f) | grep -F $pin_to)
                                        
                                        fnd=0 
                                        for pin_excluded in "${arr_pin_excluded[@]}"; do # add pin to ${arr_pin_excluded[@]}
                                                if [[  "$pin_excluded" == "$pin" ]]; then 
                                                        fnd=1 
                                                        break 
                                                fi
                                        done 
                                        if [[ $fnd -eq 0 ]]; then # add pin to ${arr_pin_excluded[@]}
                                                arr_pin_excluded+=("$pin")
                                        fi
                                                  
                                        if [ "$detailed_out" == "y" ]; then
                                                printf " %-35s | %-85s |\n" "$err_num $pin to $pin_to" "     FOUND <$pin_to>"
                                        fi
                                        cn=0
                                        for el_in_arr_with_pin_to in "${arr_with_pin_to[@]}"; do
                                                file_with_pin_to=$(find $native -type f -exec grep -lF "${arr_with_pin_to[$cn]}" {} +)
                                                bn_file_with_pin_to=$(basename $file_with_pin_to)
                                                found=0
                                                for file_for_edit in "${files_for_edit[@]}"; do                                                        
                                                        if [[  "$file_for_edit" == "$bn_file_with_pin_to" ]]; then
                                                                found=1
                                                                break
                                                        fi                                                        
                                                done
                                                
                                                if [[ $found -eq 0 ]]; then
                                                        files_for_edit+=("$bn_file_with_pin_to")                                                        
                                                fi
                                                if [ "$detailed_out" == "y" ]; then
                                                        printf " %-35s | %-85s | %-35s\n" " " "$el_in_arr_with_pin_to" "$bn_file_with_pin_to"
                                                fi
                                                echo "$el_in_arr_with_pin_to" >> $errors_files/$bn_file_with_pin_to
                                                ((cn+=1))
                                        done

                                done
                                if [ "$detailed_out" == "y" ]; then
                                        printf " %-35s | %-85s | %-35s\n"
                                fi
                                        
                        fi
                done
        fi
done
echo -e "\n\tвсего из $total_pin_assigment_in_create_ghrd_quartus ошибочных PIN назначений ${#arr_pin_excluded[@]}"
#for elem in ${arr_pin_excluded[@]}; do # for check echo -e "check pin = $elem" done
#declare -p arr_pin_excluded # export arr_pin_excluded to terminal
if [ "$detailed_out" == "y" ]; then # показать имена файлов для редактирования
        echo -e "\n\tfiles_for_edit :"
        for file_to_edit in "${files_for_edit[@]}"; do
                if [ "$file_to_edit" != " " ]; then
                        echo -e "\t\t$file_to_edit"
                fi
        done
fi

echo -e "\n\texample :\n\t\tgenerated_quartus_projects/24-11_15_57_56_cleaned_edited"
read -p $'\n\t'"Путь к проекту в который будем вносить изменения ?:" path_project

if [ ! -d $path_project ]; then # check users path
        echo -e "Error : path $path_project not found! exit..."
        exit
fi
############################## check files in users path
for file_to_edit in "${files_for_edit[@]}"; do # check files in users path
        if [ "$file_to_edit" != " " ]; then
                if [ ! -f  $path_project/$file_to_edit ]; then
                        echo -e "Error : file $path_project/$file_to_edit not found! exit..."
                        exit
                fi
        fi
done

arr_pin_included=() # массив с PIN включенными в ${files_for_edit[@]}
for file_to_edit in "${files_for_edit[@]}"; do # редактирование файлов
        if [ -f $path_project/$file_to_edit ]; then
                count=0
                echo -e "\n\tWORK WITH FILE $file_to_edit"
                if [ "$detailed_out" == "y" ]; then
                      echo -e "\t\ttotal excluded :"  
                fi
                while IFS= read -r line; do
                        include=$(cat errors_files/$file_to_edit | grep -F "$line")
                        include_c=$(cat errors_files/$file_to_edit | grep -F -c "$line")
                        if [[ -n "${include}" && "$include_c" -eq 1 ]]; then
                                ((count+=1))
                                if [ "$detailed_out" == "y" ]; then
                                        echo -e "\t\t\t$line"
                                        #echo "# $line # commented" >> "errors_files/edited_$file_to_edit"
                                fi
                        else
                                echo "$line" >> "errors_files/edited_$file_to_edit"
                                pin_included=$(echo $line | grep -oE "PIN_[^;]*" | cut -d " " -f 1)


                                if [ -n "${pin_included}" ]; then
                                        arr_pin_included+=("$pin_included")
                                fi
                        fi
                done <$path_project/$file_to_edit
                echo -e "\t\ttotal excluded : $count"
        fi
done

echo -e "\n\tвсего ошибочных PIN назначений ${#arr_pin_excluded[@]}"
echo -e "\n\tвсего использовано PIN назначений ${#arr_pin_included[@]}"
# pin_included
# for elem in ${arr_pin_included[@]}; do # for check OK echo -e "check pin included = $elem" done
echo -e "\n\texample :\n\t\t$HOME/Quartus_projects/AR_PROV1_2_compiled_with_some_changes"
echo -e "\n\texample :\n\t\t$HOME/Quartus_projects/AR_PROV_native_yandex/AR_PROV1_2/AR_PROV1_2"
read -p $'\n\t'"Путь к проекту из которого будем добавлять PIN назначения ?:" path_source
if [ ! -d $path_source ]; then # check users path
        echo -e "Error : path $path_source not found! exit..."
        exit
fi

name_source_project=$(basename -s .qpf $(find $path_source -maxdepth 1 -iname "*.qpf"))
if [[ -n "${name_source_project}" && -f $path_source/$name_source_project.qsf ]]; then # assign $source_qsf
        source_qsf="$path_source/$name_source_project.qsf"
        if [ "$detailed_out" == "y" ]; then
                echo -e "\n\tOK source_qsf = $source_qsf"
        fi
else # error
        echo "Error : in path $path_source not found file $name_source_project.qsf exit..."
        exit
fi


for file_to_edit in "${files_for_edit[@]}"; do # проверка соответствия отредактированных файлов и файлов выбранного проекта 
        if [ "$file_to_edit" != " " ]; then
                if [ ! -f  $path_project/$file_to_edit ]; then
                        echo -e "Error : file $path_project/$file_to_edit not found! exit..."
                        exit
                fi
        fi
done

# собираем массив PIN из файла $source_qsf
arr_pin_source=()
pin_1=$(cat $source_qsf | grep -oE "PIN_[^;]*" | cut -d " " -f 1)
pin=$(echo ${pin_1//\"/})
for p in $pin; do # собираем массив PIN из файла $source_qsf
        found=0
        for p_added in "${arr_pin_source[@]}"; do                                                        
                if [[  "$p_added" == "$p" ]]; then
                        found=1
                        break
                fi                                                        
        done

        if [[ $found -eq 0 ]]; then
                arr_pin_source+=("$p")                                                        
        fi        
done


echo -e "\n\tв файле $source_qsf \n\tнайдено PIN назначений : ${#arr_pin_source[@]}" # при проверке было 241

# сравнение PIN в ${arr_pin_source[@]} и в ${arr_pin_included[@]}
cnt_in=0
cnt_out=0
rm -rf in_both_project
echo "in_both_project" > in_both_project
for pin_included in ${arr_pin_included[@]}; do
        for pin_source in ${arr_pin_source[@]}; do
                #pin_exist=0
                if [ "$pin_included" == "$pin_source" ]; then
                        #pin_exist=1
                        ((cnt_in+=1))
                        #echo -e "\t$cnt_in\t$pin_source in arr_pin_included[@]"
                        echo -e "$cnt_in\t$pin_included" >> in_both_project
                        for_pin_included=$(cat errors_files/edited_create_ghrd_quartus.tcl | grep "$pin_included -to")
                        for_pin_source=$(cat $source_qsf | grep "$pin_source -to")
                        echo "$for_pin_included" >> in_both_project
                        echo -e "source :\t\t$for_pin_source" >> in_both_project
                        echo "" >> in_both_project
                        break
                #else
                #        ((cnt_out+=1))
                #        echo -e "\n\t\t\t$cnt_out PIN $pin_source not in arr_pin_included[@]\n"
                fi
        done             
done
# сводка
#$total_pin_assigment_in_create_ghrd_quartus
SYMBOL='='
printf " %-25s | %-25s | %-25s | %-25s |\n" "" | tr ' ' "$SYMBOL"
printf " %-25s | %-25s | %-25s | %-25s |\n" " Изначальных PIN         " " ошибочных" "в $name_source_project" "пересечение"
printf " %-25s | %-25s | %-25s | %-25s |\n" "" | tr ' ' "$SYMBOL"
printf " %-25s | %-25s | %-25s | %-25s |\n" "$total_pin_assigment_in_create_ghrd_quartus" "${#arr_pin_excluded[@]}" "${#arr_pin_source[@]}" "$cnt_in"



read -p $'\n\t'"Ппродолжить для critical warnings ?: " cont_cr_warn

if [ "$cont_cr_warn" == "y" ]; then # Ппродолжить для critical warnings
        echo -e "\n\tCritical Warning"
        printf " %-8s | %-25s\n" "PIN" "SIGNAL"
        for cr_w in "${cr_warn_ar[@]}"; do
                pin_1=$(echo $cr_w | grep -oE "PIN_[^;]*" | cut -d " " -f 1)
                pin=$(echo ${pin_1//\"/})
                signal=$(echo $cr_w | cut -d " " -f 9)
                signal=$(echo ${signal//\"/})
                if [[ -n "${pin}" ]]; then
                        printf " %-8s | %-25s\n" "$pin" "$signal"
                fi
        done
fi
exit




# на этом этапе ошибок нет ну нету их 1
# здесь правильно
