These scripts can be used to train acoustic models, language models, and obtain a lexicon from the raw CGN data.
Everything is experimental, though has been tested. Please let me know if something doesn't work properly!

**Cristian TG changes - since 20201/Mar/01**


Initial configuration of the project (just one time):


*First:*
Install the SRILM tool. First, you need to download the file from the webpage: http://www.speech.sri.com/projects/srilm/download.html, change the name to `srilm.tar.gz`, put the file on: `$KALDI_ROOT/tools` and run:
```
cd $KALDI_ROOT/tools
./install_srilm.sh
```


*Second:*
Soft link to wsj project folder:
```
cd s5
ln -s $KALDI_ROOT/egs/wsj/s5/utils/ s5/utils
ln -s $KALDI_ROOT/egs/wsj/s5/steps/ s5/steps
```

*Third:*
Change the value of export KALDI_ROOT in `path.sh`:
```
cd s5
nano path.sh
```


*Fourth:*
Be sure you have enough privileges to run sh scripts:
```
cd s5
chmod -R 774 ./*
```