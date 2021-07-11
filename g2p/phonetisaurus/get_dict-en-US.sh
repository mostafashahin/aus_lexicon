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
g2arpa_model=data/model_g2arpa_8.fst


in_wrd_lst=oov_words
#out_dict=$2

mkdir -p tmp

#get arpa phoneme trans
phonetisaurus-apply --model $g2arpa_model --word_list $in_wrd_lst -l $cmu_dict > tmp/arpa_gen.dict

cat tmp/arpa_gen.dict
