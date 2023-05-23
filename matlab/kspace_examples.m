% make some nice k space examples

clear;
dirtosave = '/home/lconcha/Desktop/tmp/';

load mri;
im = D(:,:,1,15);
im = flipdim(im,1);
F = fft2(im);
Fs = fftshift(fft2(im));
thisK = zeros(size(Fs));
for r = 1 : 2 : size(im,1)
   for c = 1 : 1 : size(im,2)
       %thisK = zeros(size(Fs));
       thisK(r,c) = Fs(r,c);
       thisIm = abs(fft2(thisK));
       subplot(1,2,1)
       thisKshow = abs(log(thisK));
       thisKshow(isinf(thisKshow)) = 0;
       thisKshow(isnan(thisKshow)) = 0;


       
   end
   imagesc(thisKshow);colormap(gray);axis image;axis off; %title('Espacio k');
   subplot(1,2,2)
   imagesc(abs(thisIm));colormap(gray);axis image;axis off; %title('Imagen');
   drawnow
end

% now some special k space cases
mask = false(size(Fs));
%mask(64-10:64+10,64-10:64+10) = true;
% mask(end-30:end,:) = true;
% mask(1:30,:) = true;
%mask(64,64) = true;
mask(1:75,:) = true;
thisK = zeros(size(Fs));
thisK(mask) = Fs(mask);
% thisK(30,30) = max(thisK(:)); % a spike
thisIm = abs(fft2(thisK));
subplot(1,2,1)
thisKshow = abs(log(thisK));
thisKshow(isinf(thisKshow)) = 0;
thisKshow(isnan(thisKshow)) = 0;
imagesc(thisKshow);colormap(gray);axis image;axis off; title('Espacio k');
subplot(1,2,2)
imagesc(abs(thisIm));colormap(gray);axis image;axis off; title('Imagen');
drawnow
set(gcf,'Color',[0.1 0.1 0.1])
