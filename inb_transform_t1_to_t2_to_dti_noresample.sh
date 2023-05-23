#!/bin/bash
source ~/noelsoft/BashTools/my_do_cmd

# Another version of image fusion for Dr Velasco's pipeline

# ALL IMAGES MUST BE BRAIN EXTRACTED
# the -f for t1 is good at 0.5
#            t2            0.3
#            t2hires       0.2

t1=$1
t2=$2
b0=$3
outbase=$4




xfm_b0_to_t2=${outbase}_b0_to_t2.xfm
xfm_t2_to_b0=${outbase}_t2_to_b0.xfm
xfm_t1_to_t2=${outbase}_t1_to_t2.xfm
xfm_t2_to_t1=${outbase}_t2_to_t1.xfm
xfm_t1_to_b0=${outbase}_t1_to_b0.xfm
xfm_b0_to_t1=${outbase}_b0_to_t1.xfm


tfm_t2_to_b0=${outbase}_t2_to_b0.mnc
tfm_t1_to_b0=${outbase}_t1_to_b0.mnc

# T2 to B0
my_do_cmd minctracc -lsq12 -nmi $b0 $t2 $xfm_b0_to_t2
my_do_cmd xfminvert $xfm_b0_to_t2 $xfm_t2_to_b0
my_do_cmd mincresample -transform $xfm_t2_to_b0 -tfm_input_sampling $t2 $tfm_t2_to_b0

# T2 to T1
my_do_cmd minctracc -lsq12 -nmi $t2 $t1 $xfm_t2_to_t1
my_do_cmd xfminvert $xfm_t2_to_t1 $xfm_t1_to_t2

# concatenate xfms
my_do_cmd xfmconcat $xfm_t1_to_t2 $xfm_t2_to_b0 $xfm_t1_to_b0
my_do_cmd xfminvert $xfm_t1_to_b0 $xfm_b0_to_t1
my_do_cmd mincresample -transform $xfm_t1_to_b0 -tfm_input_sampling $t1 $tfm_t1_to_b0