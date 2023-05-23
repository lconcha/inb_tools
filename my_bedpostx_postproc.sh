#!/bin/sh

my_do_cmd() 
{

  ifFake=""
   local l_command=""
   local l_sep=""
   local l_index=1
   while [ ${l_index} -le $# ]; do
   eval arg=\${$l_index}
    if [ "$arg" = "-fake" ]
    then
      isFake=1
      arg=""
    fi
   l_command="${l_command}${l_sep}${arg}"
   l_sep=" "
   l_index=$[${l_index}+1]
   done
   echo "  --> ${log_header} ${l_command}"


  if [ -z $isFake ]
  then
    $l_command
  fi
}



subjdir=$1
echo subjdir is $subjdir

numfib=`${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_0000/f*samples* | wc -w | awk '{print $1}'`
echo numfib is $numfib

if [ `${FSLDIR}/bin/imtest ${subjdir}.bedpostX/diff_slices/data_slice_0000/f0samples` -eq 1 ];then
    numfib=$(($numfib - 1))
fi

fib=1
while [ $fib -le $numfib ]
do
    echo $fib
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/merged_th${fib}samples `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/th${fib}samples*`
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/merged_ph${fib}samples `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/ph${fib}samples*`
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/merged_f${fib}samples  `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/f${fib}samples*`
    my_do_cmd ${FSLDIR}/bin/fslmaths ${subjdir}.bedpostX/merged_th${fib}samples -Tmean ${subjdir}.bedpostX/mean_th${fib}samples
    my_do_cmd ${FSLDIR}/bin/fslmaths ${subjdir}.bedpostX/merged_ph${fib}samples -Tmean ${subjdir}.bedpostX/mean_ph${fib}samples
    my_do_cmd ${FSLDIR}/bin/fslmaths ${subjdir}.bedpostX/merged_f${fib}samples -Tmean ${subjdir}.bedpostX/mean_f${fib}samples

    my_do_cmd ${FSLDIR}/bin/make_dyadic_vectors ${subjdir}.bedpostX/merged_th${fib}samples ${subjdir}.bedpostX/merged_ph${fib}samples ${subjdir}.bedpostX/nodif_brain_mask ${subjdir}.bedpostX/dyads${fib}
    fib=$(($fib + 1))

done


if [ `${FSLDIR}/bin/imtest ${subjdir}.bedpostX/diff_slices/data_slice_0000/mean_dsamples` -eq 1 ];then
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/mean_dsamples  `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/mean_dsamples*`
fi

if [ `${FSLDIR}/bin/imtest ${subjdir}.bedpostX/diff_slices/data_slice_0000/mean_d_stdsamples` -eq 1 ];then
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/mean_d_stdsamples  `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/mean_d_stdsamples*`
fi

if [ `${FSLDIR}/bin/imtest ${subjdir}.bedpostX/diff_slices/data_slice_0000/mean_f0samples` -eq 1 ];then
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/mean_f0samples  `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/mean_f0samples*`
fi

if [ `${FSLDIR}/bin/imtest ${subjdir}.bedpostX/diff_slices/data_slice_0000/mean_S0samples` -eq 1 ];then
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/mean_S0samples  `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/mean_S0samples*`
fi

if [ `${FSLDIR}/bin/imtest ${subjdir}.bedpostX/diff_slices/data_slice_0000/mean_tausamples` -eq 1 ];then
    my_do_cmd ${FSLDIR}/bin/fslmerge -z ${subjdir}.bedpostX/mean_tausamples  `${FSLDIR}/bin/imglob ${subjdir}.bedpostX/diff_slices/data_slice_*/mean_tausamples*`
fi


echo Removing intermediate files

if [ `imtest ${subjdir}.bedpostX/merged_th1samples` -eq 1 ];then
  if [ `imtest ${subjdir}.bedpostX/merged_ph1samples` -eq 1 ];then
    if [ `imtest ${subjdir}.bedpostX/merged_f1samples` -eq 1 ];then
      rm -rf ${subjdir}.bedpostX/diff_slices
      rm -f ${subjdir}/data_slice_*
      rm -f ${subjdir}/nodif_brain_mask_slice_*
    fi
  fi
fi

echo Creating identity xfm

xfmdir=${subjdir}.bedpostX/xfms
echo 1 0 0 0 > ${xfmdir}/eye.mat
echo 0 1 0 0 >> ${xfmdir}/eye.mat
echo 0 0 1 0 >> ${xfmdir}/eye.mat
echo 0 0 0 1 >> ${xfmdir}/eye.mat

echo Done
