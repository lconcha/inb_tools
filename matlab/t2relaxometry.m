function t2map = t2relaxometry(vol,echoes,threshold)
%
% t2map = t2relaxometry(vol,echoes)
%
% t2map : a 3D volume of quantitative T2 values
% vol   : a 4D array where the 4th dimension is the different TEs.
% echoes: a [1 x nEchoes] vector of TEs in ms.
%         example: [7.056 14.112 21.168 28.224 35.28 42.336 49.392 56.448];
% threshold: do not compute T2 if signal in TE1 < threshold. Default: 300
%
% Luis Concha
% INB, UNAM
% Julio 2010


if nargin <3
   threshold = 300; 
end


te = double(echoes);


nVox = size(vol,1) .* size(vol,2) .* size(vol,3);
nTEs = size(vol,4);

t2map = nan(size(vol,1) , size(vol,2) , size(vol,3));
vol_r = reshape(vol, nVox, nTEs);

mask = find(vol_r(:,1) > threshold);


fprintf(1,'\n');
progress('init');
nVox = numel(mask);
for j = 1 : nVox
  i = mask(j);
  if mod(j,10000)==0
    progress(j/nVox, sprintf('Computing T2 for voxel %d/%d',j,nVox));
  end  
  signal = double(squeeze(vol_r(i,:)));
  if signal(1) < threshold
     continue 
  end
  try
    fit = polyfit(te,log(signal),1);
  catch
    fit = NaN;
  end
  t2_value = exp(fit(1));
  t2map(i) = t2_value;
end
% progress('close');
fprintf(1,'\nDone!\n');