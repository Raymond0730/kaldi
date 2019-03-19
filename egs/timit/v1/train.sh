#!/bin/bash


. ./cmd.sh
[ -f path.sh ] && . ./path.sh
set -e



echo ============================================================================
echo "         MFCC Feature Extration for Training set          "
echo ============================================================================

# Now make MFCC features.
mfccdir=mfcc

steps/make_mfcc.sh --cmd "$train_cmd" --nj 4 data/train exp/make_mfcc/train $mfccdir

utils/fix_data_dir.sh data/train

echo ============================================================================
echo "         VAD and UBM Training          "
echo ============================================================================

vaddir=mfcc
# Energy based VAD
local/compute_vad_decision.sh --nj 4 --cmd "$train_cmd" data/train exp/make_vad $vaddir 

utils/fix_data_dir.sh data/train

num_components=16
rm -rf exp/diag_ubm
local/train_diag_ubm.sh --cmd "$train_cmd" --nj 4 --num-threads 8 data/train $num_components exp/diag_ubm

#local/ubm_test.py exp/ubm_test exp/ubm_test/ubm_test
  


