
function [ bvals, bvecs ] = correct_MNC_DWI_bmatrix( input_mnc_file, writing_text_option )

% 
% This function is used to read and further correct the gradient b-matrix 
% in minc files of DWI in MNI. 
%
% INPUT:
%
%   input_mnc_file: the 4D minc file storing n DWI volumes (with directory)
%
%   writing_text_option:  1. empty: don't writing any text file
%                         2. 'F': write text files with name <bvals> and
%                            <bvecs> respectively, according to FSL format
%                         3. 'D': write a text files named as          
%                            <bmatrix> according to DTIstudio format 
% OUTPUT:
%
%   bvals: N*1 vector representing b values for all the DWI volumes
%
%   bvecs: N*3 matrix with rows representing corrected gradient direction for 
%          all the DWI volumes
%   
%
% NOTE: As different packages/file-formats are using different coordinate-system, 
%       you have to check the flipping issue before running tractography.
%       The absolute values of the rotation matrix calculated in this script 
%       is applicable for any DWI acquistion. But the sign of the values in this 
%       matrix is specific to the user's employed package/file-formats/scanner, 
%       whose coordinate-systems are always flipped between each other. Current 
%       script is specifically designed for MINC-DWI files (1.5T scanner) at BIC/MNI. 
%       For this acquistion, you can directly use the resulting bvec/bmatrix 
%       for FSL/DTIstudio. For other DWI acquisitions, you have to first check
%       and find the right way to set the sign of each column in bmatrix or each
%       row in bvecs. Good luck:)
%
%  Gaolang Gong, Sep/11 2008, ACES/BIC/MNI/MCGILL



if nargin < 2
  writing_text_option = 'N';
end



% reading the raw bvals and bvecs from minc header
hdr = niak_read_hdr_minc(input_mnc_file);
bvals  =niak_get_minc_att( hdr, 'acquisition', 'bvalues');
bvals  =bvals';
bvector_x=niak_get_minc_att( hdr, 'acquisition', 'direction_x');
bvector_y=niak_get_minc_att( hdr, 'acquisition', 'direction_y');
bvector_z=niak_get_minc_att( hdr, 'acquisition', 'direction_z');
bvector=[bvector_x;bvector_y;bvector_z];

% reading the rotation matrix from minc header
rotation_x=niak_get_minc_att( hdr, 'xspace', 'direction_cosines');
rotation_y=niak_get_minc_att( hdr, 'yspace', 'direction_cosines');

% I don't understand why the third value in the Minc direction_cosines is
% sign-inversed from Dicom's ImageOrientationPatient direction_cosine
% value
rotation_x(3)=-rotation_x(3);
rotation_y(3)=-rotation_y(3);
rotation_z=cross(rotation_x, rotation_y);
Dicom2scanner_rotation=[rotation_x', rotation_y', rotation_z'];
% i.e. [x;y;z] in scanner = Dicom2scanner_rotation * [x;y;z] in Dicom coordinate
scanner2Dicom_rotation=Dicom2scanner_rotation'; % i.e. inverse  
Dicom2MNI_rotation=diag([-1,-1,1]);
scanner2MNI_rotation=Dicom2MNI_rotation * scanner2Dicom_rotation;


% Orientation information
  %----------------------------------------------------------------------
    % DICOM patient co-ordinate system:
    % x increases     right to left
    % y increases  anterior to posterior
    % z increases  inferior to superior
  
    % MNI and NIFTI co-ordinate system:
    % x increases      left to right
    % y increases posterior to anterior
    % z increases  inferior to superior
   %----------------------------------------------------------------------


% correction
Corrected_bvecs=((scanner2MNI_rotation)*bvector)'; 
Norm_Vector=(sqrt(Corrected_bvecs(:,1).^2+Corrected_bvecs(:,2).^2+Corrected_bvecs(:,3).^2)); 
Norm_Vector(Norm_Vector==0)=1;
Corrected_bvecs(:,1)=Corrected_bvecs(:,1)./Norm_Vector;
Corrected_bvecs(:,2)=Corrected_bvecs(:,2)./Norm_Vector;
Corrected_bvecs(:,3)=Corrected_bvecs(:,3)./Norm_Vector;
bvecs=Corrected_bvecs;
bvecs(:,3)=-bvecs(:,3); % specific to FSL for minc-dwi files in 1.5T bic/mni.

% writing the text files in the current directory,in terms of writing_text_option
if writing_text_option=='F'
    % bvals text file
    fid = fopen('bvals', 'wt');
    if fid == -1
        error('Could not open bvals output file')
    end
    fprintf(fid, '   %e', bvals);
    fprintf(fid, '\n');
    fclose(fid);
    
    % bvecs text file
    fid = fopen('bvecs', 'wt');
    if fid == -1
        error('Could not open bvecs output file')
    end
    for D = 1:3
    fprintf(fid, '   %e', bvecs(:,D));
    fprintf(fid, '\n');
    end
    fclose(fid);
end

if writing_text_option=='D' 
    % bmatrix text file
    fid = fopen('bmatrix.txt', 'wt');
    if fid == -1
        error('Could not open bmatrix output file')
    end
    fprintf(fid, '%g: %8.5f, %8.5f, %8.5f\n', [[0:length(bvecs)-1]', bvecs]');
    fprintf(fid, '\n');
    fclose(fid);
end


%--------------------------------------------------------------------------
% Show the results in Command Windows of Matlab
%--------------------------------------------------------------------------
fprintf('----------------------------------------------------------------------------------------\n');
% Show the exact angle around left-right axis
Phi = atan2(scanner2MNI_rotation(2,3), scanner2MNI_rotation(3,3));
if abs(Phi*180/pi)~=0
    fprintf('1:  The rotation angle around left-right axis is %g degree.\n',abs(Phi*180/pi));
else
    fprintf('1:  No rotation around left-right axis.\n');
end
% Show the exact angle around anterior-posterior axis
Theta = asin(-scanner2MNI_rotation(1,3)); 
if abs(Theta*180/pi)~=0
fprintf('2:  The rotation angle around anterior-posterior axis is %g degree.\n',abs(Theta*180/pi));
else
fprintf('2:  No rotation around anterior-posterior axis.\n');
end
% In transverse scanning, no rotation around inferior-posterior axis
fprintf('3:  No rotation around inferior-posterior axis.\n');
fprintf('----------------------------------------------------------------------------------------\n');
