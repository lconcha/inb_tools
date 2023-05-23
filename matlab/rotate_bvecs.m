function bvecsnew=rotate_bvecs(bvecin,eddyparams,bvecout)

% Rotate gradients based on FSL's eddy motion and distortion correction. 
% 
% Usage: bvecsnew=rotate_bvecs(bvecin,eddyparams,bvecout)
%
% Inputs:
% bvecin       filename of the bvecs file (usually *.bvec)
% eddyparams   filename of the eddy parameters (usually *.eddy_params)
% bvecout      new filename for the rotated bvecs (optional)
%
% Outputs:
% bvecsnew     the rotated bvecs
%
% Additional information:
% To use this function with mrtrix3 grad.txt file, follow these steps:
% 1. before rotation of the gradient (and motion correction with eddy):
%       e.g. mrinfo dwi.mif -export_grad_fsl sub1.bvec sub1.bvals
% 2. perform motion correction with eddy and then rotate the gradients with
%       e.g. matlab -nodisplay -nosplash -nojvm -r "rotate_bvecs('sub1.bvec','dwi_eddy.eddy_params','sub1_rot.bvec')"
% 3. after rotation:
%       e.g mrconvert dwi_eddy.nii -fslgrad sub1_rot.bvec sub1.bvals dwi_corrected.mif
%
% (c) Timo Roine, timo.roine@uantwerpen.be, 2015, no warranty

pars=load(eddyparams);
bvecs=load(bvecin);

if size(bvecs,1) > size(bvecs,2)
  bvecs = bvecs';
end


for i=1:size(bvecs,2)
    rx=[1 0 0; 0 cos(pars(i,4)) sin(pars(i,4)); 0 -sin(pars(i,4)) cos(pars(i,4))];
    ry=[cos(pars(i,5)) 0 -sin(pars(i,5)); 0 1 0; sin(pars(i,5)) 0 cos(pars(i,5))];
    rz=[cos(pars(i,6)) sin(pars(i,6)) 0; -sin(pars(i,6)) cos(pars(i,6)) 0; 0 0 1];
    bvecsnew(:,i)=(inv(rx*ry*rz)*bvecs(:,i));
end

dlmwrite(bvecout,bvecsnew,'precision',10,'delimiter',' ');
