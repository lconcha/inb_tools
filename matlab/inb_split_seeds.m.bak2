function inb_split_seeds(seeds_vol_fname,output_base,voxelSize)


[hdr,seeds]  = niak_read_nifti(seeds_vol_fname);
outfile = [output_base '_seeds.txt'];

if nargin < 3
  voxelSize = hdr.info.voxel_size(1);
end


XFM = hdr.info.mat

index = find(seeds > 0);
nVoxels = length(index);
fprintf(1,'There are %d seed voxels\n',nVoxels);

[r,c,s] = ind2sub(size(seeds),index);


fid = fopen(outfile,'w');

fprintf(1,'Saving to %s',outfile);
for v = 1 : nVoxels
  voxel = [r(v) c(v) s(v)] -1; %MUST OFFSET MATLAB ORIGIN
  world = XFM * [voxel 1]';
  fprintf(fid,'%d,%d,%d,%1.4f,%1.4f,%1.4f,%1.4f\n',voxel(1),voxel(2),voxel(3),world(1),world(2),world(3),voxelSize/2);
end

fclose(fid);
fprintf(1,'\nDone.\n');
