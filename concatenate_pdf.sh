#!/bin/bash


print_help()
{
echo "
   Concatenate several pdf files into one file.
	$0 <file1.pdf> <file2.pdf> <file_n.pdf> ... <outfile.pdf>
"
exit 1
}


if [ $# -lt 3 ] 
then
    echo "At least 3 arguments are required."
    print_help
fi


filesToConcatenate=""
for arg in "$@"
do
   filesToConcatenate=`echo $filesToConcatenate $arg`
done


lastarg=`expr $#`
eval outFile=\${${lastarg}}

filesToConcatenate=${filesToConcatenate%${outFile}}

echo "Will concatenate:"
echo $filesToConcatenate
echo "end result is: $outFile"


gs -q -sPAPERSIZE=letter -dNOPAUSE -dBATCH \
  -sDEVICE=pdfwrite \
  -sOutputFile=${outFile} \
  $filesToConcatenate
