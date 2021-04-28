#!/usr/bin/env bash

# Decodes a single audio file in real-time

# run: ./uber_single.sh input_folder input_file_name output_folder output_file_name spk_id
# example: ./uber_single.sh raw_data/other bird.wav output2/other bird speaker
# optimized: ./uber_single.sh raw_data/other bird.wav output2/other bird speaker > somefile 2>&1


# 1. Prepare environment
. cmd.sh
. path.sh


# 2. Prepare configuration
# 
# 2.1 Your models must be prepared beforehand:
# steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf data/lang_chain exp/nnet3_cleaned/extractor exp/chain_cleaned/tdnn1a_sp_bi exp/tdnn1a_sp_bi_online
# utils/mkgraph.sh --self-loop-scale 1.0 data/lang_s_test_tgpr exp/tdnn1a_sp_bi_online exp/tdnn1a_sp_bi_online/graph_s
#
# 2.2 Be sure your wav file is in the correct format:
# sox source_data/spk001/bird_original.wav -r 16000 -c 1 -b 16 raw_data/spk001/bird.wav
#
# 2.3 Variables
#input_folder="raw_data/other"
input_folder=$1
#input_file_name="bird.wav"
input_file_name=$2
#output_folder="output2/other"
output_folder=$3
#output_file_name="bird"
output_file_name=$4
#spk_id="speaker"
spk_id=$5


# 3. Decoding the audio file
mkdir -p $output_folder
audio_file="${input_folder}/${input_file_name}"
if [ -f "$audio_file" ]; then
    
    utt=$input_file_name
    m_bestsym="${output_file_name}_1bestsym.ctm"

    online2-wav-nnet3-latgen-faster \
    --online=false \
    --do-endpointing=false \
    --frame-subsampling-factor=3 \
    --config=exp/tdnn1a_sp_bi_online/conf/online.conf \
    --max-active=7000 \
    --beam=15.0 \
    --lattice-beam=6.0 \
    --acoustic-scale=1.0 \
    --word-symbol-table=exp/tdnn1a_sp_bi_online/graph_s/words.txt \
    exp/tdnn1a_sp_bi_online/final.mdl \
    exp/tdnn1a_sp_bi_online/graph_s/HCLG.fst \
    'ark:echo '$spk_id' '$utt'|' \
    'scp:echo '$utt' '$audio_file'|' \
    ark:- | lattice-to-ctm-conf ark:- $output_folder/$m_bestsym
                
    utils/int2sym.pl -f 5 exp/tdnn1a_sp_bi_online/graph_s/words.txt $output_folder/$m_bestsym > $output_folder/$output_file_name
fi