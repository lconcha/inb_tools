function [track2, dist_vol] = track_length(track_fname,vol_fname,seed_vol_fname,out_file)

mrtrixdir = getenv('mrtrixDir');
addpath([mrtrixdir '/matlab']);
track = read_mrtrix_tracks(track_fname);

if nargin > 2
    do_seed_vol = true;
    [hdr,seed_vol]  = niak_read_nifti(seed_vol_fname);
end

if nargin > 3
    savevol = true;
end

[hdr,vol]  = niak_read_nifti(vol_fname);
xfm = hdr.info.mat;
% corner0 = xfm * [1 1 1 1]';
% corner1 = xfm * [hdr.info.dimensions(1) hdr.info.dimensions(2) hdr.info.dimensions(3) 1]';
% [X,Y,Z] = meshgrid(corner0(1):hdr.info.voxel_size(1):corner1(1),...
%                    corner0(2):hdr.info.voxel_size(2):corner1(2),...
%                    corner0(3):hdr.info.voxel_size(3):corner1(3));

track2 = track;
for t = 1 : str2num(track.count)
   thisTrack    = track.data{t};
   if do_seed_vol
      voxels = round(inv(xfm) * [thisTrack(:,1:3) ones(size(thisTrack,1),1)]')' +1;
      seed_values = zeros(size(thisTrack,1),1);
      [unique_voxels,index_i,index_j] = unique(voxels,'rows');
      unique_indices = unique(index_j);
      for uv = 1 : length(unique_voxels)
          thisIndex_j = find(index_j == uv);
          thisCoord_vox  = voxels(thisIndex_j(1,:),1:3);
          thisCoord_mask_val = seed_vol(thisCoord_vox(1),thisCoord_vox(2),thisCoord_vox(3));
          seed_values(thisIndex_j) = thisCoord_mask_val;
      end
      if sum(seed_values) == 0
         fprintf(1,'Could not find seed for track %d\n',t); 
         thisDistance = zeros(size(seed_values));
         thisDistance(:) = NaN;
      else
          first = find(logical(seed_values),1,'first');
          last  = find(logical(seed_values),1,'last');
          first_seed_Point  = thisTrack(first,:);
          last_seed_Point   = thisTrack(last,:);
          distance_to_first = distancePoints3d(first_seed_Point,thisTrack(1:first,:));
          distance_to_last  = distancePoints3d(last_seed_Point, thisTrack(last:end,:));
          thisDistance      = zeros(size(seed_values));
          thisDistance(1:first) = distance_to_first;
          thisDistance(last:end) = distance_to_last;
      end
   else
       firstPoint   = thisTrack(1,:);
       thisDistance = distancePoints3d(firstPoint,thisTrack);
   end
   track2.distances{t} = thisDistance';
end




nPoints = 0;
for t = 1 : str2num(track.count)
    nPoints = nPoints + length(track2.data{t});
end

thePoints = zeros(nPoints,4);
start = 1;
for t = 1 : str2num(track.count)
  thisTrack     = track.data{t};
  thisDistances = track2.distances{t};
  offset = start + length(thisTrack) -1;
  thePoints(start:offset,:) = [thisTrack thisDistances'];
  start = offset +1;
end
voxels = round(inv(xfm) * [thePoints(:,1:3) ones(size(thePoints,1),1)]')' +1;
[unique_voxels,index_i,index_j] = unique(voxels,'rows');


dist_vol = zeros([hdr.info.dimensions(1:3)]);
unique_indices = unique(index_j);
for uv = 1 : length(unique_voxels)
    thisIndex_j = find(index_j == uv);
    thisCoord_vox  = voxels(thisIndex_j(1,:),1:3);
    thisCoord_dist = thePoints(thisIndex_j,4);
    dist_vol(thisCoord_vox(1),thisCoord_vox(2),thisCoord_vox(3)) = nanmean(thisCoord_dist);
end


if savevol
    hdr.file_name = out_file;
    niak_write_nifti(hdr,single(dist_vol));
end