#!/bin/bash

# Copyright   2012  Johns Hopkins University (Author: Daniel Povey)
#             2013  Daniel Povey
#             2014  David Snyder
# Apache 2.0.

# This is a modified version of steps/train_diag_ubm.sh, specialized for
# speaker-id, that does not require to start with a trained model, that applies
# sliding-window CMVN, and that expects voice activity detection (vad.scp) in
# the data directory.  We initialize the GMM using gmm-global-init-from-feats,
# which sets the means to random data points and then does some iterations of
# E-M in memory.  After the in-memory initialization we train for a few
# iterations in parallel.


# Begin configuration section.
cmd=run.pl

stage=-2
num_gselect=30 # Number of Gaussian-selection indices to use while training
               # the model.
subsample=5 # subsample all features with this periodicity, in the main E-M phase.
cleanup=true
mean_tau=16 # Tau value for updating means.
variance_tau=50 # Tau value for updating variances 
weight_tau=16  # Tau value for updating weights.
delta_window=3
delta_order=2
apply_cmn=true # If true, apply sliding window cepstral mean normalization
update_flags="mvw" #Which GMM parameters will be updated: subset of mvw.
                
# End configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;


if [ $# != 3 ]; then
  echo "Usage: $0  <model-in-dir> <data-dir> <model-out-dir>"
  echo " e.g.: $0 exp/diag_ubm data/test/enroll exp/spk_gmm"
  echo "Options: "
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo " --subsample <n|5>                                 # In main E-M phase, use every n"
  echo "                                                   # frames (a speedup)"
  echo "  --stage <stage|-2>                               # stage to do partial re-run from."
  echo " --delta-window <n|3>                              # number of frames of context used to"
  echo "                                                   # calculate delta"
  echo " --delta-order <n|2>                               # number of delta features"
  echo " --apply-cmn <true,false|true>                     # if true, apply sliding window cepstral mean"
  echo "                                                   # normalization to features"
  echo " --mean-tau <n|16>                                 # Tau value for updating means"
  echo " --update-flags <m|mvw>                            # which GMM parameters will be updated" 
  exit 1;
fi

ubm=$1
data=$2
dir=$3

for f in $data/feats.scp $data/vad.scp $data/spk2utt; do
   [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1
done

for spk in `cat $data/spk2utt | awk '{print $1}'`;do

  mkdir -p $dir/log $data/$spk
  for x in feats.scp vad.scp spk2utt utt2spk;do
    grep "$spk" $data/$x > $data/$spk/$x
  done

delta_opts="--delta-window=$delta_window --delta-order=$delta_order"
echo $delta_opts > $dir/delta_opts

if $apply_cmn; then
  feats="ark,s,cs:add-deltas $delta_opts scp:$data/$spk/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 ark:- ark:- | select-voiced-frames ark:- scp,s,cs:$data/$spk/vad.scp ark:- | subsample-feats --n=$subsample ark:- ark:- |"
else
  feats="ark,s,cs:add-deltas $delta_opts scp:$data/$spk/feats.scp ark:- | select-voiced-frames ark:- scp,s,cs:$data/$spk/vad.scp ark:- | subsample-feats --n=$subsample ark:- ark:- |"
fi

# # Store Gaussian selection indices on disk-- this speeds up the training passes.
# if [ $stage -le -2 ]; then
#   echo Getting Gaussian-selection info
#   $cmd $dir/log/gselect.$spk.log \
#     gmm-gselect --n=$num_gselect $ubm/final.dubm "$feats" \
#       "ark:|gzip -c >$dir/gselect.$spk.gz" || exit 1;
# fi

# if [ $stage -le -1 ]; then
# # Accumulate stats.
#   $cmd $dir/log/acc.$spk.log \
#     gmm-global-acc-stats "--gselect=ark,s,cs:gunzip -c $dir/gselect.$spk.gz|" \
#     $ubm/final.dubm "$feats" $dir/$spk.acc || exit 1;
#   $cmd $dir/log/update.$spk.log \
#     gmm-global-est-map --mean-tau=$mean_tau --update-flags=$update_flags $ubm/final.dubm $dir/$spk.acc $dir/$spk.dgmm || exit 1;
#   $cleanup && rm $dir/$spk.acc 
# fi 

# $cleanup && rm $dir/gselect.$spk.gz

# Accumulate stats.
  $cmd $dir/log/acc.$spk.log \
    gmm-global-acc-stats $ubm/final.dubm "$feats" $dir/$spk.acc || exit 1;
  $cmd $dir/log/update.$spk.log \
    gmm-global-est-map --mean-tau=$mean_tau --weight-tau=$weight_tau --update-flags=$update_flags $ubm/final.dubm $dir/$spk.acc $dir/$spk.dgmm || exit 1;
  $cleanup && rm $dir/$spk.acc 


done
echo "Finish MAP Adaption"
