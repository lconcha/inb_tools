function correlation_matrix(data,labels,pthresh,doSubplots)


if nargin < 4
   doSubplots = false; 
end

if nargin<3
   pthresh = 0.05; 
end

if nargin < 2
   labels = [1:1:size(data,2)]; 
   labels = {labels};
end

for lb = 1 : length(labels)
   jjj = labels{lb};
   Xlabels{lb} = jjj(1);
end


if nargin < 2
   Xlabels = labels;
end


cmap1 = spring(10);
cmap2 = winter(10);
myCmap = [flipdim(cmap1,1);[0 0 0];cmap2];

if doSubplots
   myCmap = jet(20); 
end


for xx = 1 : size(data,2)
    for yy = 1 : size(data,2)
        x = data(:,xx);
        y = data(:,yy);
        nan1 = isnan(x);
        nan2 = isnan(y);
        arenans = logical(nan1+nan2);
        [R,P] = corr(x(~arenans),y(~arenans));
        r(xx,yy) = R;
        p(xx,yy) = P;
    end
end
    

rt = r;
rt(p > pthresh) = 0;





if doSubplots
    subplot(1,3,1)
    imagesc(r);
    set(gca,'YTick',[1:1:size(data,2)])
    set(gca,'YTickLabel',labels)
    set(gca,'XTick',[1:1:size(data,2)])
    set(gca,'XTickLabel',Xlabels)
    title('r values')
    colormap(myCmap)
    colorbar
    set(gca,'CLim',[-1 1]);
    
    
    subplot(1,3,2)
    imagesc(p);
    set(gca,'YTick',[1:1:size(data,2)])
    set(gca,'YTickLabel',Xlabels)
    set(gca,'XTick',[1:1:size(data,2)])
    set(gca,'XTickLabel',Xlabels)
    title('p values')
    colormap(jet)
    colorbar
    set(gca,'CLim',[0 0.5]);
    
    
    subplot(1,3,3)
    imagesc(rt);
    set(gca,'YTick',[1:1:size(data,2)])
    set(gca,'YTickLabel',Xlabels)
    set(gca,'XTick',[1:1:size(data,2)])
    set(gca,'XTickLabel',Xlabels)
    title('thresholded r values')
    colorbar
    colormap(myCmap)
    set(gca,'CLim',[-1 1]);
else
    imagesc(rt);
    set(gca,'YTick',[1:1:size(data,2)])
    set(gca,'YTickLabel',labels)
    set(gca,'XTick',[1:1:size(data,2)])
    set(gca,'XTickLabel',Xlabels)
    title('thresholded r values')
    colorbar
    colormap(myCmap)
    set(gca,'CLim',[-1 1]); 
end



