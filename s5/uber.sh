#!/usr/bin/env bash

# 1. Prepare environment
. cmd.sh
. path.sh


# 2. Prepare configuration
raw_folder="raw_data/"
audio_file_ext=".wav"
m_output="output"
mkdir -p $m_output


# 3. Main loop
spk_counter=0
utt_counter=0
for f in ${raw_folder}*; do
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
                m_best="${spk}_${utt}_1best.ctm"


                online2-wav-nnet3-latgen-faster \
                --online=false \
                --do-endpointing=false \
                --frame-subsampling-factor=3 \
                --config=_runs/run2/exp/tdnn1a_sp_bi_online/conf/online.conf \
                --max-active=7000 \
                --beam=15.0 \
                --lattice-beam=6.0 \
                --acoustic-scale=1.0 \
                --word-symbol-table=_runs/run2/exp/tdnn1a_sp_bi_online/graph_s/words.txt \
                _runs/run2/exp/tdnn1a_sp_bi_online/final.mdl \
                _runs/run2/exp/tdnn1a_sp_bi_online/graph_s/HCLG.fst \
                'ark:echo '$spk' '$utt'|' \
                'scp:echo '$utt' '$audio_file'|' \
                ark:- | lattice-to-ctm-conf ark:- $m_output/$m_bestsym
                
                utils/int2sym.pl -f 5 _runs/run2/exp/tdnn1a_sp_bi_online/graph_s/words.txt $m_output/$m_bestsym  > $m_output/$m_best

                end=`date +%s`
                runtime=$((end-start))
                echo -e "\n - UTT (${utt_counter}): ${utt_full}, time: ${runtime} seconds\n"
            fi
        done
    fi
    echo " --> SPEAKER (${spk_counter}): ${utt_counter} utterances"  
done
echo -e "\nTotal processed - speakers: ${spk_counter}, audio files  ${utt_counter}." 
