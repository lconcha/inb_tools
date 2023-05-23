function [rPeaks,rAmplitudes,rVectors] = inb_selective_FOD_amplitude(...
    fPeaks,fAmplitudes,fTracks,...
    ofPeaks,ofAmplitudes,ofVectors)
% How to use:
%
% [rPeaks,rAmplitudes,rVectors] = inb_selective_FOD_amplitude(...
%                                 fPeaks, fAmplitudes, fTracks,...
%                                 ofPeaks, ofAmplitudes, ofVectors)
%
% For a given track, select the FODs that have allowed that track to pass
% through each voxel, even in areas of crossing fibres.
% 
% Inputs:
% fPeaks      : The peaks image obtained through find_SH_peaks
% fAmplitudes : the amplitudes image obtained through dir2amp
% fTracks     : The track file (.tck)
%
% Files to write (specify file names): 
% ofPeaks     : The peaks file (indices)
% ofAmplitudes: The amplitudes (of the corresponding FOD peak)
% ofVectors   : The vectors of the particular FOD peaks
%               that allowed the track to pass through each voxel.
%
% Outputs:
% rPeaks      : The peak of the FOD.
% rAmplitudes : Amplitude of the corresponding FOD.
% rVectors    : Vector of the corresponding FOD peak.
%
% Notes:
% Please make sure that your fPeaks file does not contain >3 peaks/voxel.
% File names should use .nii suffix.
%
%
% LU15 (0N(H4
% INB, UNAM
% Feb 2014.
% lconcha@unam.mx




% Load some files
[hdr,peaks]      = niak_read_nifti(fPeaks);
peaks            = permute(peaks,[2 1 3 4]);
[hdr,amplitudes] = niak_read_nifti(fAmplitudes);
amplitudes       = permute(amplitudes,[2 1 3 4]);
tracks           = read_mrtrix_tracks(fTracks);

% make sure that there are no more than 3 peaks per voxel.
nPeaks = size(peaks,4) ./ 3;
if nPeaks ~= 3
    error('number of peaks is not exactly three. I have only implemented this function for 3. Sorry.')
    return
end

% organize the peaks
peak_index = 0;
for i = 1 : 3 : size(peaks,4)
   peak_index = peak_index + 1;
   cmd        = ['peak' num2str(peak_index) ' = peaks(:,:,:,' num2str(i) ':' num2str(i+nPeaks-1) ');'];
   eval(cmd);
end


% allocate memory
rAmplitudes = zeros(size(amplitudes(:,:,:,1)),'single');
rPeaks      = zeros(size(amplitudes(:,:,:,1)),'uint8');
rIndices    = zeros([size(amplitudes(:,:,:,1)) 3],'uint8');
rVectors    = zeros([size(amplitudes(:,:,:,1)) 3],'single');



% Go find the most parallel FOD peak for each track segment.
nTracks     = size(tracks.data,2);
msg         = sprintf('Percent done: %3.1f', 0);
reverseStr  = '';
fprintf([reverseStr, msg]);
reverseStr  = repmat(sprintf('\b'), 1, length(msg));
for t = 1 : nTracks
    if mod(t,10) == 0
       percentDone  = 100 * t / nTracks;
       msg          = sprintf('Percent done: %3.1f', percentDone);
       fprintf([reverseStr, msg]);
       reverseStr   = repmat(sprintf('\b'), 1, length(msg));
    end
    thisTrack = tracks.data{t};
    for p = 1 : size(thisTrack,1)
        thisPoint = thisTrack(p,:);
        try
            thisVec = thisTrack(p+1,:) - thisTrack(p,:);
        catch
            thisVec = thisTrack(p,:)   - thisTrack(p-1,:);
        end
        thisVec     = normalize3d(thisVec);
        vVoxelSpace = round(transformPoint3d(thisPoint,inv(hdr.info.mat))) +1;
        j           = vVoxelSpace(1); %notice the dimension swap between xyz (mrtrix) and r,c,s (matlab)
        i           = vVoxelSpace(2);
        k           = vVoxelSpace(3);
        try
        thesePeaks  = [squeeze(peak1(i,j,k,:))';...
            squeeze(peak2(i,j,k,:))';...
            squeeze(peak3(i,j,k,:))']; %#ok<*NODEF>
        catch
           fprintf('\nSkipping voxel coordinate [%d %d %d]\n',i,j,k); 
           reverseStr='';
           continue
        end
        thesePeaks  = normalize3d(thesePeaks);
        dots        = dot(thesePeaks',repmat(thisVec,3,1)');
        [y,index_peak] = max(abs(dots));
        
        rIndices(i,j,k,index_peak) =  rIndices(i,j,k,index_peak) +1;
    end
end
msg          = sprintf('Percent done: %3.1f', 100);
fprintf([reverseStr, msg]);
fprintf(1,'\n');



% mask the results
mask   = sum(rIndices,4) > 0;
%mask = ones(size(amplitudes));

[Y,I]  = max(rIndices,[],4);
Im     = I .* mask;
rPeaks = Im;




% organize the results according to the indices we identified
fprintf(1,'Organizing results...\n');
for f = 1 : 3
   ff        = find(Im == f);
   fprintf(1,'  Peak %d is in %d voxels\n',f,length(ff));
   [i,j,k]   = ind2sub(size(mask),ff);
   thisAmp   = zeros(size(mask));
   thisPeaks = zeros(size(mask));
   thisVecs  = zeros([size(mask) 3]);
   for z = 1 : length(k)
      thisAmp(i(z),j(z),k(z)) = amplitudes(i(z),j(z),k(z),f); 
      eval(['rVectors(i(z),j(z),k(z),:) = peak' num2str(f) '(i(z),j(z),k(z),:);']);
   end
   rAmplitudes(ff) = thisAmp(ff);
   
end


% Write output files
fprintf(1,'Writing files...\n');

hdr.file_name = ofPeaks;
fprintf(1,'  %s\n',hdr.file_name);
niak_write_nifti(hdr,permute(rPeaks,[2 1 3]));

hdr.file_name = ofAmplitudes;
fprintf(1,'  %s\n',hdr.file_name);
niak_write_nifti(hdr,permute(rAmplitudes,[2 1 3]));

hdr.file_name = ofVectors;
fprintf(1,'  %s\n',hdr.file_name);
niak_write_nifti(hdr,permute(rVectors,[2 1 3 4]));


fprintf(1,' Done!\n');
