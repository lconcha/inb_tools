function aparc_simplify(aparc,simple)


[hdr,aparcVol] = niak_read_nifti(aparc);
simpleVol = zeros(size(aparcVol));

id.rh.thalamus		= [49];
id.rh.precentral	= [2024];
id.rh.postcentral	= [2022];
id.rh.frontal		= [2003 2012 2014 2017 2018 2019 2020 2027 2028 2032];
id.rh.temporal		= [2001 2006 2007 2009 2015 2016 2030 2033 2034];
id.rh.parietal		= [2008 2010 2025 2029 2031];
id.rh.occipital		= [2005 2011 2013 2021];
id.rh.insula		= [2035];
id.rh.limbic		= [54 53 2023 2002 2026];

id.lh.thalamus		= [10];
id.lh.precentral	= [1024];   
id.lh.postcentral	= [1022];
id.lh.frontal		= [1003 1012 1014 1017 1018 1019 1020 1027 1028 1032];
id.lh.temporal		= [1001 1006 1007 1009 1015 1016 1030 1033 1034];
id.lh.parietal		= [1008 1010 1025 1029 1031];
id.lh.occipital		= [1005 1011 1013 1021];
id.lh.insula		= [1035];
id.lh.limbic		= [17 18 1023 1002 1026];


newIDs.thalamus     = [1 2];
newIDs.precentral   = [3 4];
newIDs.postcentral  = [5 6];
newIDs.frontal      = [7 8];
newIDs.temporal     = [9 10];
newIDs.parietal     = [11 12];
newIDs.occipital    = [13 14];
newIDs.insula       = [15 16];
newIDs.limbic       = [17 18];


anatStructures = {'thalamus','precentral','postcentral','frontal','temporal','parietal','occipital','insula','limbic'};


hemis = {'lh','rh'};
for H = 1 : length(hemis)
    hemi = hemis{H};
    if strmatch(hemi,'lh')
       side = 1; 
    else
       side = 2;
    end
    for A = 1 : length(anatStructures)
        thisStructure = anatStructures{A};
        eval(['theseIndices  = id.' hemi '.' thisStructure ';'])
        eval(['thisNewIndex  = newIDs.' thisStructure '(side);'])
        for i = 1 : length(theseIndices)
           fprintf(1,'Changing %d to %d\n',theseIndices(i),thisNewIndex);
           simpleVol(aparcVol==theseIndices(i)) = thisNewIndex; 
        end
    end
end


disp([min(simpleVol(:)) max(simpleVol(:))])
disp(unique(simpleVol(:))')

hdr.file_name = simple;
niak_write_nifti(hdr,simpleVol);