# Cristian Tejedor-García new changes  since 2021/Mar/01**

- Step by step execution logs (EXE1, EXE2 and EXE3).

- Possibility of including  a custom lexicon.

- Added real-time decoding scripts (server-load.sh, uber_single.sh and uber.sh)

- Tested on Ponyland cluster/GPUs.




# Initial configuration of the project (just one time):


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
project=$KALDI_ROOT/egs/kaldi_egs_CGN/s5/ && cd $project && clear && pwd
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
cd $project && clear && pwd
chmod -R 770 ./*
```


# Execution:

**Tested on Thunderlane/Ponyland**

*EXE1: ~6h*:
```
# Change: includednnprep=false & stage=0
cd $project && clear && pwd
# mv nohup.out prev_nohup.out
# rm -r data exp
nohup time ./run.sh &

# Extra: tree -L 2 data exp > tree_exe1.txt
```

*EXE2: ~11h*:
```
# Change: includednnprep=true and stage=7
nohup time ./run.sh &

# Extra: tree -L 2 data exp > tree_exe2.txt
```

*EXE3 (GPUs needed): 23h*:
```
nohup time ./local/chain/run_tdnn.sh &

# Extra: tree -L 2 data exp > tree_exe3.txt
```


# Check WER results

```
for x in exp/*/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done | sort -n > best_wer.txt
```