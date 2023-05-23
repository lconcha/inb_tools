function inb_bruker_to_nii(fname,nii,varargin) 
% inb_bruker_to_nii(fname,nii,varargin) 
% 
%
% fname:  2dseq file. Usually within the PV directory structure, organized
%         into folders according to acquisitions.
%
% nii  : OUTPUT file name. Do not supply the .gz part, it will be done
%        automatically if needed.
%
%
% OPTIONS
% (should be given as value pairs, as: 'key',value)
%
% compress:    true|false. Use gzip compression of output. Optional. 
% 
% inversions   a 1x3 matrix of multipliers in [x y z] form. 
%              For example, to flip the z component, use [1 1 -1]
%              Default is to not flip anything, i.e., [1 1 1].
%
% doplot       true|false. Plot the diffusion gradient vectors.
%
% writenii     true|false.  Useful if you only want the grads. Default is true.
% maxg         Maximum gradient strength per channel (mT/m). 
%              Useful for writing a gradient table in Stejskal-Tanner
%              format that can be used in camino, with the gradient
%              strength in mT/m in the fourth column. If not supplied, then
%              this column will represent the percent of the maximum
%              achievable gradient strength by the scanner.
%
% Requires aedes: http://aedes.uef.fi/
%
% Example
% inb_bruker_to_nii('2dseq','myfile.nii','compress',true, 'maxg', 770) 
% 
% LU15 (0N(H4
% INB, UNAM
% August 2015
%   Modified Feb 2016 to correctly output 3D acquisitions and DWI vectors.


if nargin < 2
   fprintf(1,'ERROR, need at least 2 arguments\n');
   return
end






% default options
compress   = false;
inversions = [1 1 1];
doPlot     = false;
write_nii  = true;
maxG       = 100;

% Parse parameter/value pairs
for ii=1:2:length(varargin)
    this_arg =  lower(varargin{ii});
    switch this_arg
      case 'compress'
            compress = cell2mat(varargin(ii+1));
      case 'inversions'
            inversions  = cell2mat(varargin(ii+1));
            fprintf(1, '  [INFO]  Gradient flipping will take place: %s\n', mat2str(inversions));
      case 'doplot'
            doPlot = cell2mat(varargin(ii+1));
            fprintf(1, '  [INFO]  Will plot gradients \n');
      case 'writenii'
            write_nii = cell2mat(varargin(ii+1));
            fprintf(1, '  [INFO]  Will not write a nifti file. \n');
        case 'maxg'
            maxG =  cell2mat(varargin(ii+1));
            fprintf(1, '  [INFO]  Maximum gradient strength per channel (mT/m): %1.3f. \n',maxG);
    end
end



%% Check if file exists
if  exist(nii, 'file') == 2
   fprintf(1,'ERROR. File exists (not overwriting): %s\n',nii);
   return
end
if compress
    if  exist([nii '.gz'], 'file') == 2
        fprintf(1,'ERROR. File exists (not overwriting): %s\n',[nii '.gz']);
        return
    end
end




%% Load data ande extract important info
fprintf(1,'Loading file: %s\n',fname);
if ~write_nii
    % DATA = aedes_readbruker(fname,'header'); % not well implemented
    DATA = aedes_readbruker(fname,'wbar','off');
else
    DATA = aedes_readbruker(fname,'wbar','off');
end
scan_name = DATA.HDR.FileHeader.acqp.ACQ_scan_name;
fprintf(1,'  %s\n',scan_name);


if length(DATA.HDR.FileHeader.reco.RECO_fov) == 2
    voxSize(1:2) = DATA.HDR.FileHeader.reco.RECO_fov ./ DATA.HDR.FileHeader.reco.RECO_size .* 10; %header holds FOV in cm, I change it to mm
    voxSize(3)   = DATA.HDR.FileHeader.method.PVM_SPackArrSliceDistance .* 10;
    voxSize(4)   = DATA.HDR.FileHeader.method.PVM_RepetitionTime ./ 1000; 
else
    voxSize(1:3) = DATA.HDR.FileHeader.reco.RECO_fov ./ DATA.HDR.FileHeader.reco.RECO_size .* 10;
    voxSize(4)   = DATA.HDR.FileHeader.method.PVM_RepetitionTime ./ 1000;
end






%% Write nifti
if write_nii
    aedes_write_nifti(DATA,nii,'VoxelSize',voxSize,'DataType','single');
    if compress
        fprintf(1,'Compressing %s\n',nii);
        [status,result] = system(['gzip ' nii]);
    end
end



%% find out if we are dealing with DWIs
try
    bmat      = DATA.HDR.FileHeader.method.PVM_DwBMat;
    isDWIs    = true;
catch
    fprintf(1,'Not a DWI data set\n');
    isDWIs = false;
end




%% write bvals and bvecs
if isDWIs
    bmat      = DATA.HDR.FileHeader.method.PVM_DwBMat;
    DwDir     = DATA.HDR.FileHeader.method.PVM_DwDir;  % these are the normalized vectors available in DwGradVec, without the b=0 directions.
                                                       % if user inputs a gradient vector not normalized, it gets normalzied by the scanner
    bval_eff  = DATA.HDR.FileHeader.method.PVM_DwEffBval; %takes into account imaging gradients.
    DwDir_eff = DATA.HDR.FileHeader.method.PVM_DwEffGradTraj;

    DwGamp    = DATA.HDR.FileHeader.method.PVM_DwGradAmp;
    DwMaxBval = DATA.HDR.FileHeader.method.PVM_DwMaxBval;
    DwGdur    = DATA.HDR.FileHeader.method.PVM_DwGradDur;
    DwGsep    = DATA.HDR.FileHeader.method.PVM_DwGradSep;
    DwGradVec = DATA.HDR.FileHeader.method.PVM_DwGradVec;  % these include the b=0s, but they are not normalized.
    TE        = DATA.HDR.FileHeader.acqp.ACQ_echo_time;
    nShells   = length( DATA.HDR.FileHeader.method.PVM_DwBvalEach );
    n_bzero   = DATA.HDR.FileHeader.method.PVM_DwAoImages;
    prescribed_bvals = [repmat(0,n_bzero,1); repmat(DATA.HDR.FileHeader.method.PVM_DwBvalEach',length(DwDir),1)];
    
    
    nonzero_DWdirs = repmat(DwDir,nShells,1);
    b0_dirs            = repmat([0 0 0],n_bzero,1);
    all_dwi_dirs = [b0_dirs;nonzero_DWdirs];
    norm_DwGradVec = normalize3d(DwGradVec);
    norm_DwGradVec(isnan(norm_DwGradVec)) = 0;
    
   
    % invert, if necessary
    if isstr(inversions); inversions = str2num(inversions);end % this is just in case this function was called from bash using the -inversions switch
    invMat = repmat(inversions,size(norm_DwGradVec,1),1);
    flipped_gradients = norm_DwGradVec .* invMat;
    norm_DwGradVec = flipped_gradients;
    
    full_b_table = [norm_DwGradVec bval_eff'];
    
    
    
    if doPlot
        scatter3(DwGradVec(:,1),DwGradVec(:,2),DwGradVec(:,3),50,bval_eff,'filled');
        hold on
        plot3(DwGradVec(:,1),DwGradVec(:,2),DwGradVec(:,3),'- k');
        colorbar;
    end


    
    
    
  
    fprintf(1,'Writing bval and bvec files\n');
    f_bvec = strrep(nii,'.nii','.bvec');
    f_bval = strrep(nii,'.nii','.bval');
    f_btab = strrep(nii,'.nii','.encoding');
    dlmwrite(f_bvec,full_b_table(:,1:3)','delimiter',' ')
    dlmwrite(f_bval,bval_eff,'delimiter',' ')
    dlmwrite(f_btab,full_b_table,'delimiter',' ');
    
%     % write camino scheme file
%     % VERSION: STEJSKALTANNER
%     % x_1 y_1 z_1 |G_1| DELTA_1 delta_1 TE_1
%     % x_2 y_2 z_2 |G_2| DELTA_2 delta_2 TE_2
%     % :
%     % :
%     % x_N y_N z_N |G_N| DELTA_N delta_N TE_N
     DwGamp_mTm = maxG .* (DwGamp./100); 
     Gamps     = [repmat(0,n_bzero,1);repmat(DwGamp_mTm',size(DwDir,1),1)];
     Deltas = repmat(DwGsep,size(DwGradVec,1),1);
     Deltas(Gamps==0) = 0;
     deltas = repmat(DwGdur,size(DwGradVec,1),1);
     deltas(Gamps==0) = 0;
     TEs = repmat(TE,size(DwGradVec,1),1);
     st_table = [DwGradVec Gamps Deltas deltas TEs];
     f_scheme = strrep(nii,'.nii','.scheme');
     fid = fopen(f_scheme,'w');
     fprintf(fid,'VERSION: STEJSKALTANNER\n');
     fclose(fid);
     dlmwrite(f_scheme,st_table,'-append','delimiter',' ');
    
end







