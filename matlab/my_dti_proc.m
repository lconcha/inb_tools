function [ADC,FA,VectorF,DifT] = my_dti_proc(directory,outbase,parentFile)
% calculate dti maps from a bedpostx style directory

savenifti = true;
if nargin < 2
   savenifti = false; 
end

addpath /home/lconcha/denoising/DTI_version_1b


bvals = load([directory '/bvals']);
bvecs = load([directory '/bvecs']);
[hdr,data]   = niak_read_nifti([directory '/data.nii.gz']);
[hdr,mask]   = niak_read_nifti([directory '/nodif_brain_mask.nii.gz']);



for i = 1 : size(data,4)
    DTIdata(i).VoxelData = squeeze(data(:,:,:,i));
    DTIdata(i).Gradient  = bvecs(:,i)';
    DTIdata(i).Bvalue    = bvals(i);
    DTIdata(i).mask      = mask;
end

[hdrParent,parent]   = niak_read_nifti([directory '/' parentFile]);
 

parametersDTI.BackgroundTreshold =  0;
parametersDTI.WhiteMatterExtractionThreshold=0.10;
parametersDTI.textdisplay=false;
            
[ADC,FA,VectorF,DifT]=DTI(DTIdata,parametersDTI);

if savenifti
    hdrParent.file_name = [directory '/' outbase '_ADC.nii'];
    niak_write_nifti(hdrParent,ADC);
    hdrParent.file_name = [directory '/' outbase '_FA.nii'];
    niak_write_nifti(hdrParent,FA);
end
            

size(data);
size(mask);