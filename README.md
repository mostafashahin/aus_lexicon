# aus_lexicon
cat test_words | sudo docker run -i -w /opt/aus_lexicon/g2p/phonetisaurus  g2p:3.5 ./get_dict.sh > out
