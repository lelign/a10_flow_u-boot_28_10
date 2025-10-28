#!/bin/bash
#echo -e "\n"
pat="[0-9][0-9]-[0-9][0-9]_[0-9][0-9]_[0-9][0-9]_[0-9][0-9]_gsrd"
rm -rf $(find . -maxdepth 1 -iname $pat)
