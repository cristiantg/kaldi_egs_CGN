These scripts can be used to train acoustic models, language models, and obtain a lexicon from the raw CGN data.
Everything is experimental, though has been tested. Please let me know if something doesn't work properly!

**Cristian TG changes - since 20201/Mar/01**

First: 
Soft link to wsj project folder:
```
ln -s $KALDI_ROOT/egs/wsj/s5/utils/ s5/utils
ln -s $KALDI_ROOT/egs/wsj/s5/steps/ s5/steps
```

Second:
Be sure you have enough privileges to run sh scripts:
```
chmod -R 774 ./*
```