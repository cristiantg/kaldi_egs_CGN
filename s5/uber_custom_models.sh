#!/usr/bin/env bash

### Preprocessing CTM files at Nivel for data preparation
# Depends on these two repositories:
# https://github.com/cristiantg/lexiconator
# https://github.com/cristiantg/ctmator

# Change the values of the following variables:
stage=1
# Credentials of: https://webservices.cls.ru.nl/
USER_WS=<CHANGE_THIS_VALUE>
PWD_WS=<CHANGE_THIS_VALUE>
ctmator=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi_nl/ctmator
lexiconator=/home/ctejedor/python-scripts/lexiconator
audio_source=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi_nl/homed_wav
ctm_source=$ctmator/ref_original

# Optional:
output_project=$KALDI_ROOT/egs/kaldi_egs_CGN/s5/homed
output_audio_splitted=audio_split
output_ctm_splitted=ctm_split
lexiconator_pre_lexicon=$lexiconator/input
output_custom_lexicon=outputlexicon
absolute_lexicon=$output_project/$output_custom_lexicon
final_combined_lexicon=combined.lex


if [ $stage -le 1 ]; then
    echo
    echo "Stage 1. Split all audio files in a folder into sentence-based files, based on ctm files"
    for i in $audio_source/*.wav; do
        [ -f "$i" ] || break
        filename=$(basename -- "$i")
        #extension="${filename##*.}"
        filename="${filename%.*}"
        #echo $filename
        python3 $ctmator/splitaudioctm.py $audio_source/$filename.wav $ctm_source/$filename.ctm . $output_project/$output_audio_splitted $output_project/$output_ctm_splitted
    done
fi

if [ $stage -le 2 ]; then
    echo
    echo "Stage 2. We need a lexicon which combines CGN + custom data from all .ctm files"
    # Words from custom data must be 'cleaned' first (homed protocol v2.0)
    
    python3 $ctmator/extractCtmWords.py $output_project/$output_ctm_splitted $absolute_lexicon
    ####python3 $ctmator/extractCtmWords.py /vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi/egs/kaldi_egs_CGN/s5/homed/ctm_test $absolute_lexicon    
    python3 $lexiconator/utils/preparing_raw_data.py $absolute_lexicon $lexiconator_pre_lexicon
    python3 $lexiconator/uber_script.py $USER_WS $PWD_WS $lexiconator 1 1 "<unk><TAB>spn" $lexiconator_pre_lexicon/wordlist $absolute_lexicon

    python3 $ctmator/merge_lex.py $output_project/../wordlists/lexicon.txt $absolute_lexicon/results-final/lexicon.txt $absolute_lexicon/results-final/$final_combined_lexicon
fi