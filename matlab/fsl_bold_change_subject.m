function [pCentChange,n] = fsl_bold_change_subject(tsData,tsDataAllCopes,copePercent,doPlot)
% get Percent Bold Change from the time series data of a .feat result
% Per Subject
% [pCentChange,n] = fsl_bold_change_subject(tsData,tsDataAllCopes,copePercent,doPlot)
%
% Outputs:
%   pCentChange    :  The % change in BOLD signal during the block or event, as
%                  compared to the baseline BOLD.
%   n              :  The number of volumes that were used to get pCentChange.
%
% Inputs:
%   tsData         :  The time series data of the COPE of interest.
%                     For example: luis_e_loRes.feat/tsplot/tsplot_zstat9.txt
%   tsDataAllCopes :  The times series of a COPE that Must exist, in which
%                     all the EVs are used in the contrast. For example, if
%                     you have 3 EVs, this contrast would be [1 1 1] or
%                     [0.33 0.33 0.33].
%                     This can be found in the same directory as the
%                     tsData.
%   copePercent    :  The COPE waveform is curved, as it is already
%                     convolved with the HRF. This is a percentage of the
%                     height of the COPE above which you consider the
%                     stimulus to be active. The data is getting from those
%                     time points that satisfy this COPE > copePercent.
%                     This argument is optional; the default is 50%.
%   doPlot         :  True or false. Default is false.
%
% Luis Concha
% INB, UNAM, Dec. 2011.
%

if nargin < 3
   copePercent = 50;
end
if nargin < 4
   doPlot = false; 
end
copePercent = copePercent ./ 100;


data = load(tsData);


dataAllCopes = load(tsDataAllCopes);
delta = max(dataAllCopes(:,2)) - min(dataAllCopes(:,2));
copeThreshold = ( max(dataAllCopes(:,2)) ) - ( copePercent .* delta );
isAnyCope = dataAllCopes(:,2) > copeThreshold;
baseline = ~isAnyCope;          % this is when none of the COPES is active, ie the baseline.


volumes = [1:1:size(data,1)];



delta = max(data(:,2)) - min(data(:,2));
copeThreshold = ( max(data(:,2)) ) - ( copePercent .* delta );
isCope = data(:,2) > copeThreshold;
% make sure that the baseline and the cope do not overlap
%isCope(baseline+isCope==2) = 0;
n = sum(isCope);

ON  = mean(data(isCope,4));
OFF = mean(data(~isCope,4));
BASELINE = mean(data(baseline,4));
pCentChange = ((ON - BASELINE) ./ BASELINE) .* 100;





mBASELINE = repmat(BASELINE,1,length(volumes));

if doPlot
    isON = data(:,2);
    isON(~isCope) = NaN;
    dataON = data(:,4);
    dataON(~isCope) = NaN;
    
    plot(volumes,data(:,2),'k');        % full cope
    hold on;
    plot(volumes,data(:,4),'r');        %data
    plot(volumes,dataAllCopes(:,2),'g');        % all copes
    legend('COPE','DATA');
    plot(isON,'k','LineWidth',3);       % cope only on
    plot(dataON,'r','LineWidth',3);     % dataON
    plot([0 length(volumes)],[ON ON],  'r')
    plot([0 length(volumes)],[BASELINE BASELINE],'r')
    plot([0 length(volumes)],[copeThreshold copeThreshold],': k')
    plot(volumes(baseline),mBASELINE(baseline),'rs')
    title([num2str(pCentChange) '% change in BOLD signal'])
end