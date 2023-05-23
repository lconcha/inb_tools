#!/bin/bash
source `which my_do_cmd`

ref=$1
dest=$2


orient=`fslorient -getorient $ref`
sform=`fslorient  -getsform $ref`
qform=`fslorient  -getqform $ref`
sformcode=`fslorient -getsformcode $ref`
qformcode=`fslorient -getqformcode $ref`


if [[ "$orient" == $RADIOLOGICAL ]]
then
 my_do_cmd fslorient -forceradiological $dest
else
 my_do_cmd fslorient -forceneurological $dest
fi


my_do_cmd fslorient -setsform "$sform" $dest
my_do_cmd fslorient -setqform "$qform" $dest
my_do_cmd fslorient -setsformcode $sformcode $dest
my_do_cmd fslorient -setqformcode $qformcode $dest

