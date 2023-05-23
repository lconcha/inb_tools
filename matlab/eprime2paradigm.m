function paradigm = eprime2paradigm(eprimeTxtFile,ColumnName,categoriesBaseName,cluster,doPlot,writeTimes)
% paradigm = eprime2paradigm(eprimeTxtFile,ColumnName,categoriesBaseName,doPlot)

if nargin < 4
   doPlot  = false; 
   cluster = false;
end
if nargin < 5
    doPlot = false;
end
if nargin < 6
    writeTimes = true;
end




%% Read the eprime file
% first convert to ascii standard
tmpfile = '/tmp/tmpmatlabfile.txt';
[status,result] = system(['iconv -f UNICODELITTLE ' eprimeTxtFile ' > ' tmpfile]);

% now read it
[j,b] = readtext(tmpfile,'[\t]');
[status,result] = system(['rm -f ' tmpfile]);



% remove the first line, as it is the title
pname = j{1,1};
j = j (2:end,:);

quotes1 = 'â';
quotes2 = 'â';

for c = 1:size(j,2)
   var = j{1,c};
   var = strrep(var,quotes1,'');
   var = strrep(var,quotes2,'');
   var = strrep(var,'"','');
   dt  = j(2:end,c);
   
   if iscell(dt)   
       for r = 1 : size(dt,1)
           if ischar(dt{r,1})
              dt(r,1) = strrep(dt(r,1),quotes1,'');
              dt(r,1) = strrep(dt(r,1),quotes2,'');
              dt(r,1) = strrep(dt(r,1),'"','');
           end
       end
   end
   
   
   try
       dt = cell2mat(dt);
   catch
       disp('.');
   end
   eval(['vars.' var '=dt;'])

end
data = vars;




%% Get the columns we want
onsetTime = data.Slide1.OnsetTime - data.Dummies.OnsetTime;
duration  = data.SoundDuration;
eval(['[y,idxNames] = grp2idx(data.' ColumnName ');'])

paradigm.onsetTime      = onsetTime;
paradigm.idx            = y;
paradigm.idxNames       = idxNames;
paradigm.duration       = duration;


for c = 1 : length(idxNames)
   ticks{c} = [num2str(c) ': ' idxNames{c}]; 
end


fprintf(1,'The categories are:\n');
for category = 1 : length(paradigm.idxNames)
    fprintf(1,' %d: %s\n',category,paradigm.idxNames{category});
end



docats = false;
if ~isempty(categoriesBaseName)
    if cluster
        want = input('Do you want to cluster some categories? Y/N [N]:\n','s');
        if ~isempty(strmatch(want,'y') )
           docats = true;
           ncats = input('How many categories do you want?\n');
           for cc = 1 : ncats
              cn = input(['Enter the name for category ' num2str(cc) '\n'],'s');
              cv = input(['Enter the indices for category ' num2str(cc) '\n']);
              ccnn = paradigm.idxNames(cv);
              eval(['categories.' cn ' = ccnn';])
           end
        end
    else
        for c = 1 : length(paradigm.idxNames)
            thisCat = paradigm.idxNames{c};
            eval(['categories.' paradigm.idxNames{c} '= thisCat;'])
            docats = true;
        end
    end
end



%% prepare the data for fsl files
if docats
    cats = fieldnames(categories);
    indicesUsed = [];
    for catg = 1 : length(cats)
        thisCat = cats{catg};
        fname = [categoriesBaseName thisCat '.times'];
        if writeTimes
            fid = fopen(fname,'w');
        end
        eval(['[strs,index1,index2] = intersect(paradigm.idxNames,categories.' thisCat ');'])
        cate{catg,:} = index1;
        for r = 1:length(paradigm.idx)
            go = ~isempty(intersect(paradigm.idx(r),index1));
            if go
                if writeTimes
                    fprintf(fid,'%1.3f %1.3f 1\n',paradigm.onsetTime(r)./1000, paradigm.duration(r)./1000);
                end
                indicesUsed = [indicesUsed;r];
            end
        end
        if writeTimes
            fclose(fid);
        end
    end
    
    if writeTimes
        fname = [categoriesBaseName 'dummyVar.times'];
        fid = fopen(fname,'w');
        missingOnes = setdiff([1:1:length(paradigm.idx)],indicesUsed);
        for j = 1:length(missingOnes)
            r = missingOnes(j);
            fprintf(fid,'%1.3f %1.3f 1\n',paradigm.onsetTime(r)./1000, paradigm.duration(r)./1000);
        end
        fclose(fid);
    end
end



%% Plot, if needed.
colors = jet(size(cate,1));
if doPlot
    f = figure;
    plot(paradigm.onsetTime./1000,y,'.')
    
    set(gca,'YLim',[0.5 length(ticks)+0.5])
    set(gca,'YTick',[1:1:max(y)])
    set(gca,'YTickLabel',ticks)
    
    
    xlabel('time (s)')
    title(eprimeTxtFile,'Interpreter','None')
    if docats
        hold on;
        for catg = 1 : length(cats)
           indices = cate{catg,:};
           colr = colors(catg,:);
           h = plot(zeros(size(indices)),indices,'s','MarkerFaceColor',colr);
           if writeTimes
               try
                   figFname = [categoriesBaseName 'paradigm.png'];
                   print_pdf(figFname,gcf);
               catch
                   disp(lasterr)
                   try
                       figFname = [categoriesBaseName 'paradigm.png'];
                       saveas(h,figFname);
                   catch
                       disp(lasterr)
                       fprintf(1,'ERROR: Cannot save the paradigm figure\n'); 
                   end
               end
           end
        end
    end
end

