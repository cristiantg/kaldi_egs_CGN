These scripts can be used to train acoustic models, language models, and obtain a lexicon from the raw CGN data.
Everything is experimental, though has been tested. Please let me know if something doesn't work properly!

**Cristian TG changes - since 20201/Mar/01**


Initial configuration of the project (just one time):


*First step:*
Install the SRILM tool. First, you need to download the file from the webpage: http://www.speech.sri.com/projects/srilm/download.html, change the name to `srilm.tar.gz`, put the file on: `$KALDI_ROOT/tools` and run:
```
cd $KALDI_ROOT/tools
./install_srilm.sh
```


*Second step:*
Make sure you have GPUs on your machine to run DNN training scripts:
```
cd `echo $KALDI_ROOT/src`
./configure --use-cuda --cudatk-dir=/usr/local/cuda-11.2/ --cuda-arch=-arch=sm_70
./configure --shared
make -j clean depend; make -j 10
```


*Third step:*
Soft link to wsj project folder:
```
cd $KALDI_ROOT/egs/kaldi_egs_CGN
ln -s $KALDI_ROOT/egs/wsj/s5/utils/ s5/utils
ln -s $KALDI_ROOT/egs/wsj/s5/steps/ s5/steps
```

*Fourth step:*
Change the value of export KALDI_ROOT in `path.sh`:
```
nano $KALDI_ROOT/egs/kaldi_egs_CGN/s5/path.sh
```


*Fifth step:*
Be sure you have enough privileges to run sh scripts:
```
cd $KALDI_ROOT/egs/kaldi_egs_CGN
chmod -R 774 ./*
```