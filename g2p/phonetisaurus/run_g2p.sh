lex_train='../lexicon_train.txt'
lex_test='../lexicon_test.txt'
nOrders='2 4 6 8'
prefix='faad-ald'
test_wrd_list=test_words
cd ..
. ./path.sh
cd phonetisaurus

mkdir -p test
rm test/results-$prefix
for order in $nOrders; do
	echo $order >> test/results-$prefix
	phonetisaurus-train -o $order -mp model_$order --lexicon $lex_train --seq2_del
	#cat $lex_test | cut -f1 > test_wrd_list
	phonetisaurus-apply --model train/model_$order.fst --word_list $test_wrd_list > test/lexicon_gen_$order.txt
	
	
	#eval
	grep -wf $test_wrd_list $lex_test > test/aus_ref.dict
	lex_ref=test/aus_ref.dict

	total_ws=`cat $lex_ref | wc -l`
	correct_ws=`grep -wf $lex_ref test/lexicon_gen_$order.txt | wc -l`
	echo $correct_ws/$total_ws
	acc=`echo $correct_ws/$total_ws | bc -l`
	echo "Accuracy of $order = $acc"
	#Add index to distangush between similar words for compute-wer
	#seq 1 `cat test_wrd_list | wc -l` > test/indexs
	#paste -d'-' test/indexs test/lexicon_gen_$order.txt > test/lexicon_gen_index_$order.txt
	#paste -d'-' test/indexs lexicon_test.txt > test/lexicon_test_index_$order.txt

	#TODO handle multiple pronunciations
	#compute-wer --text --mode=present ark:test/lexicon_test_index_$order.txt ark:test/lexicon_gen_index_$order.txt >> test/results-$prefix
done
