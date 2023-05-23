function my_create_streamline_for_sampling(fdots,ftckout)
% my_create_streamline_for_sampling(fdots,ftckout)
% fdots   = A filename of a NIFTI file in which dots were drawn on a single
% slice. These dots will be connected by a line, and saved into ftckout.
%           example: '/misc/mansfield/lconcha/TMP/displasia/carm04g_ctrl/denoised/dots.nii';
% ftckout = The output tck file.
%           example: '/misc/mansfield/lconcha/TMP/displasia/carm04g_ctrl/denoised/sampler.tck';
%
% After saving the tck, you can upsample the resulting line using
% tckresample, for example:
%   tckresample -num_points 100 ftckout.tck resampled.tck
% and now sample an FA map:
%   tcksample resampled.tck fa.mif favalues.txt

% load the dots that will be used to create the streamline


fprintf(1,'  Loading %s\n',fdots);
[hd, dots] = niak_read_nifti(fdots);


% find the dots and get their coordinates in voxel space
[ind] = find(dots>0);
[x,y,z] = ind2sub(size(dots),ind);
% sort according to x
[xo, o] = sort(x);
XYZ = [x(o) y(o) z(o)];


% transform to image space
pts = transformPoint3d(XYZ,hd.info.mat);


fprintf(1,'  Saving streamline with %d points, %s\n',length(XYZ),ftckout);
track.data = {pts};
write_mrtrix_tracks (track, ftckout)