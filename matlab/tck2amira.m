function tck2amira(tck,ami,im)
% function tck2amira(tck,ami,im)
%
% tck: track file name (e.g., mytrack.tck)
% ami: Output track .ami file name.
% im : Optional reference volume (.nii)
%
% LU15 (0N(H4
% INB, UNAM
% December 2014
% lconcha@unam.mx

if nargin < 3
    transform = false;
else
    transform = true;
end


if transform
    [hdr,vol] = niak_read_nifti(im);
end
tracks    = read_mrtrix_tracks (tck);

nTracks = str2num(tracks.count);
tractStructure = cell(nTracks,1);
for t = 1 : nTracks
   thesePoints = tracks.data(t);
   thesePoints = thesePoints{:};
   if transform
      thesePoints_transformed = transformPoint3d(thesePoints, hdr.info.mat); 
      tractStructure{t} = thesePoints_transformed;
   else
      tractStructure{t} = thesePoints; 
   end
end


fprintf(1,'Converting %d streamlines ...\n',nTracks);
ExploreDTI2Amira(tractStructure,ami);