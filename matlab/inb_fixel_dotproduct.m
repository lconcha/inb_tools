function [] = inb_fixel_dotproduct(f_fixel0,f_fixel1,f_dotproduct,doPlot)
% function [] = inb_fixel_dotproduct(f_fixel0,f_fixel1,f_dotproduct,doPlot)
% Example:
% a) Dot product between two fixels
%   my_dot('fixel0.mif', 'fixel1.mif', 'dotProduct.mif', false);
% b) Dot product between one fixel and a single vector, voxelwise:
%      my_dot('fixel0.mif', [1 0 0], 'dotProduct.mif', false);
%
% LU15 (0N(H4
% INB-UNAM
% Nov, 2024.
% lconcha@unam.mx

addpath(genpath('/home/inb/soporte/lanirem_software/mrtrix_3.0.4/matlab'));
addpath(genpath('/misc/lauterbur/lconcha/code/geom3d')); % https://la.mathworks.com/matlabcentral/fileexchange/24484-geom3d




if nargin < 4
    doPlot = false;
end

if numel(f_fixel1) == 3
  singleVector = true;
  fprintf(1,'Computing dot product to stationary vector\n');
else
  singleVector = false;
end







fixel0 = read_mrtrix(f_fixel0);
nX = size(fixel0.data,1);
nY = size(fixel0.data,2);
nZ = size(fixel0.data,3);
nVoxels = nX * nY * nZ;


% this is just for tests:
%x = 73; %test voxel. Later we add the +1 matlab offset
%y = 43;
%z = 30;
%v0 =  squeeze(fixel0.data(x+1,y+1,z+1,1:3))'; % transpose to make it easier

if ~singleVector
    fixel1 = read_mrtrix(f_fixel1);
    %v1 =  squeeze(fixel1.data(x+1,y+1,z+1,1:3))';
else
    fixel1.data = fixel0.data .* 0;
    fixel1.data(:,:,:,1) = f_fixel1(1);
    fixel1.data(:,:,:,2) = f_fixel1(2);
    fixel1.data(:,:,:,3) = f_fixel1(3);
end






rfixel0 = reshape(fixel0.data,nVoxels,3);
rfixel1 = reshape(fixel1.data,nVoxels,3);


rdotproduct = dot(rfixel0' ,rfixel1' );

dotproduct = reshape(rdotproduct,nX,nY,nZ);

if doPlot
    z = round(nZ/2);
    imagesc(abs(dotproduct(:,:,z)))
    colorbar
    set(gca,'CLim',[0 1])
end


fprintf(1,'Saving %s\n',f_dotproduct);
im_dotproduct = fixel0;
im_dotproduct.data = dotproduct;
write_mrtrix (im_dotproduct, f_dotproduct);
