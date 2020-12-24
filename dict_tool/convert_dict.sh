#!/bin/env bash
#TODO write help and argument parser
set -e

cat - > in_dict

in_alphabet=$1
out_alphabet=$2

#TODO validate in_dict formt
#TODO validate that map files are exist

python3 dict_tool/map_dict.py in_dict data/${in_alphabet}_phoneme.list data/${in_alphabet}2${out_alphabet}.map out_dict

cat out_dict

rm in_dict out_dict