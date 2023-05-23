#!/usr/bin/python

import sys
import argparse
import nipype.interfaces.mrtrix as mrt


parser = argparse.ArgumentParser(description='Convert mrtrix tck files to trackvis trk files.')
parser.add_argument('--mrtrix',    help='mtrix track file (.tck)',
                                   dest='s_infile')
parser.add_argument('--image',     help='Image filename (.nii[.gz])',
                                   dest='s_image_file')
parser.add_argument('--trackvis',  help='trackvis track file (.trk)',
                                   dest='s_out_file')
args = parser.parse_args()



#print '  Infile is {}'.format( args.s_infile )
#print '  Image file is {}'.format( args.s_image_file )
#print '  Output trk file will be {}'.format( args.s_out_file )

print(f' Infile is {format(args.s_infile)}\n')
print(f' Image file is {format(args.s_image_file)}\n')
print(f' Output trk file will be {format(args.s_out_file)}\n')


tck2trk 			= mrt.MRTrix2TrackVis()
tck2trk.inputs.in_file 		= args.s_infile
tck2trk.inputs.image_file 	= args.s_image_file
tck2trk.run(out_filename = args.s_out_file)





print """
  I have Finished
  """
