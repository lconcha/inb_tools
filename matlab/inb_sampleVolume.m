function image_values = inb_sampleVolume(image_Fname,wSurfCoordsFname,outFile);
% image_values = inb_sampleVolume(image_Fname,wSurfCoordsFname,[outFile]);
%
% Takes in a txt file with nx3 size that are x,y,z world coordinates and
% samples image_Fname (nifti) using nearest_neighbour interpolation.
% Nothing fancy.
% If a third argument is specified, then it will write a text file with the
% values per coordinates in outFile.
%
% Luis Concha
% INB, UNAM
% 2012

disp('Entering inb_sampleVolume');
fprintf(1,'image_Fname :\t\t %s\nwSurfCoordsFname : \t %s\noutFile :\t\t %s\n',image_Fname,wSurfCoordsFname,outFile);

writeTXT = false;
if nargin > 2
   writeTXT = true; 
end

v   = load(wSurfCoordsFname);
[h,IMAGE]    = niak_read_nifti(image_Fname);

vVoxelSpace  = round(transformPoint3d(v,inv(h.info.mat))) +1;

image_values = nan(length(v),1);
for vx = 1 : length(vVoxelSpace)
    thisV = vVoxelSpace(vx,:);
    try
      image_values(vx) = IMAGE(thisV(1),thisV(2),thisV(3));
    catch
      image_values(vx) = 0;
    end
end

if writeTXT
    fprintf(1,'Writing to file: %s\n',outFile);
    fid = fopen(outFile,'w');
    fprintf(fid,'%g\n',image_values);
    fclose(fid);
end

disp('Done');
