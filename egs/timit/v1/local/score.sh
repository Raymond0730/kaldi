#!/bin/bash

delta_window=3
delta_order=2
delta_opts="--delta-window=$delta_window --delta-order=$delta_order"
subsample=5
echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
  echo "Usage: $0  <spk-model-dir> <data-dir> <results-dir>"
  echo " e.g.: $0 exp/spk_gmm data/test/eval exp/score"
  exit 1;
fi

spk_model=$1
data=$2
results=$3
ubm_model=exp/diag_ubm/final.dubm

for f in $data/feats.scp $data/vad.scp $data/spk2utt; do
   [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1
done

# add-deltas,apply cmvn sliding and VAD
add-deltas $delta_opts scp:$data/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 ark:- ark:- | select-voiced-frames ark:- scp,s,cs:$data/vad.scp ark:- | subsample-feats --n=$subsample ark:- ark:$data/feats_tmp.ark

mkdir -p $results

for spk in `cat $data/spk2utt | awk '{print $1}'`;do
	gmm-global-get-frame-likes --average=true $spk_model/$spk.dgmm ark:$data/feats_tmp.ark ark,t:$results/$spk.like
done

gmm-global-get-frame-likes --average=true $ubm_model ark:$data/feats_tmp.ark ark,t:$results/ubm


local/score.py $results $results/score
rm $data/feats_tmp.ark

echo "finish scoring"