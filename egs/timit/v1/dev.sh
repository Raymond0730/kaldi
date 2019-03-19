#!/bin/bash


. ./cmd.sh
[ -f path.sh ] && . ./path.sh
set -e


echo ============================================================================
echo "         MFCC Feature Extration for Dev set          "
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc

steps/make_mfcc.sh --cmd "$train_cmd" --nj 4 data/dev exp/make_mfcc/dev $mfccdir

utils/fix_data_dir.sh data/dev

echo ============================================================================
echo "         VAD and MAP adaption          "
echo ============================================================================

vaddir=mfcc
# Energy based VAD
local/compute_vad_decision.sh --nj 4 --cmd "$train_cmd" data/dev exp/make_vad $vaddir 

utils/fix_data_dir.sh data/dev

#split the test to enroll and eval
mkdir -p data/dev/enroll data/dev/eval
cp data/dev/{spk2utt,feats.scp,vad.scp} data/dev/enroll
cp data/dev/{spk2utt,feats.scp,vad.scp} data/dev/eval
local/split_data_enroll_eval.py data/dev/utt2spk  data/dev/enroll/utt2spk  data/dev/eval/utt2spk
trials=data/dev/timit_speaker_ver.lst
local/produce_trials.py data/dev/eval/utt2spk $trials
utils/fix_data_dir.sh data/dev/enroll
utils/fix_data_dir.sh data/dev/eval

# MAP adaption(enroll)
local/ubm_map_adapt.sh exp/diag_ubm data/dev/enroll exp/spk_gmm

rm -rf exp/score
#score
local/score.sh exp/spk_gmm data/dev/eval exp/score





  


