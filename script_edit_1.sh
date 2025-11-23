#!/bin/bash
reset
generated_quartus_projects=$(realpath $(find ./ -maxdepth 4 -type f -name "*.fit.rpt" | grep "edited"))
file_fit_rpt=$(ls -tr $generated_quartus_projects | tail -1)
if [ ! -f $file_fit_rpt ]; then
        echo -e "\n\tError : file *.fit.rpt not found, exit..."
        exit
fi

echo -e "\n\tPROJECT: $(basename $(dirname $(dirname $file_fit_rpt)))"
if [ ! -d $(pwd)/gsrd_native ]; then
        echo -e "\n\t\Error: needs $(pwd)/gsrd_native, exit..."
else
        native=$(pwd)/gsrd_native
fi

tot_lines=$(wc -l < $file_fit_rpt)
echo -e "\n\tВсего записей $tot_lines"
echo -e "\tВсего <Info> $(cat $file_fit_rpt | grep "Info ([0-9]*" -c)"
echo -e "\tВсего <Error> $(cat $file_fit_rpt | grep "Error ([0-9]*" -c)"
echo -e "\tВсего <Critical Warning> $(cat $file_fit_rpt | grep "Critical Warning ([0-9]*" -c)"

error_ar=()
cr_warn_ar=()
while IFS= read -r line; do
        type=$(echo $line | cut -d ":" -f 1)
        mes=$(echo $line | cut -d ":" -f 2)
        pin=""
        if [[ "$line" == *"Error ("* ]]; then
                error_ar+=("$line")
        fi
        if [[ "$line" == *"Critical Warning ("* ]]; then
                cr_warn_ar+=("$line")
        fi        
done < $file_fit_rpt

error_ar_length=${#error_ar[@]}
cr_warn_ar=${#cr_warn_ar[@]}
echo -e "\n\terror_ar_length=$error_ar_length\tcr_warn_ar=$cr_warn_ar"
echo -e "\n\t\t\tERRORS"
#printf " %-8s | %-25s | %-35s | %-40s\n" "PIN" "SIGNAL" "PIN_ASSIGN" "IN_FILE"
SYMBOL='='
printf " %-35s | %-85s | %-35s |\n" "" | tr ' ' "$SYMBOL"
printf " %-35s | %-85s | %-35s |\n" "PIN ASIGMENT" " ASSIGMENT USED " "FILE NAME"
printf " %-35s | %-85s | %-35s |\n" "" | tr ' ' "$SYMBOL"

for err in "${error_ar[@]}"; do
	pin_1=$(echo $err | grep -oE "PIN_[^;]*" | cut -d " " -f 1)
        pin=$(echo ${pin_1//\"/})
        signal_=$(echo $err | cut -d " " -f 6)
        signal=$(echo $signal_ | cut -d "~" -f 1 )
        signal=$(echo ${signal//\"/})        
        #if [[ "$err" == *"File: "* ]]; then file=$(echo $err | grep -oE "File: [^;]*" | cut -d " " -f 2) file_name=$(basename $file) line_num=$(echo $err | grep -oE "File: [^;]*" | cut -d " " -f 4) fi if [[ -n "${pin}" ]]; then for f in $(find $native -type f); do here=$(cat $f | grep $pin) if [[  -n "${here}" ]]; then name_file=$(basename $f) #echo -e "\t$(basename $f)\t$here" fi done printf " %-8s | %-25s | %-15s | %-4s | %-25s | %-40s |\n" "$pin" "$signal" "$file_name" "$line_num" "$name_file" "$here" fi
        if [[ -n "${pin}" ]]; then
                for file in $(find $native -type f); do
                        pin_assign=$(cat $file | grep -oE "$pin[^;]*")
                        #pin_assign=$(cat $file | grep $pin)
                        line_n="line_n"
                        if [[ -n "${pin_assign}" ]]; then
                                for pin_to in $(cat $file | grep -oE "$pin[^;]*" | cut -d " " -f 3); do
                                        #line_n=$(cat -n $file | grep $el | grep -oE [0-9][0-9][0-9])
                                        b_n_f=$(basename $file | tr -d '\n')
                                        #for line_n in $(cat -n $file | grep $el | grep -oE [0-9][0-9][0-9]); do
                                        mapfile -t myArray < <(cat $(find $native -type f) | grep -F $pin_to)
                                        printf " %-35s | %-85s |\n" "$pin to $pin_to" "     FOUND <$pin_to>"
                                        cn=0
                                        for el in "${myArray[@]}"; do
                                                b_n=$(basename $(find $native -type f -exec grep -lF "${myArray[$cn]}" {} +))
                                                printf " %-35s | %-85s | %-35s\n" " " "$el" "$b_n"
                                                ((cn+=1))
                                        done
                                        

                                        #for f in $(find $native -type f); do
                                        # pin_to_include=$(cat $f | grep $pin_to)
                                        # if [[ -n "${pin_to_include}" ]]; then
                                        #        b_f=$(basename $f)
                                        #        printf " %-8s | %-25s | %-35s | %-4s |\n" " " " " " " "$pin_to_include"
                                        # fi
                                        #done       
                                        #done
                                        #pin_assign=$(echo $pin_assign | grep -oE "PIN_[^;]*") #b_n_f=$(basename $file | tr -d '\n') # grep -oE "$pin[^;]*" # grep -oE "$pin[^;]*" #el_=$(echo -e $el | tr -d '\n') #echo -e "\t\t\tpin_assign=$pin_assign\tb_n_f=$b_n_f" #echo -e "" #for pins in $pin_assign; do #       printf " %-8s | %-25s | %-25s |\n" "$pin" "$signal" "$pins" "$b_n_f"
                                done
                                printf " %-35s | %-85s | %-35s\n"
                        fi


                
        
        
                #printf " %-8s | %-25s | %-15s | %-4s | %-25s | %-40s |\n" "$pin" "$signal" "$file_name" "$line_num" "$name_file" "$here"
                done
        fi
done

read -p $'\n\t'"Contunue ?: " cont

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
exit

