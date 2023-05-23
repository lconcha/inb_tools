function F = ift2d(F,shift)
%   Computes the [shifted] 2D ifft

if nargin < 2 || isempty(shift)
    shift = 1;
end

if shift
%     F = fftshift(fftshift(ifft(ifft(ifftshift(ifftshift(F,1),2),[],1),[],2),1),2);
    F = ifft(ifft(ifftshift(ifftshift(F,1),2),[],1),[],2);

else
    F = ifft(ifft(F,[],1),[],2);
end

