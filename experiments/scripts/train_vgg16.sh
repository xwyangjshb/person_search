#!/usr/bin/env bash
# Usage:
# ./experiments/scripts/train.sh GPU [options args to {train,test}_net.py]
#
# Example:
# ./experiments/scripts/train.sh 0 \
#   --set EXP_DIR foobar RNG_SEED 42 TRAIN.SCALES "[400, 500, 600, 700]"

set -x
set -e

export PYTHONUNBUFFERED="True"

GPU_ID=$1
NET=VGG16
DATASET=psdb

array=( $@ )
len=${#array[@]}
EXTRA_ARGS=${array[@]:1:$len}
EXTRA_ARGS_SLUG=${EXTRA_ARGS// /_}

case $DATASET in
  psdb)
    TRAIN_IMDB="psdb_train"
    TEST_IMDB="psdb_test"
    PT_DIR="psdb"
    ITERS=50000
    ;;
  *)
    echo "No dataset given"
    exit
    ;;
esac

LOG="experiments/logs/${DATASET}_train_${NET}_${EXTRA_ARGS_SLUG}.txt.`date +'%Y-%m-%d_%H-%M-%S'`"
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

time mpirun -n 8 python2 tools/train_net.py --gpu ${GPU_ID} \
  --solver models/${PT_DIR}/${NET}/solver.prototxt \
  --snapshot output/psdb_train/VGG16_matching_trial_1/VGG16_iter_30000.solverstate \
  --weights data/imagenet_models/${NET}.v2.caffemodel \
  --imdb ${TRAIN_IMDB} \
  --iters ${ITERS} \
  --cfg experiments/cfgs/train_vgg16.yml \
  --rand \
  ${EXTRA_ARGS}

set +x
NET_FINAL=`grep -B 1 "done solving" ${LOG} | grep "Wrote snapshot" | awk '{print $4}'`
set -x
