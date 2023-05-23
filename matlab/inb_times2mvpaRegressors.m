function Regressors = inb_times2mvpaRegressors(times,nFrames,TR,findBlocks,convHRF,thresh,doPlot,outTXT)
% Regressors = inb_times2mvpaRegressors(times,nFrames,TR,findBlocks,convHRF,thresh,doPlot,outTXT)
%
% Returns a matrix that can be fed to mvpa analyses (Princeton toolbox),
% with dimensions [nCategories x nTRs].
%
% times: A cell structure of file names. Each file contains the info of a
% particular category, and is referenced in seconds. In those files, each
% stimulus is represented in a row, in three-column format, as in:
%   onset duration value
%   onset duration value
%   ...
% (Note that this is the way that FEAT takes in stimulus info for the GLM.)
%
% nFrames: Number of volumes in the fMRI data set.
% TR: Repetition time in seconds.
% doPlot: true or false (default=false).
% 
% Luis Concha
% INB, UNAM
% lconcha@unam.mx
% December 2014.


if nargin < 6
   doPlot = false; 
   findBlocks = false;
   convHRF = false;
end

nSeconds = nFrames .* TR;

Regressors = zeros(length(times),nFrames);


% for f = 1 : length(times)
% thisReg = load(times{f});
% thisVols = zeros(nFrames,1);
%     for s = 1 : size(thisReg,1)
%         st  = round( thisReg(s,1) ./ TR ) +1;
%         dur = round( thisReg(s,2) ./ TR );
%         fin = st + dur;
%         thisVols(st:fin) = 1;
%         Regressors(f,:) = thisVols;
%     end
% end

% % my gaussian filter
% sigma = 550;
% size = 500;
% x = linspace(-size / 2, size / 2, size);
% gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
% gaussFilter = gaussFilter / sum (gaussFilter); % normalize);
% 


if convHRF
    [hrf,p] = spm_hrf(TR);
end



Time         = [0:1:(nSeconds.*1000)-1];
samplingTime = [0:TR:(nFrames.*TR)-1];
for f = 1 : length(times)
    thisSamples     = zeros(1,(nSeconds.*1000));
    thisReg = load(times{f});
    if findBlocks
         theseBlocks = [];
         st = thisReg(:,1);
         sp = thisReg(:,2);
         df = [0;st] - [st;1000];
         inflexions = find(abs(df) > abs(2.*median(df)));
         for inx = 1 : length(inflexions)-1
             b = inflexions(inx+1)-1;
             a = inflexions(inx);
             st = thisReg(a,1);
             sp = thisReg(b,1) + thisReg(b,2);
             dur = sp - st;
             theseBlocks = [theseBlocks;[st dur 1]];
         end
        thisReg = theseBlocks;
    end
        R            = zeros(1,nFrames);
        for s = 1 : length(thisReg)
           st  = round(thisReg(s,1) .* 1000);
           dur = round(thisReg(s,2) .* 1000);
           fin = st + dur;
           if ~isint(st) || ~isint(fin)
              disp(st); 
           end
           thisSamples(st+1:fin+1) = 1;
           % filter a little to account for imperfections in timings
%            thisSamplesF = conv (thisSamples, gaussFilter, 'same');
           try
            ti = interp1(Time,thisSamples,samplingTime.*1000);
           catch
             fprintf(1,'Stim %d in category %s is beyond alloted time\n', s,times{f});
             if st+1 < length(thisSamples)
                 thisSamples(st+1:end) = 1;
             end
           end
%            if convHRF
%                ti = conv(hrf,ti);
%                ti = ti(1:size(R,2));
%            end
           R = R + ti;
        end
    R = double(R>0);
    if convHRF
        rconv = conv(hrf,R);
        Regressors(f,:) = rconv(1:size(Regressors,2));
    else
        Regressors(f,:) = R;
    end
end

if thresh > 0
    R1 = Regressors;
    R1(R1<thresh) = 0;
%     R1(R1>0) = 1;
    Regressors = R1;
end

% add the REST condition
areRest = sum(Regressors) == 0;
Regressors(size(Regressors,1)+1,:) = areRest;
times{size(Regressors,1)} = 'rest';


% remove the .times suffix
for s = 1 : length(times)
   times{s} = strrep(times{s},'.times',''); 
end




if ~isempty(outTXT) & thresh>0
    fid = fopen(outTXT,'w');
    for frame = 1 : size(Regressors,2)
        [mx,ix] = max(Regressors(:,frame));
        thisCat = times{ix};
        fprintf(fid,'%s 1\n',thisCat);
    end
    fclose(fid);
end



if doPlot
    if thresh>0
       Regressors(Regressors>0) = 1; 
    end
    imagesc(-Regressors)
    colormap(gray)
    set(gca,'YTickMode','manual')
    set(gca,'YTick',[1:length(times)])
    set(gca,'YTickLabel',times)
    xlabel('frame') 
end