#!/bin/env bash
cat - | tr [:lower:] [:upper:] > oov_words

IFS=$'\n'

wget -O cmudict.dict https://raw.githubusercontent.com/cmusphinx/cmudict/master/cmudict.dict 2>/dev/null
cat cmudict.dict \
  | perl -pe 's/\([0-9]+\)//;
              s/[0-9]//g;
              s/\s+/ /g; s/^\s+//;
              s/\s+$//; @_ = split (/\s+/);
              $w = shift (@_);
              $_ = $w."\t".join (" ", @_)."\n";' | sed '/#/d' | tr [:lower:] [:upper:] > cmudict.formatted_upp.dict

cmu_dict=cmudict.formatted_upp.dict
arpa2aus_dict=data/arpa2aus.dict
g2arpa_model=data/model_g2arpa_8.fst
arpa2aus_model=data/model_arpa2aus.fst

phone_list=data/asr_phoneme.list
phone_map=data/asr2sampa.map

in_wrd_lst=oov_words
#out_dict=$2

mkdir -p tmp

#get arpa phoneme trans
phonetisaurus-apply --model $g2arpa_model --word_list $in_wrd_lst -l $cmu_dict > tmp/arpa_gen.dict

#Get aus trans from arpa using p2p model and eval
cat tmp/arpa_gen.dict | cut -f2 > tmp/arpa_gen.trans
cat tmp/arpa_gen.dict | cut -f1 > tmp/arpa_gen.wrds
phonetisaurus-apply -gs " " --model $arpa2aus_model --word_list tmp/arpa_gen.trans > tmp/arpa_aus_gen.dict
cat tmp/arpa_aus_gen.dict | while read line; do t=`echo $line | cut -f2`; l=`echo $line | cut -f1`; m=`grep -P "\t$l$" tmp/arpa_gen.dict | cut -f1` ; for w in $m; do echo -e "$w\t$t"; done; done > tmp/aus_gen.dict

#convert to sampa

python3 ../../dict_tool/map_dict.py tmp/aus_gen.dict $phone_list $phone_map oov_dict

cat oov_dict
