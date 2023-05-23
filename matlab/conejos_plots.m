% script to make plots of rabbit data

%%%%%%%%%%%%%%%%%%
%load DTI2.mat
%%%%%%%%%%%%%%%%%%
%ROI = 2;
%%%%%%%%%%%%%%%%%%






excludeIndex = [4];
colors = {'k','r','b','g'};

savePlots = true;
base      = '/media/Porsche/conejos/figs/';

ROInames = {'Corpus callosum';...
            'Left internal capsule';...'
            'Right internal capsule';...
            'Left hippocampus dorsalis';...
            'Right hippocampus dorsalis';...
            'Left hippocampus ventralis';...
            'Right hippocampus ventralis';...
            'Basal ganglia';...
            'CSF'};


fprintf(1,'Now working on the %s (ROI %d)\n',ROInames{ROI},ROI);

        

%%  Plot absolute values
f_abs = figure;
for r = 1 : 4
   if intersect(r,excludeIndex)
      fprintf(1,'Skipping Rabbit %d\n',r);
      continue
   end
  for var = 1 : length(vars)
     subplot(2,3,var);
     eval(['x = scantime' num2str(r) ';'])
     eval(['y = squeeze(rabbit' num2str(r) '(:,var,ROI));'])
     eval(['e = squeeze(rabbit' num2str(r) '_std(:,var,ROI));'])
     color = colors{r};
     errorbar(x,y,e,color);
     set(gca,'XLim',[-10 800]);
     xlabel('Time (min)');
     ylabel(vars{var});
     title(ROInames{ROI})
     hold on;
     if var == 1 && r > 2
        legend('Rabbit 1','Rabbit 2','Rabbit 3')
     end
  end
end
if savePlots
   fname = [base 'abs_' ROInames{ROI} '.pdf'];
   print_pdf(fname,gcf);
end
close(f_abs);

%%  Plot relative values
f_rel = figure;
for r = 1 : 4
   if intersect(r,excludeIndex)
      fprintf(1,'Skipping Rabbit %d\n',r);
      continue
   end
  for var = 1 : length(vars)
     subplot(2,3,var);
     eval(['x = scantime' num2str(r) ';'])
     eval(['y = squeeze(rabbit' num2str(r) '(:,var,ROI));'])
     eval(['e = squeeze(rabbit' num2str(r) '_std(:,var,ROI));'])
     color = colors{r};
     e = (e ./ y)    .* 100;
     y = (y ./ y(1)) .* 100;  % get the percent from baseline
%      errorbar(x,y,e,color);
     plot(x,y,color);
     set(gca,'XLim',[-10 800]);
     if var ~= 1
        set(gca,'YLim',[0 100]);
     else
         set(gca,'YLim',[0 200]);
     end
     xlabel('Time (min)');
     ylabel([vars{var} ' (% from t=0)']);
     title(ROInames{ROI})
     hold on;
     if var == 1 && r > 2
        legend('Rabbit 1','Rabbit 2','Rabbit 3')
     end
  end
end
if savePlots
   fname = [base 'rel_' ROInames{ROI} '.pdf'];
   print_pdf(fname,gcf);
end
close(f_rel)




%% Let's see the temperature
i_temps1 = [scantime1 interp1(temps1(:,1),temps1(:,2),scantime1)];
i_temps2 = [scantime2 interp1(temps2(:,1),temps2(:,2),scantime2)];
i_temps3 = [scantime3 interp1(temps3(:,1),temps3(:,2),scantime3)];
i_temps4 = [scantime4 interp1(temps4(:,1),temps4(:,2),scantime4)];


ii_time   = [0:10:800];
ii_temps1 = interp1(temps1(:,1),temps1(:,2),ii_time);
ii_temps2 = interp1(temps2(:,1),temps2(:,2),ii_time);
ii_temps3 = interp1(temps3(:,1),temps3(:,2),ii_time);
ii_temps4 = interp1(temps4(:,1),temps4(:,2),ii_time);
ii_tempsAll = [ii_temps1;ii_temps2;ii_temps3;ii_temps4];
goodRabbits = setdiff([1:1:4],excludeIndex);
ii_tempsMean = mean(ii_tempsAll(goodRabbits,:));
ii_tempsStd  = std(ii_tempsAll(goodRabbits,:));


%  Plot absolute values
f_abs = figure;
for r = 1 : 4
   if intersect(r,excludeIndex)
      fprintf(1,'Skipping Rabbit %d\n',r);
      continue
   end
  for var = 1 : length(vars)
     subplot(2,3,var);
     eval(['y = squeeze(rabbit' num2str(r) '(:,var,ROI));'])
     eval(['e = squeeze(rabbit' num2str(r) '_std(:,var,ROI));'])
     eval(['x = i_temps' num2str(r) '(:,2);']);
     color = colors{r};
     errorbar(x,y,e,color);
     xlabel('Temperature (C)');
     ylabel(vars{var});
     title(ROInames{ROI})
     hold on;
     if var == 1 && r > 2
        legend('Rabbit 1','Rabbit 2','Rabbit 3')
     end
  end
end
if savePlots
   fname = [base 'abs_temp_vs_DTI_' ROInames{ROI} '.pdf'];
   print_pdf(fname,gcf);
end
close(f_abs)

% Plot relative values
f_rel = figure;
for r = 1 : 4
   if intersect(r,excludeIndex)
      fprintf(1,'Skipping Rabbit %d\n',r);
      continue
   end
  for var = 1 : length(vars)
     subplot(2,3,var);
     eval(['y = squeeze(rabbit' num2str(r) '(:,var,ROI));'])
     eval(['e = squeeze(rabbit' num2str(r) '_std(:,var,ROI));'])
     eval(['x = i_temps' num2str(r) '(:,2);']);
     color = colors{r};
     % normalize the temperatures too
     x = 100 - ((x ./ max(x)) .* 100);
     e = (e ./ y)    .* 100;
     y = (y ./ y(1)) .* 100;  % get the percent from baseline
     h = plot(x,y,color);
     ylabel(['% ' vars{var} ' from baseline'])
     xlabel('% Change in Temperature from baseline');
     title(ROInames{ROI})
     hold on;
     if var == 1 && r > 2
        legend('Rabbit 1','Rabbit 2','Rabbit 3')
     end
  end
end
if savePlots
   fname = [base 'rel_temp_vs_DTI_' ROInames{ROI} '.pdf'];
   print_pdf(fname,gcf);
end
close(f_rel)



%% Plot the temperature with respect to time
f_t = figure;
for r = 1 : 4
   if intersect(r,excludeIndex)
      fprintf(1,'Skipping Rabbit %d\n',r);
      continue
   end
     eval(['x = scantime' num2str(r) ';'])
     eval(['y = i_temps' num2str(r) '(:,2);']);
     color = colors{r};
     h = plot(x,y,color);
     ylabel(['Temperature (C)'])
     xlabel('Time from baseline (min)');
     title(ROInames{ROI})
     hold on;
     legend('Rabbit 1','Rabbit 2','Rabbit 3')
end
if savePlots
   fname = [base 'temp_vs_time_' ROInames{ROI} '.pdf'];
   print_pdf(fname,gcf);
end
close(f_t)


%% Simple plot of theoretical data
subplot(1,2,1);
h = plot(theory_temp,theory_ADC,'-sr');hold on;
vline([20 40],'k:');
hline([2.023 3.238],'k:');
xlabel('Temperature (C)');
ylabel('D_{H_2O} (m^2s^{-1})')
subplot(1,2,2);
index = find(theory_temp >19 & theory_temp <41);
h = plot(theory_temp(index),theory_ADC(index),'-sr');
ylabel('D_{H_2O} (m^2s^{-1})')
xlabel('Temperature (C)');
legend('Holtz et al.');
if savePlots
   fname = [base 'Holtz_data.pdf'];
   print_pdf(fname,gcf);
end
close(f_t)




%% Arrhenius plots
% minTemp = min(ii_tempsAll(:));
% maxTemp = max(ii_tempsAll(:));
minTemp = 20;
maxTemp = 40;
index        = find(theory_temp > minTemp & theory_temp < maxTemp);
theory_tempK = theory_temp + 273;
f            = figure;
subplot(1,2,1);
[lfit1,eq1,hf1,h2] = arrhenius_plot(theory_temp,theory_ADC);
legend({'Holts et al.';'linear fit'});
xlabel('(1000/T)/K^{-1}')
ylabel('log(D_{H_2O}) (m^2s^{-1})')
text(2.7,-20.5,eq1);


subplot(1,2,2);
[lfit2,eq2,hf2,h2] = arrhenius_plot(theory_temp(index),theory_ADC(index));
legend({'Holts et al.';'linear fit'});
xlabel('(1000/T)/K^{-1}')
ylabel('log(D_{H_2O}) (m^2s^{-1})')
text(3.15,-20,eq2);


%% Linear fit of log function in Celcius, easier to use
f       = figure;
subplot(1,2,1);
h       = plot(theory_temp(index), log(theory_ADC(index)), '-sk');
lfit3   = polyfit(theory_temp(index), log(theory_ADC(index)),1);
hf3     = refline(lfit3(1),lfit3(2));
set(hf3,'LineStyle','--','Color','r');
legend({'Holtz et al.';'linear fit'});
eq3 = ['log(D) = ' num2str(lfit3(1)) '(degrees C) + ' num2str(lfit3(2))]; hold on;
xlabel('T (C)')
ylabel('log(D_{H_2O}) (m^2s^{-1})')
text(22,0.7,eq3,'FontSize',12);


subplot(1,2,2);
h       = plot(theory_temp(index), theory_ADC(index), '-sk');
hold on;
T = [20:1:40];
plot(T,ADC_predict(T),'r');
title('Error using a mono-exponential fit within temperature range');
xlabel('T (C)')
ylabel('D_{H_2O} (m^2s^{-1})')
if savePlots
   fname = [base 'Holtz_fit.pdf'];
   print_pdf(fname,gcf);
end
close(f_t)



%% Linear fit of log function in Celcius, easier to use,
% but in terms of relative values!!!
x = theory_temp(index);
delta_x = (x./max(x)).*100;
y = theory_ADC(index);
delta_y = (y./max(y)).*100;  % get the percent from max (call it baseline)
log_delta_y = log(delta_y);

subplot(1,2,1)
h       = plot(delta_x, log_delta_y, '-sk');

lfit_DTheory   = polyfit(delta_x, log_delta_y ,1);
hf3     = refline(lfit_DTheory(1),lfit_DTheory(2));
set(hf3,'LineStyle','--','Color','r');
legend({'Holts et al.';'linear fit'});
eq3 = ['log(%\Delta D_{T=40}) = ' num2str(lfit_DTheory(1)) '(%\Delta T) + ' num2str(lfit_DTheory(2))]; hold on;
xlabel('%\Delta T (C) from baseline (T=40C)')
ylabel('log(%\Delta D_{T=40})')
text(75,4.6,eq3,'FontSize',12);


subplot(1,2,2)
T = [20:40];
delta_T = (T ./ max(T)) .* 100;
hpc = plot(delta_T,exp((lfit_DTheory(1) .* delta_T) + lfit_DTheory(2)),'o-r');
xlabel('\Delta T (%)');
ylabel('\Delta D(%)');
set(gca,'YLim',[50 100]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This means that if T drops by 1%, we get a drop in D of around .66%
% remaining_D_percent = exp((lfit_DTheory(1) .* percent_temp) + lfit_DTheory(2)) - 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Now that we have a linear fit to the %D drop due to delta T, we can see
%% if the model fits the data

tempsVector = [100:-1:35];
tDrop_pcent = calc_drop_percent_D(lfit_DTheory,tempsVector);

f_rel = figure;


subplot(1,2,1);
hf = plot(100 - tempsVector, ...
           100 + tDrop_pcent, ...
           'LineStyle','--','Color','m');
hold on;
for r = 1 : 4
    if intersect(r,excludeIndex)
      fprintf(1,'Skipping Rabbit %d\n',r);
      continue
    end
    subplot(1,2,1);
    var = 2 % only do ADC
    eval(['y = squeeze(rabbit' num2str(r) '(:,var,ROI));'])
    eval(['e = squeeze(rabbit' num2str(r) '_std(:,var,ROI));'])
    eval(['x = i_temps' num2str(r) '(:,2);']);
    color = colors{r};
    x = 100 - ((x ./ max(x)) .* 100);
    e = (e ./ y)    .* 100;
    y = (y ./ y(1)) .* 100;  % get the percent from baseline
    yi = interp1(100 - tempsVector,100 + tDrop_pcent,x)
    h = plot(x,y,color);
    ylabel(['% ' vars{var} ' from baseline'])
    xlabel('% decrease in Temperature from baseline');
    title(ROInames{ROI})
    hold on;
    
    subplot(1,2,2);
    h = plot(x,y-yi,color);
    title(ROInames{ROI})
    ylabel(['Actual - predicted value (% ' vars{var} ' from baseline)'])
    xlabel('% decrease in Temperature from baseline');
    hold on;
end
subplot(1,2,1);
axis square
legend('Predicted','Rabbit 1','Rabbit 2','Rabbit 3');
set(gca,'XLim',[0 40]);
set(gca,'YLim',[30 100])
subplot(1,2,2);
axis square
set(gca,'XLim',[0 40]);
set(gca,'YLim',[-50 0])
if savePlots
   fname = [base 'rel_change_with_rel_change_temp_' ROInames{ROI} '.pdf'];
   print_pdf(fname,gcf);
end
close(f_rel)





