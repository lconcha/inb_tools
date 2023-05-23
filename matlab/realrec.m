function [img2,pmap] = realrec(img,simg,kc)
%   Recostruct real image. Useful for IR images
%   Required functions: butter2 (RML)
%   
%   Usage: [img2,pmap] = realrec(img,simg,kc)
%   Author: Marc Lebel
%   Date: 10/2006
%   
%   Input:
%   img = the image matrix of size m x n
%   simg = a low contrast image (optional, but can improve reconstruction)
%   kc = frequency filter cutoff. Default: 0.1
%   
%   Output:
%   img2 = an image that lies on the +- real axis
%   pmap = the +-1 phase map

%   Check input arguments
if nargin < 1 || ~isnumeric(img)
    error('realrec: function requires at least one input')
end
if nargin < 2 || isempty(simg) || ~isnumeric(simg)
    simg = img;
end
if nargin < 3 || ~isnumeric(kc)
    kc = 1;
end

%   Get and test image sizes
s = size(img);
if length(s) ~= 2
    error('realrec: input image must be of size M x N');
end
if size(simg) ~= s
    error('realrec: reference image must be same size as input image');
end

%   Generate low pass filtered image
simg = fft2(fftshift(butter2(ifftshift(ifft2(simg)),kc)));

%   Generate phase corrected image
img2 = img .* exp(-i*angle(simg));

%   Isolate common phase regions to push onto real axis
%   This stage might cause some errors
ind = find(abs(angle(img2)) >= pi/2);
pmap = ones(s);
pmap(ind) = -pmap(ind);

%   Invert common phase regions
img2 = abs(img2).*pmap;
