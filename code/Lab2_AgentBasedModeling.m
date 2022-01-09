%% Would you use "blue" or "circle"? (Frank & Goodman, 2012)
% Lexicon, M, defining the relations between signals referents 
% where rows represent the 4 possible signals: blue, green, circle, square 
% and columns the 3 possible referents: blue square, blue circle, green square

% Lexicon, M
M = [1 1 0;  % blue
     0 0 1;  % green
     0 1 0;  % circle
     1 0 1]; % square

% Literal speaker, S0
S0 = M./sum(M,1)
S0_bluecircle = S0(:,2) % preferred signal(s) for referring to the blue circle (note, 50-50)

% Literal listener, L0
L0 = M./sum(M,2) % probability distribution over referents given possible signals

% Pragmatic speaker, S1
S1 = L0./sum(L0,1) % taking into account a literal listener
S1_bluecircle = S1(:,2) % preferred signal(s) for referring to the blue circle


%% Which object are they referring to using the word "blue"? (Frank & Goodman, 2012)
% Pragmatic listener, L1
L1 = S1./sum(S1,2) % as L0, but taking into account a pragmatic speaker
L1_blue = L1(1,:) % most likely referent for blue (1st row)


%% Whom is referred to with "red hair"? (Breakout session)
% 1) Specify the lexicon (use the powerpoint slide)
M = [        % red hair
             % tall one
          ]; % gamer

% 2) Compute a literal listener's (L0) inference 
L0 = "do something here";

% 3) Compute a pragmatic listener's (L1) inference
S1 = "do something here";
L1 = "do something here";
