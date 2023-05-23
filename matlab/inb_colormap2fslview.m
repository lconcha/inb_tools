function inb_colormap2fslview(cmap,fname)

fprintf(1,'  Saving colormap to %s\n',fname);

fid = fopen(fname,'w');
fopen(fid);


fprintf(fid,'%s\n','%!VEST-LUT');
fprintf(fid,'%s\n','%%BeginInstance');
fprintf(fid,'%s\n','<<');
fprintf(fid,'%s\n','/SavedInstanceClassName /ClassLUT ');
fprintf(fid,'%s\n','/PseudoColorMinimum 0.00 ');
fprintf(fid,'%s\n','/PseudoColorMaximum 1.00 ');
fprintf(fid,'%s\n','/PseudoColorMinControl /Low ');
fprintf(fid,'%s\n','/PseudoColorMaxControl /High ');
fprintf(fid,'%s\n','/PseudoColormap [');


for r = 1:size(cmap,1)
    fprintf(fid,'%s%1.3f,%1.3f,%1.3f%s\n','<-color{',cmap(r,1),cmap(r,2),cmap(r,3),'}->');
end

fprintf(fid,'%s\n',']');
fprintf(fid,'%s\n','>>');
fprintf(fid,'%s\n','%%EndInstance');
fprintf(fid,'%s','%%EOF');

fclose(fid); 

