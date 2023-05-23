function [par,k] = readGEdata(pfile)
%   Read header information and binary pfile data
%   Requires: readGEheader.m
%   
%   Author:
%   R Marc Lebel
%   11/2010
%   
%   Usage:
%   [par,k] = readGEdata(pfile)
%   
%	Input:
%   pfile: path and file name
%   
%	Output:
%	par: (partial) parameter structure based on reverse engineering of the
%       Pfile header
%   k: complex data (unsorted)
%
%   See also the GE LX ESE users manual and rawloadHD.m

%   Check input
if nargin < 1 || isempty(pfile)
    files = dir('*.7*');
    if isempty(files)
        error('No P*****.7 files in current directory');
    end
    pfile = files(1).name;
    fprintf('No file specifed. Reading from %s\n',pfile);
    clear files
end

%   Read header information
[par,byte_off] = read_gehdr(pfile);

%   Open P file and jump past the header
fip = fopen(pfile,'r');
if fip == -1
  fprintf('File %s not found\n',pfile);
  return
end
status = fseek(fip,byte_off,'bof');
if status ~= 0
    error('Unable to find data');
end

%   Read the data and convert data pairs to complex points
if par.rdb.point_size == 2
    k = fread(fip,inf,'int16=>int16');
elseif par.rdb.point_size == 4
    k = fread(fip,inf,'int32=>int32');
else
    error('Unknown data precision');
end
k = complex(k(1:2:end),k(2:2:end));

%   Convert from integer to floating point
k = double(k);

%   Close the file
status = fclose(fip);
if status ~= 0
    error('Problem closing file');
end

end
