# "queue.pl" uses qsub.  The options to it are
# options to qsub.  If you have GridEngine installed,
# change this to a queue you have access to.
# Otherwise, use "run.pl", which will run jobs locally
# (make sure your --num-jobs options are no more than
# the number of cpus on your machine.i

# hostname=$(hostname)

#if [ "${hostname:0:3}" == "mlp" ]; then 
#echo "running on ponyland mahcines"
#echo "running on $hostname"
#export train_cmd="conf/slurm_pony.pl -p short --time 11:59:00 --mem 4G -x mlp03"
#export ivector_cmd="conf/slurm_pony.pl -p short --time 11:59:00 --mem 4G -x mlp03"
#export align_cmd="conf/slurm_pony.pl -p short --time 11:59:00 --mem 4G -x mlp03"
#export decode_cmd="conf/slurm_pony.pl -p short --time 11:59:00 --mem 10G -x mlp03"
#export mkgraph_cmd="conf/slurm_pony.pl -p short --time 11:59:00 --mem 8G -x mlp03"
#export rnn_cmd="conf/slurm_pony.pl -p short --num-threads 1 --gpu 1 --time 08:59:00 --mem 12G"
#export cuda_cmd="conf/slurm_pony.pl -p short --num-threads 1 --time 00:10:00 --mem 4G"
#
#elif [ "${hostname:0:4}" == "coma" ]; then
#export train_cmd="slurm_coma.pl -p normal --time 11:59:00 --mem 10G"
#export decode_cmd="slurm_coma.pl -p normal --time 00:30:00 --mem 10G"
#export mkgraph_cmd="slurm_coma.pl -p normal --time 01:59:00 --mem 10G"
#export cuda_cmd="slurm_coma.pl -p normal --time 00:30:00 --mem 6G"
#export cuda_cmd="slurm.pl -p long -w "coma13" --time 23:59:00 --mem 6G"
#
#else 
#echo "No squeue or qstat found, running local"

export train_cmd=utils/run.pl
export decode_cmd=utils/run.pl
export cuda_cmd=utils/run.pl
export mkgraph_cmd=utils/run.pl
export align_cmd=utils/run.pl
export ivector_cmd=utils/run.pl

#fi