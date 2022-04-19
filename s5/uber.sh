#!/usr/bin/env bash
# Decodes all audio files in a root path in real-time. The root path must only
# contain subfolders (speakers) and these subfolders must contain audio files.

if [ $# -lt 5 ]; 
then
  echo "Please add 5 parameters: the output folder path of the decoding call; HCLG folder; mdl folder; conf folder; audio files root folder"
  echo "Example 1: $0 output exp/tdnn1a_sp_bi_online/graph_s exp/tdnn1a_sp_bi_online exp/tdnn1a_sp_bi_online/conf raw_data"
  echo "Example 2: nohup time $0 output exp/tdnn1a_sp_bi_online/graph_s exp/tdnn1a_sp_bi_online exp/tdnn1a_sp_bi_online/conf raw_data &"
  exit -2
else 


# 1. Prepare environment
. cmd.sh
. path.sh

# 2. Prepare configuration
#
# steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf data/lang_chain exp/nnet3_cleaned/extractor exp/chain_cleaned/tdnn1a_sp_bi exp/tdnn1a_sp_bi_online
# utils/mkgraph.sh --self-loop-scale 1.0 data/lang_s_test_tgpr exp/tdnn1a_sp_bi_online exp/tdnn1a_sp_bi_online/graph_s
#
# Be sure your wav files are in the correct format:
# a) One by one:
# sox source_data/spk001/bird_original.wav -r 16000 -c 1 -b 16 raw_data/spk001/bird.wav
# b) All files at the same time
# cd source_data/spk001
# for i in *.wav; do sox "$i" -r 16000 -c 1 -b 16 ../../raw_data/spk001/"$i"; done
#
# Must be a root folder with subdirectories
# nohup time ./uber.sh &
raw_folder="$5"
audio_file_ext=".wav"
graph_s="$2"
model_s="$3"
conf_s="$4"
#m_output="output"
m_output="$1"
mkdir -p $m_output
echo "*** Run: m_output=$m_output"


# 3. Main loop
spk_counter=0
utt_counter=0
for f in ${raw_folder}/*; do
    echo $f
    if [ -d "$f" ]; then
        spk="${f//$raw_folder/""}"
        ((spk_counter=spk_counter+1))
        echo -e "\nSPEAKER (${spk_counter}): ${spk}"        
        for m_file in ${f}/*; do
            if [ -f "$m_file" ] && [ ${m_file: -${#audio_file_ext}} == $audio_file_ext ]; then
                start=`date +%s`
                aux=${f}/
                utt_full="${m_file//$aux/""}"
                utt="${utt_full%.*}"
                ((utt_counter=utt_counter+1))
                echo -e "\n - UTT (${utt_counter}): ${utt_full}"
                audio_file="${raw_folder}${spk}/${utt_full}"

                # 3. Decode a wav file
                m_bestsym="${spk}_${utt}_1bestsym.ctm"
                #m_best="${spk}_${utt}_1best.ctm"
                m_bestsym="${utt}_1bestsym.ctm"                
                m_best="${utt}.ctm"


                online2-wav-nnet3-latgen-faster \
                --online=false \
                --do-endpointing=false \
                --frame-subsampling-factor=3 \
                --config=$conf_s/online.conf \
                --max-active=7000 \
                --beam=20.0 \
                --lattice-beam=7.0 \
                --acoustic-scale=1.0 \
                --word-symbol-table=$graph_s/words.txt \
                $model_s/final.mdl \
                $graph_s/HCLG.fst \
                'ark:echo '$spk' '$utt'|' \
                'scp:echo '$utt' '$audio_file'|' \
                ark:- | lattice-to-ctm-conf ark:- $m_output/$m_bestsym                
                # Do not add parameters like inv-scale etc, it does not work at all.

                utils/int2sym.pl -f 5 $graph_s/words.txt $m_output/$m_bestsym  > $m_output/$m_best

                end=`date +%s`
                runtime=$((end-start))
                echo -e "\n - UTT (${utt_counter}): ${utt_full}, time: ${runtime} seconds\n"
            fi
        done
    fi
    echo " --> SPEAKER (${spk_counter}): ${utt_counter} utterances"  
done
echo -e "\nTotal processed - speakers: ${spk_counter}, audio files  ${utt_counter}." 
fi