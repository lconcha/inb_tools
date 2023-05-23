tCoords = coords_apply_nonlinear_ants(affineXFM,Warp,coordsFname)

nv = textread(coordsFname,'',1,'delimiter','  ','headerlines',1);
nv = nv(1);
coords = textread(coordsFname,'','delimiter','  ','headerlines',2);
coords = coords(1:nv,1:3);


[a,b] = textread(affineXFM,'%s%s','delimiter',':','headerlines',3);
M1 = str2num(b{1});
M2 = str2num(b{2});
tr_matrix = [reshape(M1,3,4)];


[hdr,x] = niak_read_nifti([Warp 'xvec.nii.gz']);
[hdr,y] = niak_read_nifti([Warp 'yvec.nii.gz']);
[hdr,z] = niak_read_nifti([Warp 'zvec.nii.gz']);
deformField = cat(4,x,y,z);


info.Starts = hdr.info.mat(1:3,4);
info.Steps  = hdr.info.voxel_size;
info.xspace = hdr.info.dimensions(1);
info.yspace = hdr.info.dimensions(2);
info.zspace = hdr.info.dimensions(3);


xbox = linspace(info.Starts(1),info.Starts(1)+info.Steps(1).*info.xspace,info.xspace);
ybox = linspace(info.Starts(2),info.Starts(2)+info.Steps(2).*info.yspace,info.yspace);
zbox = linspace(info.Starts(3),info.Starts(3)+info.Steps(3).*info.zspace,info.zspace);
bbox = [xbox(1) xbox(length(xbox))-1;...
        ybox(1) ybox(length(ybox))-1;...
        zbox(1) zbox(length(zbox))-1];




% original coords
ox = coords(:,1);
oy = coords(:,2);
oz = coords(:,3);


% displacement vectors
ix = interp3(xbox,ybox,zbox,squeeze(deformField(:,:,:,1)),ox,oy,oz);
iy = interp3(xbox,ybox,zbox,squeeze(deformField(:,:,:,2)),ox,oy,oz);
iz = interp3(xbox,ybox,zbox,squeeze(deformField(:,:,:,3)),ox,oy,oz);
displacementVectors = [ix iy iz];

% modify the original coordinates by the linear transformation
xyz_lin = transformPoint3d(allPointsInAllFibers, tr_matrix);

% modify the coordinates by the disp. vectors
iXYZ = xyz_lin + displacementVectors;
