function schemeCamino = bv_to_scheme(bval_fname,bvec_fname,DELTA,delta,TE,scheme_fname)

disp('Converting to camino-style scheme file');


bval = load(bval_fname);
bvec = load(bvec_fname);

% transpose, if necessary
if size(bval,1) < size(bval,2)
   bval = bval'; 
end
if size(bvec,1) < size(bvec,2)
   bvec = bvec'; 
end



bval = bval ./ 1e6;
bvec = bvec;





%Convertir a sec
DELTA = DELTA .* 1e-3;
delta = delta .* 1e-3;
TE    = TE    .* 1e-3;

fprintf(1,'DELTA (DwGradSep) is %1.6f s\n',DELTA);
fprintf(1,'delta (DwGradDur) is %1.6f s\n',delta);
fprintf(1,'TE is %1.6f s\n',TE);


%Definir gyromagnetic ratio:
gmr = 42.576*1e6; %de MHZ/T ->  rad/(sec T)

%Luego calcular el G despejando como 
G = sqrt( bval ./ (gmr^2 *  delta.^2 .* (DELTA-delta/3))) ; %en T/m


nG     = numel(bval);
DELTAS = repmat(DELTA, nG,1);
deltas = repmat(delta, nG,1);
TEs    = repmat(TE,    nG,1);


fprintf(1,'  Number of lines to write: %d\n',nG);
% size(DELTAS)
% size(deltas)
% size(TEs)
% size(G)
% size(bvec)
% size(bval)


schemeCamino = [bvec(:,1), bvec(:,2) ,bvec(:,3), G, DELTAS, deltas, TEs];

% save(scheme_fname, 'schemeCamino', '-ascii', '-tabs');

fprintf(1,'Maximum gradient found: %1.8f T/m\n',max(G));



fid = fopen(scheme_fname,'w');
fprintf(fid,'VERSION: STEJSKALTANNER\n');
for i = 1 : nG
fprintf(fid,'%1.6f\t%1.6f\t%1.6f\t%1.10f\t%1.4f\t%1.4f\t%1.4f\n',...
               schemeCamino(i,1),...
               schemeCamino(i,2),...
               schemeCamino(i,3),...
               schemeCamino(i,4),...
               schemeCamino(i,5),...
               schemeCamino(i,6),...
               schemeCamino(i,7) );
end
fclose(fid)