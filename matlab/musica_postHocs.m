% generar las pruebas post-hoc

fname = 'cluster_peak_left_FULL_copeData.txt';
copeData = load(fname);
copeNames = {'midi',...
             'violin',...
             'pianist',...
             'speech',...
             'nonvocal',...
             'vocallization',...
             'monkey'};
         

         
         
pianos       = [copeData(:,1);copeData(:,3)];
violin       = [copeData(:,2);nan(size(copeData(:,2)))];
speech       = [copeData(:,4);nan(size(copeData(:,4)))];
nonvocal     = [copeData(:,5);nan(size(copeData(:,5)))];
vocalization = [copeData(:,6);nan(size(copeData(:,6)))];
monkey       = [copeData(:,7);nan(size(copeData(:,7)))];

copeData = [pianos violin speech vocalization nonvocal monkey];
copeNames = {'pianos',...
             'violin',...
             'speech',...
             'vocallization',...
             'nonvocal',...
             'monkey'};      
         

ntests = ((size(copeData,2) .* size(copeData,2)) - size(copeData,2) ) ./2;
pvals = ones(size(copeData,2),size(copeData,2));        
for r = 1 : size(copeData,2)
    for c = 1 : size(copeData,2)
        [h,p] = ttest(copeData(:,r),copeData(:,c));
        pvals(r,c) = p;
    end
end
pthresh = 0.05 ./ ntests;  %%  Bonferroni correction!
pvals(isnan(pvals)) = 1;

figure;
ut = triu(pvals);
lt = tril(pvals);
pvals(ut==0) = 1;
imagesc(pvals);
set(gca,'XTickLabel',copeNames)
set(gca,'YTickLabel',copeNames)
set(gca,'CLim',[0 pthresh])
colormap(flipdim(hot,1))
colorbar
hold on
for r = 1 : size(copeData,2)
    for c = 1 : size(copeData,2)
        text(r-0.25,c,num2str(pvals(c,r),'%g'));
    end
end
title(fname,'Interpreter','None')

figure;
bar(nanmean(copeData),'FaceColor',[0.5 0.5 0.5]);
hold on
errorbar([1:1:size(copeData,2)],nanmean(copeData),nanstd(copeData) ./ sqrt(sum(~isnan(copeData))),'xk');
set(gca,'XTickLabel',copeNames)
title(fname,'Interpreter','None')
