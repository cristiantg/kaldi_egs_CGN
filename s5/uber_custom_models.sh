#!/usr/bin/env bash

### Preprocessing WAV/CTM files at Nivel for data preparation
# At Nivel:
# 1. wav folder: wav_source
# 2. ctm folder: ctm_source
# 3. feats folder: feats_source
#
# Dependencies:
# 1. https://github.com/cristiantg/lexiconator
# 2. https://github.com/cristiantg/ctmator
# 3. Kaldi installed on $KALDI_ROOT
# 4. Credentials of: https://webservices.cls.ru.nl/
# 5. LaMachine environment
#
# Run:
# time nohup ./uber_custom_models.sh &
# tail -f nohup.out

###############################################################################
# Change the values of the following variables:
###############################################################################
stage=1
# Credentials of: https://webservices.cls.ru.nl/
USER_WS=<change-value>
PWD_WS=<change-value>

ctmator=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi_nl/ctmator
lexiconator=/home/ctejedor/python-scripts/lexiconator
srilm=$KALDI_ROOT/tools/srilm/bin/i686-m64

wav_source=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi_nl/homed_wav
ctm_source=$ctmator/ref_original
feats_source=feats
###############################################################################

# You need a valid Kaldi environment:
. ./cmd.sh || exit 2
[ -f path.sh ] && . ./path.sh || exit 2
[ ! -d "utils" ] && ln -s $KALDI_ROOT/egs/wsj/s5/utils/ utils

###############################################################################
# Optional:
###############################################################################
output_project=$KALDI_ROOT/egs/kaldi_egs_CGN/s5/homed
output_audio_splitted=audio_split
abs_output_audio_splitted=$output_project/$output_audio_splitted
abs_output_audio_splitted_aux=$abs_output_audio_splitted/aux
output_ctm_splitted=ctm_split
abs_ctm_splitted=$output_project/$output_ctm_splitted
lexiconator_pre_lexicon=$lexiconator/input
final_combined_lexicon=combined.lex
kaldi_data_folder=$output_project/kaldi
kaldi_dict_folder=$kaldi_data_folder/dict
kaldi_lang_aux_folder=$kaldi_data_folder/lang-aux
kaldi_lang_folder=$kaldi_data_folder/lang
kaldi_lm_folder=$kaldi_data_folder/lm
kaldi_arpa=$kaldi_lm_folder/arpatrain.gz
ngram=4
kaldi_data_train_folder=$output_project/kaldi/data/train
mfccdir=$kaldi_data_train_folder/mfcc
feats_nj=10 # do not increase this value
train_cmd=run.pl
###############################################################################

echo "Running: uber_custom_models.sh"

if [ $stage -le 1 ]; then
    echo
    echo $(date)
    echo "*+= Stage 1. Split all audio/ctm files in a folder into sentence-based files, based on ctm transcription files."
    echo
    echo "*+= 1.1 First convert audio files in a proper and standard format (SOX)"
    echo "*+= 1.2 Second split audio files and delete temporary converted source files"
    rm -rf $abs_output_audio_splitted $abs_output_audio_splitted_aux && mkdir -p $abs_output_audio_splitted $abs_output_audio_splitted_aux
    for i in $wav_source/*.wav; do
        [ -f "$i" ] || break
        filename=$(basename -- "$i")
        #extension="${filename##*.}"
        filename="${filename%.*}"
        aux_new_path=$abs_output_audio_splitted_aux/$filename.wav
        sox $i -r 16000 -c 1 -b 16 -e signed-integer $aux_new_path > /dev/null 2>&1

        python3 $ctmator/splitaudioctm.py $aux_new_path $ctm_source/$filename.ctm . $abs_output_audio_splitted $abs_ctm_splitted
    done
    # We do not want duplicates
    rm -rf $abs_output_audio_splitted_aux
fi

if [ $stage -le 2 ]; then
    echo
    echo $(date)
    echo "*+= Stage 2. Custom Kaldi data/dict Folders"        
    rm -rf $kaldi_data_folder $kaldi_dict_folder && mkdir -p $kaldi_data_folder $kaldi_dict_folder
    
    echo
    echo $(date)
    echo "*+= Stage 2.1 Data folder"
    ####TODO-TEST####ctm_test=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi/egs/kaldi_egs_CGN/s5/homed/ctm_test
    ####TODO-TEST####python3 $ctmator/speech2kaldi_suffixes.py $kaldi_data_folder $abs_output_audio_splitted $ctm_test $lexiconator
    python3 $ctmator/speech2kaldi_suffixes.py $kaldi_data_folder $abs_output_audio_splitted $abs_ctm_splitted $lexiconator
    utils/spk2utt_to_utt2spk.pl $kaldi_data_folder/spk2utt > $kaldi_data_folder/utt2spk
    utils/validate_data_dir.sh  $kaldi_data_folder/ --no-feats
    
    echo
    echo $(date)
    echo "*+= Stage 2.2 Dict folder"
    python3 $ctmator/dict2kaldi.py $kaldi_dict_folder $kaldi_data_folder $lexiconator $USER_WS $PWD_WS
    utils/validate_dict_dir.pl  $kaldi_dict_folder/

fi


if [ $stage -le 3 ]; then    
    echo
    echo $(date)
    echo "*+= Stage 3. We need a unique lexicon which combines CGN + custom data from all .ctm files"
    python3 $ctmator/merge_lex.py $output_project/../wordlists/lexicon.txt $kaldi_dict_folder/lexicon.txt $kaldi_dict_folder/$final_combined_lexicon
fi

if [ $stage -le 4 ]; then    
    echo
    echo $(date)
    echo "*+= Stage 4. Language model preparation and elaboration"
    rm -rf $kaldi_lang_folder $kaldi_lang_aux_folder
    utils/prepare_lang.sh "$kaldi_dict_folder" "<unk>" "$kaldi_lang_aux_folder" "$kaldi_lang_folder"  || exit 1

	rm -rf $kaldi_lm_folder && mkdir -p $kaldi_lm_folder
    export  PATH=$PATH:$srilm   || exit 
	# -text textfile Generate N-gram counts from text file. textfile should contain one sentence unit per line. Begin/end sentence tokens are added if not already present. Empty lines are ignored.
	# Format: same file as text but whithout speakers id, just transcriptions
	# -vocab file Read a vocabulary from file. Subsequently, out-of-vocabulary words in both counts or text are replaced with the unknown-word token. If this option is not specified all words found are implicitly added to the vocabulary.
	# Format: First 3 lines </s> <s> <sil> + one word per line without repetition. Just orth. trans.
	# Used Witten-Bell smoothing, for small vocab	
	ngram-count -interpolate -text $kaldi_data_folder/textForLM -vocab $kaldi_dict_folder/wordlist -order $ngram -unk -sort -wbdiscount -lm $kaldi_arpa   || exit 1
	###read  -n 1 -p "--> Waiting for $arpa_train: " mainmenuinput
	echo '-> 4.1 Gzip LM...'
	gzip -dk $kaldi_arpa   


fi


if [ $stage -le 5 ]; then
    echo
    echo $(date)
    echo "*+= Stage 5. Feature extraction"
    
    echo '-> 5.1 Format_data LM...'
    rm -rf $kaldi_data_train_folder
    local/format_data.sh $kaldi_data_train_folder $kaldi_lang_folder $kaldi_arpa $kaldi_data_folder || exit 1

    echo "-> 5.2 Sanity check '$kaldi_data_train_folder'"
    utils/fix_data_dir.sh $kaldi_data_train_folder  ||  exit 1

    echo '-> 5.3 Feature extraction make_mfcc'
    x=train
    exp_mfcc=$mfccdir/log
    rm -rf $mfccdir $exp_mfcc
    utils/fix_data_dir.sh  $kaldi_data_train_folder
    echo
    
    steps/make_mfcc.sh --nj $feats_nj --cmd "$train_cmd" $kaldi_data_train_folder $exp_mfcc $mfccdir
    echo
    echo '-> 5.3 Feature extraction compute_cmvn_stats'
	steps/compute_cmvn_stats.sh $kaldi_data_train_folder $exp_mfcc $mfccdir
fi


echo
echo "*+= Finished correctly: uber_custom_models.sh"
echo $(date)