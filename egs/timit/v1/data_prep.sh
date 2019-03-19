#!/bin/bash


. ./cmd.sh
[ -f path.sh ] && . ./path.sh
set -e


echo ============================================================================
echo "                Data Preparation                "
echo ============================================================================


timit=~/Downloads/timit 

rm -rf data

local/timit_data_prep.sh $timit || exit 1

local/timit_format_data.sh


  


