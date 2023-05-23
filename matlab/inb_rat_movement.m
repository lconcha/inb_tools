function inb_rat_movement(f,doMovie,twindow)
% function inb_rat_movement(f,doMovie,twindow)
% f: filename
% doMovie true|false
% twindow: integer. Defines temporal smoothing (at this moment this is
% simply timepoints, not seconds or anything meaningful. Default is 1,
% which means no smoothing).


if nargin <3
   doMovie = false;
   twindow = 1; % twindow of 1 means no temporal smoothing of signal
end

if nargin <2
   doMovie = false; 
end


warning off


% load the data
d = load(f);

% parse the data
t = d(:,1);
x = d(:,2);
y = d(:,3);

% smooth the data
x = movmean(x,twindow);
y = movmean(y,twindow);
t = movmean(t,twindow);


% make a time series from the first derivative of the displacements in x
% and y
tsd = timeseries([diff(x) diff(y)],t(2:end),'Name','Displacement (cm)');
tsd.TimeInfo.Format = 'hh:mm:ss';
tsd.TimeInfo.StartDate = '00:00:00';


figure;
set(gcf,'Renderer','painters');
hl = plot(x,y,'-k');
hold on
scatter(x,y,'MarkerFaceColor','k','MarkerFaceAlpha',0.1,'MarkerEdgeAlpha',1,'MarkerEdgeColor','none')
set(gca,'XLim',[min(x) max(x)]);
set(gca,'YLim',[min(y) max(y)]);
axis square


figure;
plot(tsd)
legend('x','y')


if doMovie
    figure
    set(gcf,'Renderer','painters');
    scatter(min(x),min(y));
    set(gca,'XLim',[min(x) max(x)]);
    set(gca,'YLim',[min(y) max(y)]);
    hold on;
    axis square
    for i = 1 : length(t)
       sh = scatter(x(i),y(i),'MarkerFaceColor','r');
       drawnow
       set(sh,'MarkerFaceColor','b','MarkerEdgeColor','b',...
        'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
       drawnow
    end
end
