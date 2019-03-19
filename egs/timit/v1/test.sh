#!/bin/bash


. ./cmd.sh
[ -f path.sh ] && . ./path.sh
set -e


echo ============================================================================
echo "         MFCC Feature Extration for Test set          "
echo ============================================================================
for x in test unknown;do
	# Now make MFCC features.
	mfccdir=mfcc

	steps/make_mfcc.sh --cmd "$train_cmd" --nj 4 data/$x exp/make_mfcc/$x $mfccdir

	utils/fix_data_dir.sh data/$x

	echo ============================================================================
	echo "         VAD and MAP adaption          "
	echo ============================================================================

	vaddir=mfcc
	# Energy based VAD
	local/compute_vad_decision.sh --nj 1 --cmd "$train_cmd" data/$x exp/make_vad $vaddir 

	utils/fix_data_dir.sh data/$x
done
#split the test to enroll and eval
mkdir -p data/test/enroll data/test/eval
cp data/test/{spk2utt,feats.scp,vad.scp} data/test/enroll
cp data/test/{spk2utt,feats.scp,vad.scp} data/test/eval
local/split_data_enroll_eval.py data/test/utt2spk  data/test/enroll/utt2spk  data/test/eval/utt2spk
trials=data/test/timit_speaker_ver.lst
local/produce_trials.py data/test/eval/utt2spk $trials
utils/fix_data_dir.sh data/test/enroll
utils/fix_data_dir.sh data/test/eval

# MAP adaption(enroll)
local/ubm_map_adapt.sh exp/diag_ubm data/test/enroll exp/spk_gmm

rm -rf exp/score
#score
local/score.sh exp/spk_gmm data/test/eval exp/score





  


