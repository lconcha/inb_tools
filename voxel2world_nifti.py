#!/usr/bin/python

import sys
import argparse

parser = argparse.ArgumentParser(description='Convert voxel to world coordinates.')
parser.add_argument('--voxel',    help='mtrix track file (.tck)',
                                   dest='voxel')
parser.add_argument('--image',     help='Image filename (.nii[.gz])',
                                   dest='s_image_file')
parser.add_argument('--trackvis',  help='trackvis track file (.trk)',
                                   dest='s_out_file')
args = parser.parse_args()

 

print '  Voxel coordinate is {}'.format( args.voxel )
print '  Image file is {}'.format( args.s_image_file )


#import nipype.interfaces.mrtrix as mrt
#tck2trk 			= mrt.MRTrix2TrackVis()
#tck2trk.inputs.in_file 		= args.s_infile
#tck2trk.inputs.image_file 	= args.s_image_file
#tck2trk.run(out_filename = args.s_out_file)  





print """
  I have Finished
  """	