#!/usr/bin/env bash

### Preprocessing WAV/CTM files for Kaldi data preparation and feature extraction
# INPUT (same filenames, different extension):
# 1. wav folder: wav_source
# 2. ctm folder: ctm_source
#
# OUTPUT: $output_project folder
# 1. Kaldi folder with all preprocessed data
# 2. Feature files
#
# DEPENDENCIES:
# 1. Kaldi installed on $KALDI_ROOT
# 2. Network connection
# 3. Credentials of: https://webservices.cls.ru.nl/
# 4. LaMachine environment activated
# 5. Other repositories (see local/check_repositories.sh):
# 5.1. https://github.com/cristiantg/lexiconator
# 5.2. https://github.com/cristiantg/ctmator
# 5.3. https://github.com/cristiantg/check_duration_audio_files
# 5.4. SRILM (Kaldi)
#
# RUN: 
# Set first the values of $stage and $substage:
# stage=0 && substage=1 --> #-# We extract all single words from the CTM files #-#
# stage=0 && substage=2 --> #-# We prepare a lexicon file from a G2P tool #-#
# stage=1 && substage=1 --> #-# Kaldi data folder #-#
# stage=5 && substage=1 --> #-# LM preparation #-#
#
# nohup time ./uber_custom_models.sh &
# tail -f nohup.out
echo "Running: uber_custom_models.sh"

###############################################################################
# Change the values of the following variables:
###############################################################################
stage=0 # Values: [0,5]
substage=1 # Values: [1,2]
wav_source=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi_nl/homed_wav
ctm_source=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi_nl/ctmator/ref_original
KALDI_ROOT=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi
# Path to the local file to the lexicon. Keep empty: lexicon_path= in order to use the standard G2P/WS tool.
#lexicon_path=
lexicon_path=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi/egs/kaldi_egs_CGN/s5/homed/extracted-words/results-final/lexicon.txt
output_project=/vol/tensusers4/ctejedor/lanewcristianmachine/opt/kaldi/egs/kaldi_egs_CGN/s5/homed
USER_WS=<CHANGE> # Credentials of: https://webservices.cls.ru.nl/
PWD_WS=<CHANGE> # Credentials of: https://webservices.cls.ru.nl/
[ ! -d $wav_source ] || [ ! -d $ctm_source ] || [ ! -d $KALDI_ROOT ] && echo "ERROR: WAV/CTM/KALDI paths do not exist." && exit 2

REPOS_FOLDER=$KALDI_ROOT/egs/kaldi_egs_CGN/s5/repos
## Uncomment the following single line if you have network access:
## local/check_repositories.sh $REPOS_FOLDER $KALDI_ROOT/tools
    lexiconator=$REPOS_FOLDER/lexiconator
    ctmator=$REPOS_FOLDER/ctmator
    check_dur=$REPOS_FOLDER/check_duration_audio_files
    srilm=$KALDI_ROOT/tools/srilm/bin/i686-m64
[ ! -d $lexiconator ] || [ ! -d $ctmator ] || [ ! -d $check_dur ] || [ ! -d $srilm ] && echo "ERROR: The repositories do not exit on the specified path." && exit 2
###############################################################################
###############################################################################




###############################################################################
# Optional:
###############################################################################
kaldi_data_folder=$output_project/kaldi
extracted_words_folder=$output_project/extracted-words
sox_bitrate=16000
sox_channels=1
sox_bits=16
sox_encoding=signed-integer
output_audio_splitted=audio_split
abs_output_audio_splitted=$output_project/$output_audio_splitted
abs_output_audio_splitted_aux=$abs_output_audio_splitted/aux
output_ctm_splitted=ctm_split
abs_ctm_splitted=$output_project/$output_ctm_splitted
lexiconator_pre_lexicon=$lexiconator/input
final_combined_lexicon=lexicon-combined.txt
kaldi_cgn_lexicon=$output_project/../wordlists/lexicon.txt
kaldi_dict_folder=$kaldi_data_folder/dict
kaldi_lang_aux_folder=$kaldi_data_folder/lang-aux
kaldi_lang_folder=$kaldi_data_folder/lang
kaldi_lm_folder=$kaldi_data_folder/lm
kaldi_arpa=$kaldi_lm_folder/arpatrain.gz
ngram=4
kaldi_data_train_folder=$kaldi_data_folder/data/train
mfccdir=$kaldi_data_train_folder/mfcc
feats_nj=10 # do not increase this value
train_cmd=run.pl
mkdir -p $output_project $kaldi_data_folder
###############################################################################

# Prepare a local lexicon file from a G2P tool. This step can be skipped.
if [ $stage -le 0 ]; then
    echo
    echo $(date)
    #-# Run on: NO-INTERNET-PC
    if [ $substage -le 1 ]; then
        echo "*+= Stage 0.1 Extract all possible words from CTM files in a folder"    
        python3 $ctmator/extractCtmWords.py $ctm_source $extracted_words_folder
        echo "*+= Stage 0.1 Finished correctly"
        echo
        echo $(date)
        exit 0
    fi
    #-# Run on: CLST-cluster
    if [ $substage -le 2 ]; then
        echo "*+= Stage 0.2 Generate a local lexicon file from a G2P tool"
        echo "*+= Stage 0.2 Finished correctly"
        output_folder=$extracted_words_folder/input
        python3 $lexiconator/utils/preparing_raw_data.py $extracted_words_folder $output_folder
        python3 $lexiconator/uber_script.py $USER_WS $PWD_WS $lexiconator 1 1 "<unk><TAB>[SPN]" $output_folder/wordlist $extracted_words_folder
        echo "The local lexicon file is on: $extracted_words_folder/results-final/lexicon.txt"
        echo
        echo $(date)
        exit 0
    fi
fi


#-# Run on: NO-INTERNET-PC
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
        sox $i -r $sox_bitrate -c $sox_channels -b $sox_bits -e $sox_encoding $aux_new_path > /dev/null 2>&1

        python3 $ctmator/splitaudioctm.py $aux_new_path $ctm_source/$filename.ctm . $abs_output_audio_splitted $abs_ctm_splitted
    done
    # We do not want duplicates
    rm -rf $abs_output_audio_splitted_aux

    # Check duration
    $check_dur/get_duration.sh $abs_output_audio_splitted *.wav $kaldi_data_folder/audio_split_files_duration.txt
fi


# You need a valid Kaldi environment:
. ./cmd.sh || exit 2
[ -f path.sh ] && . ./path.sh || exit 2
[ ! -d "utils" ] && ln -s $KALDI_ROOT/egs/wsj/s5/utils/ utils
[ ! -d "steps" ] && ln -s $KALDI_ROOT/egs/wsj/s5/steps/ steps

#-# Run on: NO-INTERNET-PC
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
    
    if [ -z "$lexicon_path" ]
    then
        echo "2.2.a -> No lexicon file specified, the G2P tool wil be used."
        lexicon_path=AAfake_path123 
    else
        echo "2.2.b -> Local lexicon file specified: $lexicon_path"
    fi

    python3 $ctmator/dict2kaldi.py $kaldi_dict_folder $kaldi_data_folder $lexiconator $USER_WS $PWD_WS $lexicon_path     
    utils/validate_dict_dir.pl $kaldi_dict_folder/    
fi

#-# Run on: NO-INTERNET-PC
if [ $stage -le 3 ]; then    
    echo
    echo $(date)
    echo "*+= Stage 3. We need a unique lexicon which combines CGN + custom data from all .ctm files"
    aux_output_lexicon=$kaldi_dict_folder/lexicon.txt    
    ####### kaldi_dict_lexicon_temp=$kaldi_dict_folder/lexicon_custom.txt
    ####### mv $aux_output_lexicon $kaldi_dict_lexicon_temp
    ####### aux_output_lexicon=$kaldi_dict_lexicon_temp
    python3 $ctmator/merge_lex.py $kaldi_cgn_lexicon $aux_output_lexicon $kaldi_dict_folder/$final_combined_lexicon
fi

#-# Run on: NO-INTERNET-PC
if [ $stage -le 4 ]; then
    echo
    echo $(date)
    echo "*+= Stage 4. Feature extraction"
    
    echo '-> 4.1 Format_data LM...'
    rm -rf $kaldi_data_train_folder $kaldi_lang_folder
    local/format_data.sh $kaldi_data_train_folder $kaldi_lang_folder $kaldi_arpa $kaldi_data_folder || exit 1

    echo "-> 4.2 Sanity check '$kaldi_data_train_folder'"
    utils/fix_data_dir.sh $kaldi_data_train_folder  ||  exit 1

    echo "-> 4.3 Prepare lang "
    rm -rf $kaldi_lang_aux_folder
    utils/prepare_lang.sh "$kaldi_dict_folder" "<unk>" "$kaldi_lang_aux_folder" "$kaldi_lang_folder"  || exit 1

    echo '-> 4.4 Feature extraction make_mfcc'
    x=train
    exp_mfcc=$mfccdir/log
    rm -rf $mfccdir $exp_mfcc
    utils/fix_data_dir.sh  $kaldi_data_train_folder
    echo
    
    steps/make_mfcc.sh --nj $feats_nj --cmd "$train_cmd" $kaldi_data_train_folder $exp_mfcc $mfccdir
    echo
    echo '-> 4.5 Feature extraction compute_cmvn_stats'
	steps/compute_cmvn_stats.sh $kaldi_data_train_folder $exp_mfcc $mfccdir

    echo "Let op!: All scp files contain aboslute paths to the files. Please manually modify the paths accordingly when training your models. "
    echo "You must also create a reco2dur file for the DNN training with the id of the (split file) and teh duration in seconds"
    exit 0
fi


#-# Run on: CLST-cluster
if [ $stage -le 5 ]; then    
    echo
    echo $(date)
    echo "*+= Stage 5. Language model preparation and elaboration"
    
    echo '-> 5.1 LM building...'
	rm -rf $kaldi_lm_folder && mkdir -p $kaldi_lm_folder
    export  PATH=$PATH:$srilm   || exit 
	# -text textfile Generate N-gram counts from text file. textfile should contain one sentence unit per line. Begin/end sentence tokens are added if not already present. Empty lines are ignored.
	# Format: same file as text but whithout speakers id, just transcriptions
	# -vocab file Read a vocabulary from file. Subsequently, out-of-vocabulary words in both counts or text are replaced with the unknown-word token. If this option is not specified all words found are implicitly added to the vocabulary.
	# Format: First 3 lines </s> <s> <sil> + one word per line without repetition. Just orth. trans.
	# Used Witten-Bell smoothing, for small vocab	
	ngram-count -interpolate -text $kaldi_data_folder/textForLM -vocab $kaldi_dict_folder/wordlist -order $ngram -unk -sort -wbdiscount -lm $kaldi_arpa   || exit 1
	###read  -n 1 -p "--> Waiting for $arpa_train: " mainmenuinput
	
    echo
    echo '-> 5.2 Gzip LM...'
	gzip -dk $kaldi_arpa

    # Check lm
    echo
    echo '-> 5.3 Check LM...'
    local/format_data.sh $kaldi_data_train_folder $kaldi_lang_folder $kaldi_arpa $kaldi_data_folder || exit 1
fi


echo
echo "*+= Finished correctly: uber_custom_models.sh"
echo $(date)
