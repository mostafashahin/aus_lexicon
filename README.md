# aus_lexicon
cat test_words | sudo docker run -i -w /opt/aus_lexicon/g2p/phonetisaurus  g2p:4.0 ./get_dict.sh > out

cat dicts/lexicon_au_sampa.txt | head -n 100 | sudo docker run -i -w /opt/aus_lexicon g2p:4.0 ./dict_tool/convert_dict.sh sampa ald
