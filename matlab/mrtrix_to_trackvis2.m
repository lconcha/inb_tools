function tracts = mrtrix_to_trackvis2(filename, fibers)
% the results are stored in a cell array where each cell represents a tract with dimesion [number of points] x [3]
% open the file for reading
fid = fopen(filename, 'wb');
% id_string[6], char, 6, ID string for track file. The first 5 characters must be "TRACK".
fwrite(fid, ['T';'R';'A';'C';'K';char(0)], 'char');
% dim[3], short int, 6, Dimension of the image volume.
fwrite(fid, [110; 110; 110], 'int16');
% voxel_size[3], float, 12, Voxel size of the image volume.
fwrite(fid, [1; 1; 1], 'float');
% origin[3], float, 12, Origin of the image volume. This field is not yet being used by TrackVis. That means the origin is always (0, 0, 0).
fwrite(fid, [0; 0; 0], 'float');
% n_scalars, short int, 2, Number of scalars saved at each track point (besides x, y and z coordinates).
fwrite(fid, 0, 'int16');
% scalar_name[10][20], char, 200, Name of each scalar. Can not be longer than 20 characters each. Can only store up to 10 names.
fwrite(fid, empty_char(200,1), 'char');
% n_properties, short int, 2, Number of properties saved at each track.
fwrite(fid, 0, 'int16');
% property_name[10][20], char, 200, Name of each property. Can not be longer than 20 characters each. Can only store up to 10 names.
fwrite(fid, empty_char(200,1), 'char');
% vox_to_ras[4][4], float, 64, 4x4 matrix for voxel to RAS (crs to xyz) transformation. If vox_to_ras[3][3] is 0, it means the matrix is not recorded. This field is added from
%version 2.
%fwrite(fid, [0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 5], 'float32');
fwrite(fid, [1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1], 'float');
% reserved[444], char, 444, Reserved space for future version.
fwrite(fid, empty_char(444,1), 'char');
% voxel_order[4], char, 4, Storing order of the original image data. Explained here.
fwrite(fid, ['L';'A';'S';char(0)], 'char');
% write into the trackvis formatfunction tracts = write_trackvis(filename, fibers)
% the results are stored in a cell array where each cell represents a tract with dimesion [number of points] x [3]
% open the file for readingfid = fopen(filename, 'wb');
% id_string[6], char, 6, ID string for track file. The first 5 characters must be "TRACK".fwrite(fid, ['T';'R';'A';'C';'K';char(0)], 'char');
% dim[3], short int, 6, Dimension of the image volume.fwrite(fid, [110; 110; 110], 'int16');
% voxel_size[3], float, 12, Voxel size of the image volume.fwrite(fid, [1; 1; 1], 'float');
% origin[3], float, 12, Origin of the image volume. This field is not yet being used by TrackVis. That means the origin is always (0, 0, 0).fwrite(fid, [0; 0; 0], 'float');
% n_scalars, short int, 2, Number of scalars saved at each track point (besides x, y and z coordinates).fwrite(fid, 0, 'int16');
% scalar_name[10][20], char, 200, Name of each scalar. Can not be longer than 20 characters each. Can only store up to 10 names.fwrite(fid, empty_char(200,1), 'char');
% n_properties, short int, 2, Number of properties saved at each track.fwrite(fid, 0, 'int16');
% property_name[10][20], char, 200, Name of each property. Can not be longer than 20 characters each. Can only store up to 10 names.fwrite(fid, empty_char(200,1), 'char');
% vox_to_ras[4][4], float, 64, 4x4 matrix for voxel to RAS (crs to xyz) transformation. If vox_to_ras[3][3] is 0, it means the matrix is not recorded. This field is added from version 2.%fwrite(fid, [0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 5], 'float32');fwrite(fid, [1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1], 'float');
% reserved[444], char, 444, Reserved space for future version.fwrite(fid, empty_char(444,1), 'char');
% voxel_order[4], char, 4, Storing order of the original image data. Explained here.fwrite(fid, ['L';'A';'S';char(0)], 'char');
% pad2[4], char, 4, Paddings.
fwrite(fid, empty_char(4,1), 'char');
% image_orientation_patient[6], float, 24, Image orientation of the original image. As defined in the DICOM header.
fwrite(fid, [1;0;0;0;1;0], 'float');
 
% pad1[2], char, 2, Paddings.
fwrite(fid, empty_char(2,1), 'char');
 
% invert_x, unsigned char, 1, Inversion/rotation flags used to generate this track file. For internal use only.
fwrite(fid, 0, 'uchar');
 
% invert_y, unsigned char, 1, As above.
fwrite(fid, 0, 'uchar');
 
% invert_x, unsigned char, 1, As above.
fwrite(fid, 0, 'uchar');
 
% swap_xy, unsigned char, 1, As above.
fwrite(fid, 0, 'uchar');
 
% swap_yz, unsigned char, 1, As above.
fwrite(fid, 0, 'uchar');
 
% swap_zx, unsigned char, 1, As above.
fwrite(fid, 0, 'uchar');
 
% n_count, int, 4, Number of tracks stored in this track file. 0 means the number was NOT stored.
fwrite(fid, length(fibers), 'int');
 
% version, int, 4, Version number. Current version is 2.
fwrite(fid, 2, 'int');
 
% hdr_size, int, 4, Size of the header. Used to determine byte swap. Should be 1000.
fwrite(fid, 1000, 'int');
 
% write the fibers
for i = 1:length(fibers)
 
    % pull out the points
    points = fibers{i};
 
    % write number of points
    fwrite(fid, size(points,1), 'int');
 
    % write each point
    for j=1:size(points,1)
        fwrite(fid, points(j,:), 'float');
    end
end
% close the file.
fclose(fid);
end
function new_char = empty_char(m, n)
i=1;
a=char(0);
new_char=char(0);
while i<m*n
    new_char=[new_char;a];
    i=i+1;
end
new_char = reshape(new_char, m, n);
end