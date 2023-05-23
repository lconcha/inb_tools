function my_LDA(data,group,varNames) 

gplotmatrix(data,data,group,'kr','..',[],'on','',varNames,varNames)


% Perform the LDA with leave one out training



for ex = 1 : size(data,1)
    data2 = data;
    g = group;
    data2(ex,:) = [];
    g(ex) = [];
    [class,err(ex)] = classify(data,data2,g);
end

fprintf(1,'Accuracy of classifier is %g\n',1-mean(err));