function freesurfer_surf_to_fakeTrack(surf,OUT_track,t1)
%
% Creates a fake track with only one streamline, which takes the
% coordinates of a surface defined by freesurfer. Useful for registering
% the surface onto dti space using normalise_tracks (mrtrix).
%
%  freesurfer_surf_to_fakeTrack(surf,fakeTrack,t1)
% All arguments refer to filenames.
% 
% surf      : The surface to convert (e.g., rh.white)
% OUT_track : The file to create.
% t1        : The conformed T1 from freesurfer (mri/T1.mgz) converted to nii.
%
% Luis Concha
% INB, 2012.
% lconcha@unam.mx

disp('Here');

addpath('/home/inb/lconcha/fmrilab_software/mrtrix/matlab/')
FS_HOME=getenv('FREESURFER_HOME')
addpath([FS_HOME '/matlab/'])


if exist('write_mrtrix_tracks') < 2
    try
        addpath('/home/inb/lconcha/fmrilab_software/mrtrix/matlab/')
    catch
        error('Cannot find mrtrix matlab tools in PATH\n');
        return
    end
end

if exist('freesurfer_read_surf') < 2
    try
        addpath /home/lconcha/software/freesurfer_5.0/matlab/freesurfer_read_surf.m
    catch
        error('Cannot find freesurfer matlab tools in PATH\n');
        return
    end
end


fprintf(1,'  Loading surface: %s\n',surf);
[v,f]       = freesurfer_read_surf(surf);
fprintf(1,'  Loading Volume: %s\n',t1);
[hT1,T1]    = niak_read_nifti(t1);

% put the surface in T1 voxel coords
vVoxelSpace  = [v(:,1) + (-128 + hT1.info.mat(1,4) ./ hT1.info.voxel_size(1)),...
                v(:,2) + (128 + hT1.info.mat(2,4) ./ hT1.info.voxel_size(2)),...
                v(:,3) + (-128   + hT1.info.mat(3,4) ./ hT1.info.voxel_size(3))];


% Make a ficticious track with only one streamline with coords of the
% surface.
faketracks.count        =   1;
faketracks.total_count  =   1;
faketracks.data         = {};
faketracks.data{1}      = vVoxelSpace;
fprintf(1,'  Writing pseudo-track: %s\n',OUT_track);
write_mrtrix_tracks(faketracks,OUT_track);