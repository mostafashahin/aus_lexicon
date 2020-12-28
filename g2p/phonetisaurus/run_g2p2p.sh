IFS=$'\n'
stage=0
arpa_lex_train=../../data/cmudict.formatted_upp.dict
arpa_aus_lex_train=../arpa2aus.dict
aus_lex_test=../lexicon_test.txt
test_wrd_list=test_words
nOrderG2p=$1
nOrderP2p=$2

#TODO get only words that has ref in lex_test



if [ $stage -le 0 ]; then
    #Build graph 2 arpa
    phonetisaurus-train -o $nOrderG2p -mp model_g2arpa_$nOrderG2p --lexicon $arpa_lex_train --seq2_del
fi

if [ $stage -le 1 ]; then
	#Build arpa 2 aus model
	phonetisaurus-train -o $nOrderP2p -s1cd " " -mp model_arpa2aus_$nOrderP2p --lexicon $arpa_aus_lex_train --seq2_del 
fi



if [ $stage -le 2 ]; then
	#Get arpa trans from model with lexicon
	phonetisaurus-apply --model train/model_g2arpa_$nOrderG2p.fst --word_list $test_wrd_list -l $arpa_lex_train > test/arpa_gen_$nOrderG2p.dict 

fi

if [ $stage -le 3 ]; then
	#Get aus trans from arpa using p2p model and eval
	cat test/arpa_gen_$nOrderG2p.dict | cut -f2 > test/arpa_gen_$nOrderG2p.trans
	cat test/arpa_gen_$nOrderG2p.dict | cut -f1 > test/arpa_gen_$nOrderG2p.wrds
	phonetisaurus-apply -gs " " --model train/model_arpa2aus_$nOrderP2p.fst --word_list test/arpa_gen_$nOrderG2p.trans > test/arpa_aus_gen_${nOrderG2p}_${nOrderP2p}.dict
	cat test/arpa_aus_gen_${nOrderG2p}_${nOrderP2p}.dict | while read line; do t=`echo $line | cut -f2`; l=`echo $line | cut -f1`; m=`grep -P "\t$l$" test/arpa_gen_$nOrderG2p.dict | cut -f1` ; for w in $m; do echo -e "$w\t$t"; done; done > test/aus_gen_${nOrderG2p}_${nOrderP2p}.dict

	#eval
	grep -wf $test_wrd_list $aus_lex_test > test/aus_ref.dict
	lex_ref=test/aus_ref.dict

	total_ws=`cat $lex_ref | wc -l`
	correct_ws=`grep -wf $lex_ref test/aus_gen_${nOrderG2p}_${nOrderP2p}.dict | wc -l`
	echo $correct_ws/$total_ws
	acc=`echo $correct_ws/$total_ws | bc -l`
	echo "Accuracy of ${nOrderG2p} ${nOrderP2p} = $acc"
fi


exit 0

lex_train='../lexicon_train.txt'
lex_test='../lexicon_test.txt'
nOrders='2 4 6 8'
prefix='faad-ald'
cd ..
. ./path.sh
cd phonetisaurus

mkdir -p test
rm test/results-$prefix
for order in $nOrders; do
	echo $order >> test/results-$prefix
	phonetisaurus-train -o $order -mp model_$order --lexicon $lex_train --seq2_del
	cat $lex_test | cut -f1 > test_wrd_list
	phonetisaurus-apply --model train/model_$order.fst --word_list test_wrd_list > test/lexicon_gen_$order.txt
	#Add index to distangush between similar words for compute-wer
	seq 1 `cat test_wrd_list | wc -l` > test/indexs
	paste -d'-' test/indexs test/lexicon_gen_$order.txt > test/lexicon_gen_index_$order.txt
	paste -d'-' test/indexs lexicon_test.txt > test/lexicon_test_index_$order.txt

	#TODO handle multiple pronunciations
	compute-wer --text --mode=present ark:test/lexicon_test_index_$order.txt ark:test/lexicon_gen_index_$order.txt >> test/results-$prefix
done
