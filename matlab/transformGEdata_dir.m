function [par, img] = transformGEdata_dir(path)
%   Looping function to read in multiple GE data files
%   
%   Usage: [par img] = transformGEdata_dir(path)
%   Author: R. Marc Lebel
%   Date: 04/05/2006
%   
%   Input:
%   path: directory name
%   
%   Output:
%   par: the header data from the first file
%   img: stack of images (in double format)

%   Use current directory as default
if nargin<1 || isempty(path)
    path = cd;
end
cd(path);

%   Obtain a directory listing
files = dir;
nfiles = size(files);
nfiles = nfiles(1);

%   Count the number of P-files
count = 0;
for i = 1:nfiles
    name = files(i).name;
    if length(name) > 4
        if strcmp(name(1),'P') && strcmp(name(end-1:end),'.7');
            %   Increment array size counter
            count=count+1;
            
            %   Read sample image to obtain size
            if count == 1
                [par,imgt] = transformGEdata(name);
            end
        end
    end
end

%   Inititalize image
img = zeros([size(imgt) count]);
img(:,:,:,:,:,1) = imgt;

%   Loop through files, determine if they are Pfiles, then read them in
count = 0;
for i = 1:nfiles
    name = files(i).name;
    if length(name) > 4
        if strcmp(name(1),'P') && strcmp(name(end-1:end),'.7');
            
            %   Increment array size counter
            count=count+1;
            
            %   If not the first image
            if count > 1
                %   Read data
                [par,imgt] = transformGEdata(name);
                
                %   Save image
                img(:,:,:,:,:,count) = imgt;
            end
        end
    end
end

end
