% Clear the workspace and the screen
sca;
close all;
clearvars;

%%%%%%%%%%%%%%%%%%%%%%% Setting up Psychtoolbox %%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default settings for psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
%screenNumber = max(screens);
screenNumber = 1; %currently Wacom is screen 1

% Define black, white and grey color spaces
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white/2;

% Open a grey on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Setup the text type for the window
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 28);

% Define the ESC key
KbName('UnifyKeynames');
esc = KbName('ESCAPE');
space = KbName('SPACE');

%%%%%%%%%%%%%%%%%%%%%%% Setting up PowerMate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%initialize PowerMate
%pm = PsychPowerMate('Open');
%PsychPowerMate('SetBrightness',pm,0)

%%%%%%%%%%%%%%%%%%%%%%% Visual Trial Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Target dot appearance
dotColor = [0 1 0]; %green
dotSizePix = 15; % Dot size in pixels

% Set the color of the confidence oval to yellow
rectColor = [1 1 0];

%Fixation cross
fixCrossDimPix = 10; % Width of fixation cross arms

% Setting coordinates for fixation cross
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
lineWidthPix = 4; % Set the line width for our fixation cross

%fixation circle
fixation = [xCenter,screenYpixels-175];
baseRect = abs([0 0 20 20]);
centeredRect = CenterRectOnPointd(baseRect, xCenter, screenYpixels-175);

%Number of testable target locations
numTargets = 6;

%target location base sectors
tar1x = xCenter - xCenter/2;
tar1y = yCenter + yCenter/4;

tar2x = xCenter - xCenter/2;
tar2y = yCenter - yCenter/4;

tar3x = xCenter - xCenter/4;
tar3y = yCenter - yCenter/2;

tar4x = xCenter + xCenter/4;
tar4y = yCenter - yCenter/2;

tar5x = xCenter + xCenter/2;
tar5y = yCenter - yCenter/4;

tar6x = xCenter + xCenter/2;
tar6y = yCenter + yCenter/4;

%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Specifics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gamephase = 0;
phases = 5; %differnt steps trial moves through
trial = 1;
k = 0;
numBlocks = 4; %number of blocks
numIter = 1; %number of iterations across all 6x locations
numTrials = ones(numBlocks,1)*(numIter*numTargets); %total trial number per block must be a factor of 6
totalTrials = sum(numTrials);
confTrial = 2; %how often does a confidence trial appear
numSecs = 1;
numFrames = round(numSecs/ifi);
tarLocations =[tar1x,tar1y; tar2x,tar2y; tar3x,tar3y; tar4x,tar4y;tar5x,tar5y; tar6x,tar6y;];  %possible target locations
ptb = 30*sin(2*pi*numBlocks*linspace(0,1,totalTrials)); %perturbation function
pauseTime = 1;
waitTime = 1;
respWindow = 1.5;

%TO DO:
%formalize visual display aspects of the experiment
%formalize number of trials

%%%%%%%%%%%%%%%%%%%%%%%%%% Output Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%location information
trialNum =[];   %trial number
targetLoc = []; %tar X and tar Y (after jitter applied)
endPointTrue = []; %true end X and Y
endPointPtb = []; %feedback X and Y after perturbation applied
confRad = []; %confidence rating circle radius
dialStart = 0;
fixError =[]; %error (in pixels) from fixation
targetSector = []; %sector of target location (1-6, 1 is bottom left, 6 is bottom right)
respDist = []; %euclidian distance from true target location to end point
blockScore = []; %score for confidence accuracy, possible 5 points per iteration

%timestamps
tarAppearTime = []; %target appearance time
moveStart = []; %movement start time
moveEnd = []; %movement end time
startTimes = []; %start time of trial

%duration measures
inTimes = []; %time it takes for participant to get inside fixation
RTs = []; %time it takes for participant to start response
MTs = []; %duration of movement

%%%%%%%%%%%%%%%%%%%%%%%% Trial Permutations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tarOrder = cell2mat(arrayfun(@(tarLocations) randperm(numTargets), 1:numIter, 'UniformOutput',false)')';
timeFlag = 0; %flag to reshuffle trial order of remaining permutations if trial was missed do to timing error

%%%%%%%%%%%%%%%%%%%%%%%% Experimental Code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


tic %start block timer
jj = 1;
for bb = 1:numBlocks
    for tt = 1:numIter
        while jj < numTargets +1
            %while trial <= numTrials   % One loop iteration represents 1x trial
            
            %%%%%%%%%%%%%%%%%%% Setting up escape and timing %%%%%%%%%%%%%%%%%%%%%%
            
            % Exits experiment when ESC key is pressed.
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(esc)
                    break
                end
            end
            
            
            %%%%%%%%%%%%%%%%%%%%% Initalizing GetMouse %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [x, y, buttons] = GetMouse(window);
            
            while gamephase <= 5
                %%%%%%%%%%%%%%%%%%%% Begin drawing to screen %%%%%%%%%%%%%%%%%%%%%%%%%%
                %for ii = 1:phases
                %Start Screen
                if gamephase == 0
                    
                    startTimes(trial) = toc;
                    t = toc;
                    temp = 1;
                    
                    %%%%%%%%%%%%%%%%%%%% Select Target Location %%%%%%%%%%%%%%%%%%%
                    
                    jitter = [randn*(xCenter/8),randn*(yCenter/8)]; %jitter applied (+/- randn) normally distributed noise
                    if timeFlag == 1
                        tarOrder(jj:end,tt) = Shuffle(tarOrder(jj:end,tt));
                        timeFlag = 0;
                    end
                    tarPos = tarOrder(jj,tt);
                    dotXpos = tarLocations(tarPos,1) + jitter(1);
                    dotYpos = tarLocations(tarPos,2) + jitter(2); %so target is always above starting fixation.
                    targetLoc(trial,1) = dotXpos; targetLoc(trial,2) = dotYpos; %target position saved
                    
                    %%%%%%%%%%%%%%%%%%%% Trial Visualizations Begin %%%%%%%%%%%%%%%
                    
                    while temp == 1
                        Screen('FrameOval', window, white, centeredRect, 2,2); %fixation circle
                        Screen('DrawText', window, 'Place pen inside white fixation circle' , xCenter-300, yCenter, white);
                        Screen('Flip', window);
                        
                        [x, y, buttons] = GetMouse(window);
                        fixError(trial,1) = x-xCenter; fixError(trial,2) = y-(screenYpixels-175); %fixation check
                        
                        if abs(fixError(trial,1)) <= baseRect(3)/2 && abs(fixError(trial,2)) <=baseRect(3)/2 && buttons(1) == 1
                            gamephase = 1;
                            inTimes(trial) = toc - t;
                            pause(pauseTime);
                            t = toc;
                            temp = 0;
                            
                        else
                            temp = 1;
                        end
                    end
                    
                    %Target appears
                elseif gamephase == 1
                    
                    while buttons(1) && toc-t<respWindow %while fixation is held and less than 3 seconds has elapsed
                        % Get the current position of the mouse
                        [x, y, buttons] = GetMouse(window);
                        Screen('DrawDots', window, [dotXpos dotYpos], dotSizePix, dotColor, [], 2); %target
                        Screen('FrameOval', window, white, centeredRect, 2,2); %fixation circle
                        Screen('Flip', window);
                    end
                    
                    if toc-t > respWindow
                        Screen('DrawText', window, 'Too slow!' , xCenter-75, yCenter, white);
                        Screen('Flip', window);
                        timeFlag = 1;
                        gamephase = 99;
                        pause(waitTime);
                    else
                        gamephase = 2;
                    end
                    
                    RTs(trial) = toc-t;
                    t = toc;
                    
                    %Participant Response
                elseif gamephase == 2
                    
                    while ~buttons(1) && toc-t<respWindow %once movement has started and lasts under 3 seconds
                        moveStart(trial,1) = toc; %movement start time
                        % Get the current position of the mouse
                        [x, y, buttons] = GetMouse(window);
                        
                        %no feedback during trial
                        
                        % Flip to the screen
                        Screen('Flip', window);
                    end
                    
                    if toc-t > respWindow
                        Screen('DrawText', window, 'Too slow!' , xCenter-75, yCenter, white);
                        Screen('Flip', window);
                        timeFlag = 1;
                        gamephase = 99;
                        pause(waitTime);
                    end
                    
                    MTs(trial) = toc - t;
                    moveEnd(trial,1) = toc; %movement end timing saved
                    endPointTrue(trial,1) = x; endPointTrue(trial,2) = y; %final reach position saved
                    respDist(trial,1) = sqrt( (targetLoc(trial,1)-endPointTrue(trial,1))^2 + (targetLoc(trial,2)-endPointTrue(trial,2))^2)
                    if gamephase ~= 99
                        if rem(trial,confTrial) == 0
                            gamephase = 3;
                        else
                            gamephase = 4;
                            pause(pauseTime)
                        end
                        t = toc;
                    end
                    
                    %Confidence Trial
                elseif gamephase == 3
                    [buttonPM, dialPos] = PsychPowerMate('Get',pm);
                    startDial = dialPos;
                    circSize = randi([10,200],1);
                    
                    while ~buttonPM %until button on dial is pressed
                        
                        [buttonPM, dialPos] = PsychPowerMate('Get',pm); %get dial postion
                        
                        % Make a base Rect of 200 by 250 pixels
                        circStart = circSize + (dialPos-startDial)*2;
                        baseRect2 = abs([0 0 circStart circStart]);
                        
                        % Center the circle on the mouse click location
                        centeredRect2 = CenterRectOnPointd(baseRect2, x, y);
                        
                        % Draw the circle to the screen
                        Screen('FrameOval', window, rectColor, centeredRect2, 2,2);
                        Screen('DrawText', window, 'Expand circle to enclose target location, push down to confirm. The smaller the circle the more points recieved' , xCenter-800, yCenter-500, white);
                        % Flip to the screen
                        Screen('Flip', window);
                        
                    end
                    fbTime = toc - t;
                    confRad(trial,1) = baseRect2(4)/2; %pixel radius of confidence circle recorded
                    clear buttonPM
                    pause(pauseTime)
                    gamephase = 5;
                    
                    %Feedback Trial
                elseif gamephase == 4
                    xPtb = x+ptb(trial);
                    yPtb = y+ptb(trial);
                    for frame = 1:numFrames %display feedback for 1 second
                        Screen('DrawDots', window, [dotXpos dotYpos], dotSizePix, dotColor, [], 2); %target location
                        Screen('DrawDots', window, [xPtb yPtb], dotSizePix, white, [], 2); %endpoint location
                        
                        % Flip to the screen
                        Screen('Flip', window);
                    end
                    confRad(trial,1) = 0; %knob position saved as zero
                    endPointPtb(trial,1) = xPtb; endPointPtb(trial,2) = yPtb;
                    gamephase = 5;
                    
                    %End screen of trial
                elseif gamephase == 5
                    targetSector(trial,1) = tarPos;
                    clear buttons;
                    if jj == numTrials(bb)
                        Screen('DrawText', window, 'End of run' , xCenter-75, yCenter, white);
                        trial = trial+1;
                        jj = jj+1;
                        gamephase = 6;
                    else
                        Screen('DrawText', window, 'Get ready for next trial' , xCenter-150, yCenter, white);
                        jj = jj+1;
                        trial = trial+1;
                        gamephase = 6;
                    end
                    % Flip to the screen
                    Screen('Flip', window);
                    pause(waitTime);
                    
                elseif gamephase == 99
                    9999999
                    gamephase = 0;
                    Screen('DrawText', window, 'Get ready for next trial' , xCenter-200, yCenter, white);
                    Screen('Flip', window);
                    pause(waitTime);
                end
            end
            gamephase = 0;
        end
        jj = 1;
    end
    %Give confidence accrucy score for block and block average
    confTrials = confRad>1;
    distConf = respDist(confTrials);
    confSize = confRad(confTrials);
    ptsCheck = confSize - distConf > 0;
    
    blockScore(bb) = sum(5 - confSize(ptsCheck)/20);
    avrgScore = mean(blockScore);
    
    
    Screen('DrawText', window, ['Score for Block: ' num2str(blockScore(bb))], xCenter-200, yCenter, white);
    Screen('DrawText', window, ['Average Block Score: ' num2str(avrgScore)], xCenter-200, yCenter+40, white);
    Screen('Flip', window);
    pause(5);
end



% Clear the screen
sca;