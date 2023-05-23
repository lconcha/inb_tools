function [par,img,k_out] = transformGEdata(par,k_out)
%   Reshapes and Fourier transforms GE data
%   Requires: readGEheader.m and readGEdata.m
%   
%   Author:
%   R Marc Lebel
%   11/2010
%   
%   Usage:
%   [par, img, k_out] = transformGEdata(par,k_in); OR
%   [par, img, k_out] = transformGEdata(pfile); OR
%   [par, img, k_out] = transformGEdata;
%   
%	Input:
%   par: parameter structure from readGEheder.m or readGEdata.m
%   k_in: k-space data from readGEdata.m
%   -----OR-----
%   pfile
%   -----OR-----
%   (none)
%   
%	Output (optional):
%   par: returns the GE parameter structure
%	img: reshaped and Fourier transformed version of k_in
%   k_out: reshaped version of k_in
%   
%   Note: This function is under development. It is unlikely to properly
%   reconstruct all imaging sequences.

%   Check input parameters
if nargin > 3
    error('Function requires either zero/one OR two input variables');
end

%   If no input check for a .7 file, use the first one
if nargin == 0
    files = dir('*.7*');
    if isempty(files)
        error('No P*****.7 files in current directory');
    end
    pfile = files(1).name;
    fprintf('No file specifed. Reading from %s\n',pfile);
    clear files
    [par,k_out] = readGEdata(pfile);
end

%   If one input
if nargin == 1
    if ~isa(par,'char') || length(par) < 3
        error('File input must be a string');
    end
    if ~strcmp(par(end-1:end),'.7')
        par = [par '.7'];
    end
    if ~strcmp(par(1),'P')
        par = ['P' par];
    end
    if exist(par,'file') ~= 2
        error('Pfile does not exist');
    end
    pfile = par;
    [par,k_out] = readGEdata(pfile);
end

%   Try to detect the number of receiver coils (may be a better way)
if strcmp(par.image.cname,'8HRBRAIN')
    nrcvrs = 8;
else
    nrcvrs = 1;
end

%   Check that parameters and data are consistent
if ~isstruct(par)
    error('Parameter input must be the GE parameter structure');
end
if numel(k_out) ~= par.rdb.da_xres*par.rdb.da_yres*nrcvrs*...
        par.rdb.nslices*par.rdb.nechoes/(par.rdb.nphases)
    error('Inconsistent parameter and data size');
end

%   Reshape and permute data into read x phase x slice x echo x receiver
k_out = reshape(k_out,[par.rdb.da_xres, par.rdb.da_yres,...
    par.rdb.nechoes, par.rdb.nslices/(par.rdb.npasses), nrcvrs]);
k_out = permute(k_out,[1 2 4 3 5]);

%   Remove non-image data (the first line and phase correction data)
%k_out = k_out(:,2:par.rdb.da_yres-par.rdb.retro_control,:,:,:);
k_out = k_out(:,2:par.rdb.da_yres-par.rdb.etl,:,:,:);

%   Apply homodyne reconstruction for partial ky
% if par.image.nex < 1
%     nv_full = round((par.rdb.da_yres - 1 - par.rdb.retro_control) / par.image.nex);
%     kt = zeros(par.rdb.da_xres,nv_full,...
%         par.rdb.nslices/(par.rdb.npasses),nrcvrs);
%     for i = 1:nrcvrs
%         kt(:,:,:,i) = flipdim(pifft2(flipdim(k_out(:,:,:,i),2),nv_full),2);
%     end
%     k_out = kt;
%     clear kt i nv_full;
% end

%   2D Fourier transform the data
% img = fftshift(fftshift(ifft(ifft(ifftshift(ifftshift(k_out,1),2),[],1),[],2),1),2);
img = ift2d(k_out);
img = fftshift(fftshift(img,1),2);

%   Sort images
ind = zeros(1,par.rdb.nslices/(par.rdb.npasses));
for i = 1:par.rdb.nslices/(par.rdb.npasses)
    ind(i) = par.daqtab(i).slice_in_pass;
end
img = img(:,:,ind,:,:);
k_out = k_out(:,:,ind,:,:);

end
