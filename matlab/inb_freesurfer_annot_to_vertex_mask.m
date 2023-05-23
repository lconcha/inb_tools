function mask = inb_freesurfer_annot_to_vertex_mask(annot_file,vMask,IDs)
% function inb_freesurfer_annot_to_vertex_mask(annot_file,vMask,IDs)

FS_HOME=getenv('FREESURFER_HOME');
addpath([FS_HOME '/matlab/']);


disp(IDs);


[vertices,label,colortable]=read_annotation(annot_file);

mask = zeros(size(vertices));
for r = 1 : length(IDs)
    thisID         = IDs(r);
    thisID = cell2mat(thisID);
    disp(thisID);
    for sr = 1 : length(colortable.struct_names)
        if strmatch(thisID,colortable.struct_names{sr})
           structureIndex =  colortable.table(sr,5);
           disp(structureIndex);
           break
        end
    end
    %structureIndex = find(colortable.table(:,5) == thisID);
    %thisStructure = colortable.struct_names{structureIndex};
    %fprintf(1,'  Getting label %d (%s)\n',thisID,thisStructure);
    index        = label == structureIndex;
    disp(sum(index));
    mask(index)  = 1;
end
fid = fopen(vMask,'w');
fprintf(1,'  Writing to %s ...\n',vMask);
fprintf(fid,'%d\n',mask);
fclose(fid);
fprintf(1,'Done.\n');