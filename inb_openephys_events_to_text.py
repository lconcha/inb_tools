#!/home/inb/lconcha/fmrilab_software/inb_anaconda3/bin/python

import numpy
import sys
import argparse
import os

parser = argparse.ArgumentParser(description='Print out the events of an openephys session from a pair of .npy files. These are typically stored inside the experiment/recording/events/Message_Center/TEXT_group folder.',
                                 epilog='LU15 (0N(H4 | September 2021 | lconcha@unam.mx')
parser.add_argument('expfolder', help='Relative or absolute path to experiment folder. Specify the folder up to exeiment?/recording?, and the program will look for the files  timestamps.npy and text.npy inside <expfolder>/events/Message_Center-904.0/TEXT_group_1/.',)
parser.add_argument('--verbose',   help='Verbose output',
                                   action='store_true')
args = parser.parse_args()



print('[INFO] Experiment folder is {}'.format( args.expfolder ))

s_timestamps = os.path.join(args.expfolder, 'events/Message_Center-904.0/TEXT_group_1/timestamps.npy')
s_text       = os.path.join(args.expfolder, 'events/Message_Center-904.0/TEXT_group_1/text.npy')


isOK = True

if args.verbose:
    print('[INFO] Looking for file ' + s_timestamps)
    print('[INFO] Looking for file ' + s_text)

if not os.path.isfile(s_timestamps):
	print('  [ERROR] File does not exist: ' + s_timestamps)
	isOK = False
if not os.path.isfile(s_text):
	print('  [ERROR] File does not exist: ' + s_text)
	isOK = False

if not isOK:
	sys.exit('Bye.')


secs = numpy.load(s_timestamps)
txt = numpy.load(s_text)
nEvents = txt.size
if args.verbose:
    print(f'[INFO] There are {nEvents} events')


print('-----------------')
print('Time (ms) : Event')
print('-----------------')
for n in range(nEvents):
    print(str(secs[n]) + ' : ' + str(txt[n]))
