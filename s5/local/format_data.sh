#!/bin/bash 
# modified by Cristian TG  (2022/09/02)
# $1 output folder: data/train
# $2 input lang folder: lang
# $3 arpa file in gz: arpatrain.gz
# $4 input data folder


if [ -f path.sh ]; then . path.sh; fi

silprob=0.5

  echo  "Running: format_data.sh output:$1 lang:$2 arpa:$3 input_data:$4"
  mkdir -p $1

  arpa_lm=$3
  [ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

  # Copy stuff into its final locations...
  #for f in spk2utt utt2spk wav.scp text reco2file_and_channel; do
  for f in spk2utt utt2spk wav.scp text; do
  echo
  #echo "pepe $4/$f $1/$f"
    cp $4/$f $1/$f || exit 1;
  done
  m_seg=$4/segments
  if [[ -f "$m_seg" ]]; then
    cp $m_seg $1/segments || exit 1;
  fi


  echo  "-- format_data lm"
  # grep -v '<s> <s>' etc. is only for future-proofing this script.  Our
  # LM doesn't have these "invalid combinations".  These can cause 
  # determinization failures of CLG [ends up being epsilon cycles].
  # Note: remove_oovs.pl takes a list of words in the LM that aren't in
  # our word list.  Since our LM doesn't have any, we just give it
  # /test/null [we leave it in the script to show how you'd do it].
  gunzip -c "$arpa_lm" | \
    grep -v '<s> <s>' | \
    grep -v '</s> <s>' | \
    grep -v '</s> </s>' | \
    arpa2fst - | fstprint | \
    # utils/remove_oovs.pl /test/null | \
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$2/words.txt \
      --osymbols=$2/words.txt  --keep_isymbols=false --keep_osymbols=false | \
      fstrmepsilon > $2/G.fst
    fstisstochastic $2/G.fst

  echo  "-- Checking how stochastic G is (the first of these numbers should be small):"
  fstisstochastic $2/G.fst 

  ## Check lexicon.
  ## just have a look and make sure it seems sane.
  echo "-- First few lines of lexicon FST:"
  fstprint   --isymbols=$2/phones.txt --osymbols=$2/words.txt $2/L.fst  | head



# TODO: if uncommented, include   $2 also 
# echo Performing further checks

# # Checking that G.fst is determinizable.
# fstdeterminize $2_test/G.fst /test/null || echo Error determinizing G.

# # Checking that L_disambig.fst is determinizable.
# fstdeterminize $2_test/L_disambig.fst /test/null || echo Error determinizing L.

# # Checking that disambiguated lexicon times G is determinizable
# # Note: we do this with fstdeterminizestar not fstdeterminize, as
# # fstdeterminize was taking forever (presumbaly relates to a bug
# # in this version of OpenFst that makes determinization slow for
# # some case).
# fsttablecompose $2_test/L_disambig.fst $2_test/G.fst | \
#    fstdeterminizestar >/test/null || echo Error

# # Checking that LG is stochastic:
# fsttablecompose $2/L_disambig.fst $2_test/G.fst | \
#    fstisstochastic || echo LG is not stochastic


# echo hkust_format_data succeeded.