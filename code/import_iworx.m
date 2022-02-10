function [data, event] = import_iworx(folder)

% IMPORT_IWORX reads and converts various IWORX datafiles into a
% FieldTrip-type data structure, which subsequently can be used for
% preprocessing or other analysis methods implemented in Fieldtrip
%
% Use as
%   [data, event] = import_iworx(folder)
% where folder contains a data (.mat) and a marks (.txt) file
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
matfile = dir([folder filesep '*.mat']);
hasmat = 0;
if ~isempty(matfile)
  hasmat = 1;
end
markfile = dir([folder filesep '*.txt']);
hasmark = 0;
if ~isempty(markfile)
  hasmark = 1;
end

% read the data
data = [];
if hasmat
  load([folder filesep matfile(1).name]);
  for t = 1:n % n is a variable contained by the mat file
    data.trial{1,t} = eval(['b' num2str(t)])';
    data.time{1,t} = eval(['b' num2str(t) '(:,1)'])';
  end
  data.label = {'Time'; ...
    'Corrugator supercilii muscle'; ...
    'Zygomaticus major muscle';	...
    'Heart Rate';	...
    'dunno'; ...
    'Skin Conductance'};
end

% read the markers
event = [];
if hasmark
  fid = fopen([folder filesep markfile(1).name],'r');
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
