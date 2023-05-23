
%addpath /home/lconcha/software/mrtrix_svn/mrtrix-read-only/matlab
%addpath /home/lconcha/software/along-tract-stats


tck = '/misc/mansfield/lconcha/exp/tracto_repro/s2/auto/bothSides/out_f_ar_l.tck';
trk = '/misc/mansfield/lconcha/exp/tracto_repro/s2/auto/bothSides/blah.trk';
example_trk = '/misc/mansfield/lconcha/exp/tracto_repro/s2/tracking-deterministic-left.trk';
parent_file = '/misc/mansfield/lconcha/exp/tracto_repro/s2/fa.nii.gz';

% load the tck file
tracks = read_mrtrix_tracks(tck);

% get info from parent file
parent_hdr = niak_read_hdr_nifti(parent_file);


[ex_hdr,ex_tracks] = readTrack(example_trk);


% make a header
hdr             = ex_hdr;
hdr.id_string   = 'TRACK ';
hdr.dim         = parent_hdr.info.dimensions(1:3);
hdr.voxel_size  =  parent_hdr.info.voxel_size;
%hdr.origin      = [0 0 0];
%hdr.n_scalars   = 0;
%hdr.scalar_name = char(zeros(10,20));
%hdr.n_properties= 0;
%hdr.property_name= char(zeros(10,20));
%hdr.vox_to_ras  = zeros(4);
%hdr.reserved    = char(zeros(444,1));
%hdr.voxel_order = 'LPS ';
%hdr.pad2        = 'LAS ';
%hdr.image_orientation_patient= [1 0 0 0 -1 0];
%hdr.pad1        = '  ';
%hdr.invert_x    = 0;
%hdr.invert_y    = 1;
%hdr.invert_z    = 0;
%hdr.swap_xy     = 0;
%hdr.swap_yz     = 0;
%hdr.swap_zx     = 0;
hdr.n_count     = length(tracks.data);
%hdr.version     = 2;
%hdr.hdr_size    = 1000;


for f = 1 : hdr.n_count
   out_tracks(f).matrix = single(tracks.data{f});
   out_tracks(f).nPoints = size(out_tracks(f).matrix,1);
   out_tracks(f).props = f;
end


trk_write(hdr,out_tracks,trk);