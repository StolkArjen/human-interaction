function [data, event] = import_iworx(filename)

% IMPORT_IWORX reads and converts various IWORX datafiles into a 
% FieldTrip-type data structure, which subsequently can be used for 
% preprocessing or other analysis methods implemented in Fieldtrip.
%
% Use as
%   [data] = import_iworx(filename)
% where the filename should point to a .mat or .txt datafile.
% The output is a FieldTrip raw data structure as if it were returned
% by FT_PREPROCESSING.
%
% Copyright (C) 2022, Arjen Stolk


% check the input
[filepath,name,ext] = fileparts(filename);
if ~strcmp(ext, '.mat') && ~strcmp(ext, '.txt')
  error('file extension should be either .mat or .txt for this function')
end
hasmat = 0;
if strcmp(ext, '.mat')
  hasmat = 1;
end
hastxt = 0;
hasmark = 0;
if strcmp(ext, '.txt')
  hastxt = 1;
  if strcmp(name(end-9:end), '_MarksData')
    hasmark = 1;
  end
end

% organize the input
if hasmark
  datafile   = [filepath filesep name(1:end-10) '.mat'];
  headerfile = [filepath filesep name(1:end-10) '.txt'];
  markerfile = filename; 
elseif hastxt || hasmat
  datafile   = [filepath filesep name '.mat'];
  headerfile = [filepath filesep name '.txt'];
  markerfile = [filepath filesep name '_MarksData.txt']; 
end

% read the data
load(datafile);
for t = 1:n % n is a variable contained by the mat file
  data.trial{1,t} = eval(['b' num2str(t)])';
  data.time{1,t} = eval(['b' num2str(t) '(:,1)'])';
end

% read the header information
try
  fid = fopen(headerfile,'r');
  str = textscan(fid,'%s','Delimiter','\r');
  str = str{1};
  fclose(fid);
  data.label = split(str{1}, '	');
end

% read the markers
event = [];
try
  fid = fopen(markerfile,'r');
  str = textscan(fid,'%s','Delimiter','\r');
  str = str{1};
  fclose(fid);
  markers = split(str, '	');
  for e = 2:size(markers,1)
    event(end+1).type   = markers{e,1};
    event(end).sample = str2num(markers{e,2});
    event(end).value  = str2num(markers{e,5});
  end
end
