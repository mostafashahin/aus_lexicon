#!/bin/env bash

sudo apt-get update
sudo apt-get install -y git g++ autoconf-archive make libtool
sudo apt-get install -y python-setuptools python-dev
sudo apt-get install -y gfortran
sudo apt-get install -y python3-pip
wget http://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.6.2.tar.gz
tar -xvzf openfst-1.6.2.tar.gz
cd openfst-1.6.2
./configure --enable-static --enable-shared --enable-far --enable-ngram-fsts

make -j 4
sudo make install
cd ..
echo 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib:/usr/local/lib/fst'      >> ~/.bashrc
source ~/.bashrc
git clone https://github.com/AdolfVonKleist/Phonetisaurus.git

cd Phonetisaurus/
sudo pip3 install pybindgen
PYTHON=python3 ./configure --enable-python
make
sudo make install
cd python
cp ../.libs/Phonetisaurus.so .
sudo python3 setup.py install
cd ../..
git clone https://github.com/mitlm/mitlm.git
cd mitlm/
./autogen.sh
make
sudo make install
cd ..
