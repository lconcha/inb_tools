function p = tracto_p_poisson(seed_map,mu_map,v_null_map,p_thresh,areFileNames,niftiOut)
%Probability of connectivity of any given tract. Is it more than chance?
%
%function p = tracto_p_poisson(seed_map,mu_map,v_null_map,p_thresh,areFileNames,niftiOut)
%
%   mu_map    : A visitation count map. 
%               You get this in mrtrix with tracks2prob (do not use the
%               -fraction switch, you need the integers).
%   v_null_map: The visitation count map of a null distribution (isotropic
%               diffusion voxels), multiplied by the number of seeds used
%               in mu_map (n), divided by the number of seeds used in the null
%               experiment (n'). n' >> n. 
%
%
% Adapted from:
% Morris, Embleton and Parker. 
% Probabilistic fibre tracking: Differentiation of connections from chance events.
% Neuroimage 42, 1329-1339. 2008.
%
% Adapted by Luis Concha with amazing help from Leopoldo Gonzalez Santos.
% Instituto de Neurobiología, Universidad Nacional Autonoma de México.
% October, 2012.

fprintf(1,'Arguments were:\n')
fprintf(1,'seed_map     : %s\n',   seed_map)
fprintf(1,'mu_map       : %s\n',   mu_map)
fprintf(1,'v_null_map   : %s\n',   v_null_map)
fprintf(1,'p_thresh     : %1.3f\n',p_thresh)
fprintf(1,'niftiOut     : %s\n',   niftiOut)


writeNifti = true;
if nargin < 5
   areFileNames = false; 
   writeNifti   = false;
   p_thresh     = 0.05;
end
if nargin < 4
   p_thresh     = 0.05;
end


if areFileNames
    fprintf(1,'  Loading %s\n',mu_map);
    [hdr_mu,mu_map]      = niak_read_nifti(mu_map);
    fprintf(1,'  Loading %s\n',v_null_map);
    [hdr,v_null_map]  = niak_read_nifti(v_null_map); 
end


if regexp(seed_map,',')
  disp(['OK: Seed coords were given, not a volume'])
  vol = zeros(size(mu_map));
  world = str2num(seed_map);
  world(4) = 1;
  voxel = inv(hdr.info.mat) * world';
  voxel = round(voxel');  % if image resolution from seeds is not equal to the original CSD, then rounding errors will occur.
  voxel = voxel +1; % fix matlab offset
  vol(voxel(1),voxel(2),voxel(3)) = 1;
  seed_map = vol;
else
    fprintf(1,'  Loading %s\n',seed_map);
    [hdr_seeds,seed_map]      = niak_read_nifti(seed_map);

end

% remove any voxels in which the p of connection to the seed can only be
% explained by chance alone.
mask = mu_map > v_null_map;

p = ones(size(mu_map));

p(mask) = poisspdf((mu_map(mask)),(v_null_map(mask)));

% put back the seed with p=0
% warning: seed map and mu_map may have different resolutions (albeit being
% in the same space)
%  if sum(hdr_seeds.info.dimensions(1:3) == hdr_mu.info.dimensions(1:3)) == 3
    index_seed = find(seed_map > 0);
    fprintf(1,'Size of index_seed is %d\n',length(index_seed))
    p(index_seed) = 0;
%  else
%      fprintf(1,'INFO: Mismatch in resolution between seeds and v_map\n');
%      index_seed = find(seed_map > 0);
%      [i,j,k] = ind2sub(size(seed_map),index_seed);
%      voxelA  = [i j k] - 1; %fix matlab offset.
%      voxelA  = [voxelA ones(size(k))];
%      world   = [hdr_seeds.info.mat * voxelA']';
%      voxelB  = inv(hdr_mu.info.mat) * world';
%      voxelB  = round(voxelB);  % if image resolution from seeds is not equal to the original CSD, then rounding errors will occur.
%      voxelB  = voxelB'  +1; % fix matlab offset
%      index_seedB = sub2ind(size(mu_map),voxelB(:,1),voxelB(:,2),voxelB(:,3));
%      p(index_seedB) = 0;
%  end

% find disconnected voxels
[L,n] = bwlabeln(p < p_thresh);
seed_label_value = L(index_seed(1));
p(L~=seed_label_value) = 1;





if writeNifti
    fprintf(1,'  Writing %s\n',niftiOut);
    hdr = hdr_mu;
    hdr.file_name = niftiOut;
    hdr.details.bitpix = 32;
    hdr.info.precision = 'single';
    niak_write_nifti(hdr,p);
end
