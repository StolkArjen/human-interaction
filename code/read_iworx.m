function [data, event] = read_iworx(filename)

% READ_IWORX reads and converts various IWORX datafiles into a
% FieldTrip-type data structure, which subsequently can be used for
% preprocessing or other analysis methods implemented in Fieldtrip
%
% Use as
%   [data, event] = read_iworx(filename)
% where filename has a .mat extension
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
[~, ~, ext] = fileparts(filename);
if ~strcmp(ext, '.mat')
  error('this function requires a .mat file as input')
end

% read the data
load(filename);
for t = 1:n % n is a variable contained by the mat file
  data.trial{1,t} = eval(['b' num2str(t)])';
  data.time{1,t} = eval(['b' num2str(t) '(:,1)'])';
end
data.label = {'Time'; ...
  'Corrugator supercilii muscle'; ...
  'Zygomaticus major muscle';	...
  'Heart Rate';	...
  'dunno'; ...
  'Skin Conductance'}; % info stored in the .txt but not .mat file

% read the markers
event = [];
marks = whos('m*');
if ~isempty(marks)
  for e = 1:numel(marks)
    tmp = eval(marks(e).name);
    event(end+1).type = 'trig';
    event(end).sample = tmp.time;
    event(end).value  = tmp.value;
  end

  % discard trials unlikely to match the events
  for t = 1:size(data.trial,2)
    if data.time{1,t}(end) < event(end).sample
      data.trial{1,t} = [];
      data.time{1,t} = [];
    end
  end
  data.trial = data.trial(~cellfun('isempty', data.trial));
  data.time = data.time(~cellfun('isempty', data.time));
end
