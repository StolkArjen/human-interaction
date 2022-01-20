function [data] = read_json_tcg(logfile)

% --------------------------------------------------------
% READ_JSON_TCG reads communication game json files originating
% from the web version of the tcg or tcg kids
%
% INPUT
% Use as: [data] = read_json_tcg(logfile)
% where logfile is a 'room' containing the '*.json' files
%
% OUTPUT
% A struct containing;
% info      recording file, date and onset, and game type
% trial     rows (trials) x columns (variables)
% label     variable names
% event     onsets and durations of task events
% token     token positions
%
% Arjen Stolk, 2021
% --------------------------------------------------------


% recording information
list         = dir(logfile);
data.info{1} = logfile;
data.info{2} = list(1).date;

% read all json files
sess = {'practice', 'training', 'game'};
epoch = {'roleassignment', 'tokenassignment', 'sender', 'receiver', 'feedback'};
for s = 1:numel(sess) % session loop

  % number of trials for this session
  list = dir(fullfile(logfile, [sess{s} '*.json']));
  ntrls = 0;
  for l = 1:numel(list)
    trl = sscanf(list(l).name,[sess{s} '_trial_%d_']);
    if trl > ntrls
      ntrls = trl;
    end
  end

  % trial loop
  for t = 1:ntrls
    TrialOnset                        = NaN;
    TrialOffset                       = NaN;
    SenderPlayer                      = NaN;
    ReceiverPlayer                    = NaN;
    SenderPlanTime                    = NaN;
    SenderMovTime                     = NaN;
    SenderNumMoves                    = 0;
    ReceiverPlanTime                  = NaN;
    ReceiverMovTime                   = NaN;
    ReceiverNumMoves                  = 0;
    TargetNum                         = 0;
    TargetTime                        = NaN;
    NonTargetTime                     = NaN;
    ReceiverTargetPos                 = NaN;
    Success                           = NaN;
    SenderLocSuccess                  = NaN;
    SenderOriSuccess                  = NaN;
    ReceiverLocSuccess                = NaN;
    ReceiverOriSuccess                = NaN;
    SenderTarget                      = NaN;
    ReceiverTarget                    = NaN;
    Level                             = NaN;
    data.token{s}.sender(t).coord     = [];
    data.token{s}.sender(t).time      = [];
    data.token{s}.sender(t).shape     = [];
    data.token{s}.sender(t).control   = {};
    data.token{s}.sender(t).action    = {};
    data.token{s}.receiver(t).coord   = [];
    data.token{s}.receiver(t).time    = [];
    data.token{s}.receiver(t).shape   = [];
    data.token{s}.receiver(t).control = {};
    data.token{s}.receiver(t).action  = {};
    data.event{s}(t).epoch            = [];

    % epoch loop
    for e = 1:numel(epoch)
      filename = [logfile filesep sess{s} '_trial_' num2str(t) '_' epoch{e} '.json']; % '_bot.json'
      if exist(filename, 'file')

        % read in json structure
        val = jsondecode(fileread(filename));

        % reshape structure into cell array if needed (e.g. roleassigment of game_trial_1)
        if isstruct(val)
          tmp = val;
          val = cell(0,0);
          for c = 1:numel(tmp)
            val{c,1} = tmp(c);
          end
        end

        % trial onsets and roles
        if (strcmp(val{1}.epoch, 'roleassignment') && (strcmp(sess{s}, 'training') || strcmp(sess{s}, 'game'))) || ...
            (strcmp(val{1}.epoch, 'tokenassignment') && strcmp(sess{s}, 'practice'))
          TrialOnset = val{1}.timestamp;
          if isfield(val{1}, 'p1') || isfield(val{1}, 'p2')
            if isfield(val{1}.p1, 'angle') % tcg
              if isfield(val{1}, 'p1') && isfield(val{1}.p1, 'role') && strcmp(val{1}.p1.role, 'sender')
                SenderPlayer = 1;
                SenderTarget = [val{1}.p1.goal.xPos val{1}.p1.goal.yPos val{1}.p1.goal.angle];
              elseif isfield(val{1}, 'p2') && isfield(val{1}.p2, 'role') && strcmp(val{1}.p2.role, 'sender')
                SenderPlayer = 2;
                SenderTarget = [val{1}.p2.goal.xPos val{1}.p2.goal.yPos val{1}.p2.goal.angle];
              end
              if isfield(val{1}, 'p1') && isfield(val{1}.p1, 'role') && strcmp(val{1}.p1.role, 'receiver')
                ReceiverPlayer = 1;
                ReceiverTarget = [val{1}.p1.goal.xPos val{1}.p1.goal.yPos val{1}.p1.goal.angle];
                ReceiverTargetPos = [val{1}.p1.goal.xPos val{1}.p1.goal.yPos];
              elseif isfield(val{1}, 'p2') && isfield(val{1}.p2, 'role') && strcmp(val{1}.p2.role, 'receiver')
                ReceiverPlayer = 2;
                ReceiverTarget = [val{1}.p2.goal.xPos val{1}.p2.goal.yPos val{1}.p2.goal.angle];
                ReceiverTargetPos = [val{1}.p2.goal.xPos val{1}.p2.goal.yPos];
              end
            else % tcg kids
              if isfield(val{1}, 'p1') && isfield(val{1}.p1, 'role') && strcmp(val{1}.p1.role, 'sender')
                SenderPlayer = 1;
                SenderTarget = [0 0];
              elseif isfield(val{1}, 'p2') && isfield(val{1}.p2, 'role') && strcmp(val{1}.p2.role, 'sender')
                SenderPlayer = 2;
                SenderTarget = [0 0];
              end
              if isfield(val{1}, 'p1') && isfield(val{1}.p1, 'role') && strcmp(val{1}.p1.role, 'receiver')
                ReceiverPlayer = 1;
                ReceiverTarget = [val{1}.p1.goal];
                ReceiverTargetPos = [val{1}.p1.goal];
              elseif isfield(val{1}, 'p2') && isfield(val{1}.p2, 'role') && strcmp(val{1}.p2.role, 'receiver')
                ReceiverPlayer = 2;
                ReceiverTarget = [val{1}.p2.goal];
                ReceiverTargetPos = [val{1}.p2.goal];
              end
            end
          end
          % player IDs (for relating to userinput)
          for c = 1:numel(val) % cells for this epoch
            if isfield(val{c}, 'Iamplayer')
              if isequal(val{c}.Iamplayer, 1)
                data.info{3}{1} = ['player 1: ' val{c}.player];
                try data.info{4}{1} = ['date 1: ' val{c}.date]; end
              elseif isequal(val{c}.Iamplayer, 2)
                data.info{3}{2} = ['player 2: ' val{c}.player];
                try data.info{4}{2} = ['date 2: ' val{c}.date]; end
              end
            end
          end
        end

        % planning and movement times
        if strcmp(val{1}.epoch, 'sender')
          for c = 1:numel(val) % cells for this epoch
            % planning & movement time
            if isfield(val{c}, 'action')
              if strcmp(val{c}.action, 'start') && isnumeric(val{c}.token.shape) % tcg
                SenderMovOnset  = val{c}.timestamp;
                SenderPlanTime  = SenderMovOnset - val{1}.timestamp; % 1st timestamp is goal onset
                WaitForOffTarget = 0;
              elseif strcmp(val{c}.action, 'stop') || strcmp(val{c}.action, 'timeout')
                SenderMovOffset = val{c}.timestamp;
                SenderMovTime   = SenderMovOffset - SenderMovOnset;
                TargetTime      = nanmean(TargetTime); % take the average
                NonTargetTime   = nanmean(NonTargetTime);
              elseif strcmp(val{c}.action, 'up') || strcmp(val{c}.action, 'down') || ...
                  strcmp(val{c}.action, 'left') || strcmp(val{c}.action, 'right') || ...
                  strcmp(val{c}.action, 'rotateleft') || strcmp(val{c}.action, 'rotateright')
                SenderNumMoves = SenderNumMoves +1;
                if isequal(SenderNumMoves,1) && ischar(val{c}.token.shape) % tcg kids
                  SenderMovOnset  = val{c}.timestamp;
                  SenderPlanTime  = SenderMovOnset - val{1}.timestamp; % 1st timestamp is goal onset
                  WaitForOffTarget = 0;
                end
                % time spent at location
                if WaitForOffTarget
                  TargetTime(end+1) = val{c}.timestamp-val{c-1}.timestamp;
                  WaitForOffTarget = 0;
                else
                  NonTargetTime(end+1) = val{c}.timestamp-val{c-1}.timestamp;
                end
                % on target
                if isnumeric(val{c}.token.shape) && isequal([val{c}.token.xPos val{c}.token.yPos], ReceiverTargetPos) % tcg
                  TargetNum = TargetNum +1;
                  WaitForOffTarget = 1;
                elseif ischar(val{c}.token.shape) && check_target(val{c}.token) % tcg kids
                  TargetNum = TargetNum +1;
                  WaitForOffTarget = 1;
                end
                % double check on target
                if ~strcmp(sess{s}, 'practice') && val{c}.token.onTarget && ~TargetNum % overlooked target visits
                  warning(['on target missed for ' logfile ', ' sess{s} ', trial ' num2str(t)])
                end
              end
            end
            % token coord & timestamps
            if isfield(val{c}, 'token')
              if isfield(val{c}.token, 'angle') % tcg
                data.token{s}.sender(t).coord(end+1,:)   = [val{c}.token.xPos val{c}.token.yPos val{c}.token.angle];
                data.token{s}.sender(t).shape(end+1,:)   = val{c}.token.shape;
              else % tcg kids
                data.token{s}.sender(t).coord(end+1,:)   = [val{c}.token.xPos val{c}.token.yPos];
                data.token{s}.sender(t).shape{end+1,1}   = val{c}.token.shape;
              end
              data.token{s}.sender(t).time(end+1,:)    = val{c}.timestamp;
              data.token{s}.sender(t).control{end+1,1} = val{c}.token.control;
              data.token{s}.sender(t).action{end+1,1}  = val{c}.action;
              data.token{s}.sender(t).goal             = SenderTarget;
            end
          end
        elseif strcmp(val{1}.epoch, 'receiver')
          for c = 1:numel(val) % cells for this epoch
            % planning & movement time
            if isfield(val{c}, 'action')
              if strcmp(val{c}.action, 'start') && isnumeric(val{c}.token.shape) % tcg
                ReceiverMovOnset  = val{c}.timestamp;
                ReceiverPlanTime  = ReceiverMovOnset - val{1}.timestamp; % 1st timestamp is goal onset
              elseif strcmp(val{c}.action, 'stop') || strcmp(val{c}.action, 'timeout')
                ReceiverMovOffset = val{c}.timestamp;
                ReceiverMovTime   = ReceiverMovOffset - ReceiverMovOnset;
              elseif strcmp(val{c}.action, 'up') || strcmp(val{c}.action, 'down') || ...
                  strcmp(val{c}.action, 'left') || strcmp(val{c}.action, 'right') || ...
                  strcmp(val{c}.action, 'rotateleft') || strcmp(val{c}.action, 'rotateright') || ...
                  strcmp(val{c}.action, 'tracking')
                ReceiverNumMoves = ReceiverNumMoves +1;
                if isequal(ReceiverNumMoves,1) && ischar(val{c}.token.shape) % tcg kids
                  ReceiverMovOnset  = val{c}.timestamp;
                  ReceiverPlanTime  = ReceiverMovOnset - val{1}.timestamp; % 1st timestamp is goal onset
                end
              end
            end
            % token coord & timestamps
            if isfield(val{c}, 'token')
              if isfield(val{c}.token, 'angle') % tcg
                data.token{s}.receiver(t).coord(end+1,:)   = [val{c}.token.xPos val{c}.token.yPos val{c}.token.angle];
                data.token{s}.receiver(t).shape(end+1,:)   = val{c}.token.shape;
              else % tcg kids
                data.token{s}.receiver(t).coord(end+1,:)   = [val{c}.token.xPos val{c}.token.yPos];
                data.token{s}.receiver(t).shape{end+1,1}   = val{c}.token.shape;
              end
              data.token{s}.receiver(t).time(end+1,:)    = val{c}.timestamp;
              data.token{s}.receiver(t).control{end+1,1} = val{c}.token.control;
              data.token{s}.receiver(t).action{end+1,1}  = val{c}.action;
              data.token{s}.receiver(t).goal             = ReceiverTarget;
            end
          end
        end

        % feedback, level and trial offset
        if strcmp(val{1}.epoch, 'feedback')
          Success = val{1}.success;
          if isfield(val{1}, 'p1') && isfield(val{1}.p1, 'role') && strcmp(val{1}.p1.role, 'sender')
            [SenderLocSuccess, SenderOriSuccess] = check_feedback(val{1}.p1);
          elseif isfield(val{1}, 'p2') && isfield(val{1}.p2, 'role') && strcmp(val{1}.p2.role, 'sender')
            [SenderLocSuccess, SenderOriSuccess] = check_feedback(val{1}.p2);
          end
          if isfield(val{1}, 'p1') && isfield(val{1}.p1, 'role') && strcmp(val{1}.p1.role, 'receiver')
            [ReceiverLocSuccess, ReceiverOriSuccess] = check_feedback(val{1}.p1);
          elseif isfield(val{1}, 'p2') && isfield(val{1}.p2, 'role') && strcmp(val{1}.p2.role, 'receiver')
            [ReceiverLocSuccess, ReceiverOriSuccess] = check_feedback(val{1}.p2);
          end
          if isfield(val{1}, 'level')
            Level = val{1}.level;
          end
          TrialOffset = val{1}.timestamp+1000;
        end

        % event timestamps
        if strcmp(val{1}.epoch, epoch{e})
          data.event{s}(t).epoch(end+1) = val{1}.timestamp; % register the first timestamp
        end

      end % filename
    end % epoch

    data.trial{s}(t,:) = [t s NaN TrialOnset ...
      SenderPlayer SenderPlanTime SenderMovTime SenderNumMoves TargetNum TargetTime NonTargetTime ...
      ReceiverPlayer ReceiverPlanTime ReceiverMovTime ReceiverNumMoves ...
      Success SenderLocSuccess SenderOriSuccess ReceiverLocSuccess ReceiverOriSuccess Level ...
      TrialOffset];
  end % trial
end % session

% add label field
data.label = {'TrialNr','TrialType','TrialTypeNr','TrialOnset', ...
  'SenderPlayer','SenderPlanTime','SenderMovTime','SenderNumMoves','TargetNum','TargetTime','NonTargetTime', ...
  'ReceiverPlayer','ReceiverPlanTime','ReceiverMovTime','ReceiverNumMoves', ...
  'Success','SenderLocSuccess','SenderOriSuccess','ReceiverLocSuccess','ReceiverOriSuccess','Level', ...
  'TrialOffset'};

% add userinput field
try
  data.userinput = importdata([logfile filesep 'userinput.csv']);
end


function [loc, ori] = check_feedback(p)
% location
loc = 0;
if isequal(p.shape, 'bird') && isequal([p.xPos p.yPos], [0, 0])
  loc = 1;
elseif isequal(p.shape, 'squirrel')
  loc = NaN;
elseif isequal([p.xPos p.yPos], [p.goal.xPos p.goal.yPos])
  loc = 1;
end
% orientation
ori = 0;
if isequal(p.shape, 'bird') || isequal(p.shape, 'squirrel')
  ori = 1;
elseif isequal(p.shape, 1) % rectangle
  if isequal(p.angle, p.goal.angle) || isequal(abs(p.angle-p.goal.angle), 180) % angle
    ori = 1;
  end
elseif isequal(p.shape, 2) % circle
  if loc % angle
    ori = 1;
  end
elseif isequal(p.shape, 3) % triangle
  if isequal(p.angle, p.goal.angle) % angle
    ori = 1;
  end
end

function onTarget = check_target(t)
% field
field{1} = [-1, 1];
field{2} = [0, 1];
field{3} = [0, 1];
field{4} = [1, 1];
field{5} = [1, 1];
field{6} = [-1, 0];
field{7} = [-1, 0];
field{8} = [-1, 0];
field{9} = [1, 0];
field{10} = [-1, -1];
field{11} = [0, -1];
field{12} = [0, -1];
field{13} = [1, -1];
field{14} = [1, -1];
field{15} = [1, -1];
onTarget = isequal([t.xPos, t.yPos], field{t.goal});
