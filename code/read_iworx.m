function [data, event] = read_iworx(folder)

% READ_IWORX reads and converts various IWORX datafiles into a
% FieldTrip-type data structure, which subsequently can be used for
% preprocessing or other analysis methods implemented in Fieldtrip
%
% Use as
%   [data, event] = read_iworx(folder)
% where folder contains a data (.txt) and marks (.txt) file
%
% data has the following nested fields:
%    .trial
%    .time
%    .label
%
%  event has the following nested fields:
%    .type
%    .sample
%    .value
%
% Copyright (C) 2022, Arjen Stolk


% check the input
txtfiles = dir([folder filesep '*.txt']);
for l = 1:numel(txtfiles)
  if ~isempty(strfind(txtfiles(l).name, 'Marks'))
    markfile = [folder filesep txtfiles(l).name];
  else
    datafile = [folder filesep txtfiles(l).name];
  end
end

% read the marks file
event = [];
try
  T = readtable(markfile, 'DurationType', 'text', 'VariableNamingRule', 'preserve');
  for e = 1:size(T,1)
    event(e).type = 'trig';
    event(e).sample = sum(sscanf(T.("Real Time"){e},'%f:%f:%f').*[3600;60;1]); % hh:mm:ss
    event(e).value  = T.("MarkValue"){e};
  end
catch
  fprintf('a problem arose extracting the events\n')
end

% read the data file
data = [];
try
  % header
  fid = fopen(datafile,'r');
  str = textscan(fid,'%s','Delimiter','\r');
  str = str{1};
  fclose(fid);
  data.label = split(str{1}, '	');
  idx = [];
  for l = 1:numel(data.label) % discard time channels
    if isempty(strfind(data.label{l}, 'Time'))
      idx = [idx l];
    end
  end
  data.label = data.label(idx);

  % data
  T = readtable(datafile, 'DurationType', 'text', 'VariableNamingRule', 'preserve');
  trl = 1;
  data.trial{1,trl} = [];
  data.time{1,trl}  = [];
  for smp = 1:size(T,1)
    if isequal(T.("TimeOfDay"){smp}, 'TimeOfDay')
      trl = trl+1;
      data.trial{1,trl} = [];
      data.time{1,trl}  = [];
    else
      data.trial{1,trl} = [data.trial{1,trl} T{smp,idx}'];
      data.time{1,trl}  = [data.time{1,trl} sum(sscanf(T.("TimeOfDay"){smp},'%f:%f:%f').*[3600;60;1])]; % hh:mm:ss
    end
  end
catch
  fprintf('a problem arose reading the data\n')
end
