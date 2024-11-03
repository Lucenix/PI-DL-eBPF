#!/bin/sh

sudo echo 1 > /proc/sys/vm/drop_caches

SCRATCH="/home/gsd/andrelucena"
MAIN_PATH="$SCRATCH/scripts/pytorch/python/main_simple_ult.py"
DSTAT_PATH="$SCRATCH/scripts/pytorch/python/dstat.py"
DATA_DIR="/home/gsd/goncalo/imagenet_subset"
VENV_DIR="$SCRATCH/pytorch_venv"
STAT_DIR="$SCRATCH/statistics/control_subset"
SCREEN_PATH="screen"
# model and save every is defined in main
if [ -z $1 ] ; then
        SAVE_EVERY=1
else
        SAVE_EVERY=$1
fi
if [ -z $2 ] ; then
        MODEL=resnet50
else
        MODEL=$2
fi
if [ -z $3 ] ; then
        N_EPOCHS=2
else
        N_EPOCHS=$3
fi
if [ -z $4 ] ; then
        BATCH_SIZE=64
else
        BATCH_SIZE=$4
fi
if [ -z $5 ] ; then
        LOG=false
else
        LOG=$5
fi

# create statistics directory
mkdir -p $STAT_DIR

#spawn process
# --$1: process identifier
# --$2: path to the output file
spawn_dstat_process () 
{
        echo "utils::spawn_dstat_process"
        $SCREEN_PATH -S $1 -d -m $DSTAT_PATH -tcdrnmg --noheaders --output $2
}

spawn_nvidia_process () 
{
        echo "utils::spawn-nvidia_smi_process"
        $SCREEN_PATH -S $1 -d -m nvidia-smi --query-gpu=timestamp,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv,nounits -f $2 -l 1
}

# Join process
# --$1: process identifier
join_process() 
{
        echo "utils::join_process"
        $SCREEN_PATH -X -S $1 stuff "^C"
}

# activate venv
source "${VENV_DIR}/bin/activate"

# spawn dstat
spawn_dstat_process dstat $STAT_DIR/$MODEL\_$N_EPOCHS\_$BATCH_SIZE\_$SAVE_EVERY\_$LOG.csv
# spawn nvidia
spawn_nvidia_process nvidia $STAT_DIR/$MODEL\_$N_EPOCHS\_$BATCH_SIZE\_$SAVE_EVERY\_$LOG\_gpu.csv

{ time python3 $MAIN_PATH --model $MODEL --epochs $N_EPOCHS --batch_size $BATCH_SIZE --save_every $SAVE_EVERY --enable_log $LOG $DATA_DIR > $STAT_DIR/$MODEL\_$N_EPOCHS\_$BATCH_SIZE\_$SAVE_EVERY\_$LOG.out ; } 2>> $STAT_DIR/$MODEL\_$N_EPOCHS\_$BATCH_SIZE\_$SAVE_EVERY\_$LOG.out ;

# join processes
join_process dstat
join_process nvidia

#python3 ../../dstat.py -cdnm --output ./dstat_arm_output