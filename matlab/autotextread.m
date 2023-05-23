function [a,colnames]=autotextread(fname,ch,header)
% AUTOTEXTREAD like textread; puts results into structure based on header line.
% function [a,colnames]=autotextread(fname,ch,header)
%
% Read a data file that has a header line, assigning each column
% to a field of a structure with the appropriate name.
%
% For example, if called as follows:
% [a,colnames]=autotextread('autotextread_samp.txt')
% where the file contains the following:
% daynum stuff Adjective
% 1  .25 slimy
% 2  .23 speedy
% 3 1.00 super
%
% you get
% a = 
%       daynum: [3x1 double]
%        stuff: [3x1 double]
%    Adjective: {3x1 cell}
% colnames = 'daynum'    'stuff'    'Adjective'
% That is, autotextread will return will return a structure with fields
% "daynum", "stuff", "Adjective"; 
% daynum and stuff will be numeric vectors; stuff will be a cell array.
% A very simple test is performed on the first line of data to determine
% which columns are numeric and which are strings.  You may need to modify
% this source code if the test doesn't work for your data file.
% "ch" is optional, and defines the column separator for the header line.
% common values would be ' ' for space (the default), or char(9) for tab.
% "header" is optional, and if it is given it's treated as the first
% line of the file.  This is handy for files where you know the field names
% but don't feel like constructing a call to textread.
% This code was written by Andrew Ross, mostly just modifying code from
% http://www.mathworks.com/support/solutions/data/26207.shtml
% written by Megean McDuffy 06/21/00
% For a spreadsheet-oriented utility, look for Michael Robbins'
% spreadsheet2structure, File ID # 8127
% The "ch" argument was based on a suggestion by Suresh Joel.
% The string-cleaning code is from a suggestion by Susan Olson

if( nargin == 1 )
	ch = ' ';
end

%open file
fid = fopen(fname,'r');
%retrieve column headers
if( nargin <= 2 )
	headers = fgetl(fid);
else
	headers = header;
end
% get a sample data line
samp = fgetl(fid);
%close file for now (textread will reopen it)
fclose(fid);
%trim possible # or % from header line
if( headers(1) == '#' | headers(1) == '%')
    headers = headers(2:end);
end
% get a cell array of column names
% for "getvarnames", see far below in this file.
headercell = getvarnames(headers,ch);

% determine type (%f or %s) for each column
% first, break the sample line into fields
sampcell = getvarnames(samp,ch);
% how many fields?
ncol1 = length(headercell);
ncol2 = length(sampcell);
if( ncol1 > ncol2 )
	warning('More columns named than exist on line 1,');
	warning('skipping the extras.');
elseif( ncol1 < ncol2 )
	warning('More columns exist on line 1 than named in header,');
	warning('skipping the extras.');
end

typestr = [];
for nc=1:min(ncol1,ncol2)
% sampcell{i} % for debugging
    [tmp,ct,errmsg] = sscanf(sampcell{nc},'%f');
    if( length(errmsg) > 0 | ct > 1)
	% got an error, treat it as a string.
        typestr = [typestr, '%s '];
    else
	% no error, treat it as a number
        typestr = [typestr, '%f '];
    end
end
% chop off that last space
typestr = typestr(1:(end-1));

% construct a statement of the form
% [a.col1, a.col2, a.col3 ...] = textread(fname,typestr,'headerlines',1);
% then "eval" it.
evalme = '[';
for nc=1:min(ncol1,ncol2)
    tmpstr = headercell{nc};
    % and clean it up:
    tmpstr = strrep(tmpstr,' ','');
    tmpstr = strrep(tmpstr,'-','');

    evalme = [ evalme, 'a.', tmpstr,  ',' ];
end
evalme = evalme(1:(end-1)); % chop off the last comma
evalme = [evalme '] = textread(fname,typestr,''headerlines'',1);' ];

% for debugging:
% headercell
% typestr
% evalme

eval(evalme);

%call textread to retrieve the data from your file
%[a,b,c,d,e,f,g] = textread(fname,typestr,'headerlines',1);

%make the names of your variables the names in the header cell array
%eval([headercell{2},' = b'])
%eval([headercell{3},' = c'])
%eval([headercell{4},' = d'])
%eval([headercell{5},' = e'])
%eval([headercell{6},' = f'])
%eval([headercell{7},' = g'])

colnames = headercell;
return;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function names = getvarnames(tempstr,ch)
          %Given a string containing variable names seperated by spaces
	  % or tabs or whatever is given in "ch"
          %this function returns a cell array containing each variable name.
          %
          %Written by Megean McDuffy 06/21/00
	  % modified slightly by Andrew Ross

	  %ch = char(32); % space
          %ch = char(9); % tab
          
          index = 0;
          while length(tempstr > 0)
             
             index = index + 1;
             
             %the fliplr function flips the array left to right  this line of 
             %code will take blanks off of the front and back of the header name 
             tempstr = fliplr(deblank(fliplr(deblank(tempstr))));

	% we could clean it up here (remove spaces, minus signs, etc)
	% but we only want to remove those for field names, not sample values.
	% so, we do it above.

             %if it is the last variable name
             if isempty(find(tempstr == ch))
               names{index} = tempstr;
               tempstr = [];
             else
               %grab the name
               names{index} = tempstr(1:find(tempstr == ch)-1);
               tempstr(1:find(tempstr == ch)) = [];
             end
             
          end

