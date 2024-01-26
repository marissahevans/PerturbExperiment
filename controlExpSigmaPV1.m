function [contResultsMat,motorError] = controlExpSigmaPV1(displayInfo,numBlocks, numIter, gamephase, trial,saveFile)
%% Control experiment to test what participant's SigmaP and SigmaM are prior
% to running the main experiment. This experiment has 9 steps:
%FOR PURTERBATION EXPERIMENT!!!

% 1. Instructions screen - verbal instructions for how to do the task
% 2. Wait for participant to move pen to fixation point
% 3. Turn cursor off
% 4. Display a target
% 5. Reach is made to target location at the 'go' cue
% 6. Wait for participant to move pen to fixation again
% 7. Turn cursor on
% 8. Use mouse to move to percieved location of reach end point and click
% 9. Switch back to pen and repeat from step 1 (250-300 trials)

wacData = [];

xc = displayInfo.xCenter;
yc = displayInfo.yCenter;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Select Target Location %%%%%%%%%%%%%%%%%%%

dotXpos = xc; %target X location
dotYpos = yc-125; %target Y location
targetLoc = [dotXpos dotYpos];
startPos = [displayInfo.xCenter displayInfo.screenYpixels-175];

sampDots = [xc yc]';

HideCursor;
%%%%%%%%%%%%%%%%%%%%%%%%%% Output Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%location information
trialNum =[];                   %trial number
targetSector = [];              %sector of target location (1-6, 1 is bottom left, 6 is bottom right)
wXwY = nan(displayInfo.totalTrials,2);      %wacom coordinates for end point
endPointWac = [];               %true end X and Y
endPointPtb = [];               %feedback X and Y after perturbation applied
confRad = [];                   %confidence rating circle radius
fixError =[];                   %error (in pixels) from fixation
respDist = [];                  %euclidian distance from true target location to end point
circStart = [];                 %size of circle at start of conf. trial
tform = displayInfo.tform;
pktData = zeros(1,5);
pktData3 = [];

%timestamps
tarAppearTime = [];             %target appearance time
moveStart = [];                 %movement start time
moveEnd = [];                   %movement end time
startTimes = [];                %start time of trial

%duration measures
speedthreshold = 10;
framerate = Screen('NominalFrameRate',displayInfo.window2);
inTimes = [];                   %time it takes for participant to get inside fixation
RTs = [];                       %time it takes for participant to start response
MTs = [];                       %duration of movement
tabletData = [];

%Because tablet is smaller than projected area:
topBuff = [0 0 displayInfo.screenXpixels displayInfo.screenAdj/2]; %black bar at top of screen
bottomBuff = [0 displayInfo.screenYpixels-displayInfo.screenAdj/2 displayInfo.screenXpixels displayInfo.screenYpixels]; %black bar at bottom of screen

%%%%%%%%%%%%%%%%%%%%%%%%%% Initalizing powerMate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pm = PsychPowerMate('Open');            %will read a numeric value.

%%%%%%%%%%%%%%%%%%%%%%% Setting up escape and timing %%%%%%%%%%%%%%%%%%%%%%
% Define the ESC key
KbName('UnifyKeynames');                    %get key names
esc = KbName('ESCAPE');                     %set escape key code
[keyIsDown, secs, keyCode] = KbCheck;       % Exits experiment when ESC key is pressed.
% if keyIsDown
%     if keyCode(esc)
%         break
%     end
% end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INSTRUCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%
%INSTRUCTIONS PAGE 1 - experiment instructions
instructions1 = ('In this control experiment you will be reaching to the same point on every trial');
instructions2 = ('After each reach you will be asked to indicate your perceived reach angle using the dial');
instructions3 = ('A dot will represent your angle position, rotate it to the chosen location then press down to confirm your input');
instructions4 = (' ');
instructions6 = ('Leave the pen in positioned on the tablet and report your endpoint with your left hand');
instructions5 = ('Press SPACE to move to next screen');
[instructionsX1, instructionsY1] = centreText(displayInfo.window, instructions1, 15);
[instructionsX2, instructionsY2] = centreText(displayInfo.window, instructions2, 15);
[instructionsX3, instructionsY3] = centreText(displayInfo.window, instructions3, 15);
[instructionsX4, instructionsY4] = centreText(displayInfo.window, instructions4, 15);
[instructionsX5, instructionsY5] = centreText(displayInfo.window, instructions5, 15);
[instructionsX6, instructionsY6] = centreText(displayInfo.window, instructions6, 15);
Screen('DrawText', displayInfo.window, instructions6, instructionsX6, instructionsY6+120, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1-40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions2, instructionsX2, instructionsY2, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions3, instructionsX3, instructionsY3+40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions4, instructionsX4, instructionsY4+80, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions5, instructionsX5, instructionsY5+160, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);
pause(2);

KbName('UnifyKeyNames');
KeyID = KbName('space');
ListenChar(2);
%Waits for key press
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(KeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);

%INSTRUCTIONS PAGE 2 - exploring screen
instructions1 = ('Please take the next 10 seconds to explore the tablet with the pen');
instructions2 = ('Move your hand with the pen around on the tablet like you are drawing');
instructions3 = ('Practice trials will automatically begin after 10 seconds');
instructions5 = ('Press SPACE to start');
[instructionsX1, instructionsY1] = centreText(displayInfo.window, instructions1, 15);
[instructionsX2, instructionsY2] = centreText(displayInfo.window, instructions2, 15);
[instructionsX3, instructionsY3] = centreText(displayInfo.window, instructions3, 15);
[instructionsX5, instructionsY5] = centreText(displayInfo.window, instructions5, 15);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1-40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions2, instructionsX2, instructionsY2, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions3, instructionsX3, instructionsY3+40, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions5, instructionsX5, instructionsY5+160, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);
pause(2);

KbName('UnifyKeyNames');
KeyID = KbName('space');
ListenChar(2);
%Waits for key press
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(KeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);

%%
%%%%%%%%%%%%%%%%%%%%%%%%% EXPLORE SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This uses PROJECTOR COORDINATES to allow participant to explore the tablet
%and get used to the dimentions etc.
tic
tt = 0;
while tt <= 10          %run for 10 seconds
    % Get the current position of the mouse
    [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
    [x1, y1] = transformPointsForward(tform,x,y);
    
    % Draw a white dot where the mouse cursor is
    Screen('DrawDots', displayInfo.window, [x1 y1], 10, displayInfo.whiteVal, [], 2);
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
    
    % Flip to the screen
    Screen('Flip', displayInfo.window);
    tt = toc;
end


%%
%%%%%%%%%%%%%%%%%%%%%%%% Experimental Code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
contResultsMat = struct();
tic                                                     %start block timer
jj = 1;
for bb = 1:numBlocks                                    %run for number of blocks in fucntion settings
    timeFlag = 0;                                       %flag to reshuffle trial order of remaining permutations if trial was missed do to timing error
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Permutations %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for tt = 1:numIter                                  %run for set number of iterations within a block
        while jj < 7
            
            %%%%%%%%%%%%%%%%%%%%%%%%% Initalizing GetMouse %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [x, y, buttons] = GetMouse(displayInfo.window2);
            
            while gamephase <= 5
                %%%%%%%%%%%%%%%%%%%%%%%% Begin drawing to screen %%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %Start Screen
                if gamephase == 0                       %starting screen
                    
                    startTimes(trial) = toc;            %capture start time
                    t = toc;                            %make relative time point
                    temp = 1;                           %temp counting variable
                    
                    if trial == 1
                    instructions = 'Begin Control Experiment';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('Flip', displayInfo.window);
                    
                    pause(1)
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Visualizations Begin %%%%%%%%%%%%%%%
                    
                    while temp == 1
                        %Starting instruction screen
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.controlRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white fixation circle and hold until target turns green';
                        [instructionsX, instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                        [x1, y1] = transformPointsForward(tform,x,y);
                        fixError(trial,1) = x1-displayInfo.xCenter; fixError(trial,2) = y1-(displayInfo.screenYpixels-175); %fixation check (must be inside circle)
                        %Show cursor when near fixation to help center at
                        %start
                        if abs(fixError(trial,1)) <= 50 && abs(fixError(trial,2)) <= 50
                            Screen('DrawDots', displayInfo.window, [x1 y1], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen location
                        end
                        if abs(fixError(trial,1)) <= displayInfo.baseRect(3)/2 && abs(fixError(trial,2)) <=displayInfo.baseRect(3)/2 && buttons(1) == 1 %if error is smaller than fixation radius and pen is touching surface
                            gamephase = 1;                      %move forward to next phase
                            inTimes(trial) = toc - t;           %save time it took to find fixation
                            pause(displayInfo.pauseTime);
                            t = toc;                            %relative time point
                            temp = 0;                           %conditions are met
                            
                        else
                            temp = 1;                           %repeat until conditions are met
                        end
                        Screen('Flip', displayInfo.window);
                    end
                    penLoc = [x,y];
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Target Appears %%%%%%%%%%%%%%%%%%%
                elseif gamephase == 1
                    
                    for frame = 1:displayInfo.numFrames         %display target for numFrames seconds
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %target
                        Screen('DrawDots', displayInfo.window, [x1 y1], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.controlRect, 2,2); %fixation circle
                        Screen('Flip', displayInfo.window);
                        tarAppearTime(trial,1) = toc;
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                        [x1, y1] = transformPointsForward(tform,x,y);
                        
                        if ~buttons(1) || sqrt(sum(([x y] - penLoc).^2)) > displayInfo.baseRect(3) %if they lift the pen during target display or move out of circle
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                            instructions = 'Jumped the gun!';
                            [instructionsX, instructionsY] = centreText(displayInfo.window, instructions, 15);
                            Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                            Screen('Flip', displayInfo.window);
                            timeFlag = 1;                       %flag for reshuffling of locations when repeated
                            gamephase = 99;                     %restart trial phase
                            pause(displayInfo.iti+.3);
                            break
                        end
                    end
                    t = toc;                                    %relative time point
                    if gamephase == 1
                        while sqrt(sum(([x y] - penLoc).^2)) < displayInfo.baseRect(3) && toc-t<displayInfo.respWindow %while fixation is held and less than .6 seconds has elapsed
                            
                            [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                            Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %go cue target
                            Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.controlRect, 2,2); %fixation circle
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                            Screen('Flip', displayInfo.window);
                        end
                        
                        if  sqrt(sum(([x y] - penLoc).^2)) < displayInfo.baseRect(3) && toc-t > displayInfo.respWindow       %if elapsed time is longer than the response window (.6 seconds)
                            instructions = 'Too slow';
                            [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                            Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                            Screen('Flip', displayInfo.window);
                            timeFlag = 1;                       %flag for reshuffling of locations when repeated
                            gamephase = 99;                     %restart trial phase
                            pause(displayInfo.iti+.3);
                        else
                            gamephase = 2;                      %if no mistakes are made move to next trial phase
                        end
                        
                    end
                    RTs(trial) = toc-t;                         %elapsed response time
                    t = toc;                                    %relative time point
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Participant Response %%%%%%%%%%%%%%%
                elseif gamephase == 2
                    
                    %%%%%% TABLET POSITION COLLECTION
                    trialLength = displayInfo.respWindow +.2; %record buffer at the end of response time
                    
                    %This loop runs for trialLength seconds.
                    start = GetSecs;
                    stop  = start + trialLength;
                    
                    for frame = 1: framerate * trialLength  %once movement has started and lasts under .6 seconds
                        moveStart(trial,1) = toc;               %movement start time
                        loopStart = GetSecs;
                        
                        if frame <= framerate * trialLength
                            Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.controlRect, 2,2); %fixation circle
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                            Screen('Flip', displayInfo.window);
                        end
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2);
                        pkt = [x,y,buttons(1), (GetSecs - start), 1];
                        locdiff = sqrt(sum((pktData(end,1:2) - pkt(1:2)).^2));
                        pktData = [pktData; pkt];
                        if locdiff < 1
                            pktData(end,5) = 0;
                            break
                        end
                        
                    end
                    pktData2 = pktData(2:end,:);  %Assemble the data and then transpose to arrange data in columns because of Matlab memory preferences
                    pktData = zeros(1,5);
                    pktData2 = [pktData2 trial*ones(size(pktData2,1),1)];
                    if sum(pktData2(:,1)) == 0
                        ShowCursor;
                        instructions = 'Wacom not recording data! Restart!';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        Screen('Flip', displayInfo.window);
                        error('Wacom not recording data! Restart!');
                        break
                    end
                    tabletData = [tabletData; pktData2;];
                    

                    %no feedback during trial
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('Flip', displayInfo.window);
                    
                    
                    if sum(pktData2(:,5)== 0)>=1
                        tempX = pktData2(find(pktData2(:,5) == 0,1,'first'),1); %find X location at stopping point
                        tempY = pktData2(find(pktData2(:,5) == 0,1,'first'),2); %find Y location at stopping point
                    else
                        tempX = pktData2(end,1); %find X location at stopping point
                        tempY = pktData2(end,2); %find Y location at stopping point
                    end
                    [tempEP(1) tempEP(2)] = transformPointsForward(displayInfo.tform,tempX,tempY);
                    
                    %calculate reach endpoint angle
                    radius = sqrt(sum((targetLoc - startPos).^2)); %radius
                    reachDist = sqrt(sum((tempEP - startPos).^2)); %hypotenus
                    zeroAngle = sqrt(sum((tempEP - [startPos(1)+radius startPos(2)]).^2)); %opposite
                    endPtAngle(trial) = real(acosd((radius^2 + reachDist^2 - zeroAngle^2)/(2*radius*reachDist))); %angle in degrees
                    endPointLine(trial,:) = [(radius*cosd(360-endPtAngle(trial)))+startPos(1) (radius*sind(360-endPtAngle(trial))+startPos(2))];
                    
                    if endPtAngle(trial) > 130 || endPtAngle(trial) < 50         %If reach was not in direction of target
                        instructions = 'Reach toward target!';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('Flip', displayInfo.window);
                        timeFlag = 1;                           %flagging for reshuffling of locations on repeat
                        gamephase = 99;                         %restart trial phase
                        pause(displayInfo.iti+.3);
                    end
                    
                    if sum(pktData2(:,5)== 0)<1 || pktData2(min(find(pktData2(:,5) == 0)),4) > trialLength -.2         %if movement was longer than .8 seconds
                        instructions = 'Too slow';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('Flip', displayInfo.window);
                        timeFlag = 1;                           %flagging for reshuffling of locations on repeat
                        gamephase = 99;                         %restart trial phase
                        pause(displayInfo.iti+.3);
                    end
                    if (sum(pktData2(:,3) == 0)) > 1            %if they picked up their hand
                        
                        instructions = 'Do not pick up hand during reach!';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('Flip', displayInfo.window);
                        timeFlag = 1;                           %flagging for reshuffling of locations on repeat
                        gamephase = 99;                         %restart trial phase
                        pause(displayInfo.iti+.5);
                    end
                    MTs(trial) = toc - t;                       %elapsed movement time
                    moveEnd(trial,1) = toc;                     %movement end timing saved
                    
                    if gamephase ~= 99
                        if sum(pktData2(:,5)== 0)>=1
                            wX = pktData2(find(pktData2(:,5) == 0,1,'first'),1); %find X location at stopping point
                            wY = pktData2(find(pktData2(:,5) == 0,1,'first'),2); %find Y location at stopping point
                        else
                            wX = pktData2(end,1); %find X location at stopping point
                            wY = pktData2(end,2); %find Y location at stopping point
                        end
                        wXwY(trial,1) = wX; wXwY(trial,2) = wY;
                        [endPointWac(trial,1) endPointWac(trial,2)] = transformPointsForward(displayInfo.tform,wX,wY); %transform into projector space
                        %respDist(trial,1) = sqrt( (targetLoc(1)-endPointWac(trial,1))^2 + (targetLoc(2)-endPointWac(trial,2))^2); %euclidian distance to target from true end point%if no timing mistakes were made
                        
                        gamephase = 3;
                        t = toc;                                %relative time point
                    end
                    pktData3 = [pktData3; pktData2];
                    clear pktData2
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reporting End Point %%%%%%%%%%%%%%%%%
                elseif gamephase == 3
                    
                    %%%%%%%%%%%%%%%%%%%% Report Locations in Tablet Space %%%%%%%%%%%%%%
                    theta = (180:.2:360).*pi/180;          %report locations in half circle, step sizes for dial
                    x = radius*cos(theta);
                    y = radius*sin(theta);
                    reportLocs = [x+startPos(1);(y+startPos(2))]; %target locations in PIXEL space
                    
                    %feedback report start location
                    [buttonPM, dialPos] = PsychPowerMate('Get',pm); %initalize powermate
                    startDial = dialPos;                        %get dial's starting position
                    arcStartIdx(trial) = randi([400,500],1);               %set arc degrees to start (randomly)

                    
                    %while dial is spinning to report endpoint
                    while ~buttonPM                             %until button on dial is pressed
                        
                        [buttonPM, dialPos] = PsychPowerMate('Get',pm); %get dial postion
                        
                        loc = arcStartIdx(trial) + (dialPos-startDial);
                        if loc > 900
                            loc = 900;
                        elseif loc < 1
                            loc = 1;
                        end 
                        
                        reportArc = reportLocs(:,loc); %arc size adjusted for starting dial postion
                        
                        Screen('DrawDots', displayInfo.window, reportArc, displayInfo.dotSizePix, displayInfo.whiteVal, [], 2);
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %go cue target
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.controlRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('Flip', displayInfo.window);
                        
                        if ~buttons(1)            %if they picked up their hand
                            instructions = 'Do not pick up while reporting endpoint!';
                            [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                            Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                            Screen('Flip', displayInfo.window);
                            
                            timeFlag = 1;                           %flagging for reshuffling of locations on repeat
                            gamephase = 99;                         %restart trial phase
                            pause(displayInfo.iti+.5);
                            break
                        end
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Feedback %%%%%%%%%%%%
                        temp = 1;
                    while temp == 1
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.controlRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white circle to view feedback';
                        [instructionsX, instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                        [x1, y1] = transformPointsForward(tform,x,y);
                        fixError(trial,1) = x1-displayInfo.xCenter; fixError(trial,2) = y1-(displayInfo.screenYpixels-175); %fixation check (must be inside circle)
                        %Show cursor when near fixation to help center at
                        %start
                        if abs(fixError(trial,1)) <= 50 && abs(fixError(trial,2)) <= 50
                            Screen('DrawDots', displayInfo.window, [x1 y1], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen location
                        end
                        if abs(fixError(trial,1)) <= displayInfo.baseRect(3)/2 && abs(fixError(trial,2)) <=displayInfo.baseRect(3)/2 && buttons(1) == 1 %if error is smaller than fixation radius and pen is touching surface
                            gamephase = 1;                      %move forward to next phase
                            inTimes(trial) = toc - t;           %save time it took to find fixation
                            pause(displayInfo.pauseTime);
                            t = toc;                            %relative time point
                            temp = 0;                           %conditions are met
                            
                        else
                            temp = 1;                           %repeat until conditions are met
                        end
                        Screen('Flip', displayInfo.window);
                    end
                    for frame = 1:displayInfo.numFrames         %display feedback for 1 second
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %go cue target
                        Screen('DrawDots', displayInfo.window, reportArc, displayInfo.dotSizePix, displayInfo.whiteVal, [], 2);
                        Screen('DrawDots', displayInfo.window, endPointLine(trial,:), displayInfo.dotSizePix, displayInfo.rectColor, [], 2);
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.controlRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Feedback';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        Screen('Flip', displayInfo.window);
                    end
                    
                    if gamephase ~=99
                        endptChosen(trial,:) = reportArc;
                        fbTime = toc - t;                           %elapsed time for rating to be set
                        zeroAngle = sqrt(sum((reportArc' - [startPos(1)+radius startPos(2)]).^2)); %opposite
                        reportAngle(trial) = real(acosd((radius^2 + radius^2 - zeroAngle^2)/(2*radius*radius))); %angle in degrees
                        
                        pause(displayInfo.pauseTime)
                        gamephase = 5;                              %move on to final trial phase
                    end
                    %  end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Trial %%%%%%%%%%%%%%%%%%%
                elseif gamephase == 5
                    
                    clear buttons;
                    
                    if jj == displayInfo.numTrials(bb)          %if this is last trial
                        instructions = 'End of Run';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        trialNum(trial) = trial;                %save trial number
                        trial = trial+1;                        %update trial counter
                        jj = jj+1;                              %update iteration counter
                        gamephase = 6;                          %signal end of trial
                    else
                        instructions = 'Get ready for next trial';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                        trialNum(trial) = trial;
                        jj = jj+1;
                        trial = trial+1;
                        gamephase = 6;
                    end
                    % Flip to the screen
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('Flip', displayInfo.window);
                    pause(displayInfo.iti);
                    
                    %saving trial by trial output incase of a crash
                    fd = fopen([saveFile,'_controltrial_',num2str(trial-1)],'w');
                    fprintf(fd,'trial=%f tarLocX=%f tarLocY=%f endptChosenX=%f  endptChosenY=%f wacEndPtX=%f wacEndPtY=%f',...
                        trialNum(trial-1),targetLoc,endptChosen(trial-1,:),endPointWac(trial-1,:));
                    fclose(fd);
                    
                elseif gamephase == 99                          %flagged as a repeat trial
                    9999999                                     %visual output for testing
                    gamephase = 0;                              %reset trial phase for restart
                    instructions = 'Get ready for next trial';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('Flip', displayInfo.window);
                    pause(displayInfo.iti);
                end
            end
            gamephase = 0;                                      %reset trial phase at the end of trial
        end
        jj = 1;                                                 %reset location count at the end of iteration
    end
    
    
    
    %End of block screen
    KbName('UnifyKeyNames');
    spaceKeyID = KbName('space');
    ListenChar(2);
    
    instructions = 'End of block - Press space bar to continue';
    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
    
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
    Screen('Flip', displayInfo.window);
    
    %Waits for space bar
    [keyIsDown, secs, keyCode] = KbCheck;
    while keyCode(spaceKeyID)~=1
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    ListenChar(1);
    
    motorError = std(endPtAngle(~isoutlier(endPtAngle)));
    %% %%%%%%%%%%%%%%%%%%%%%%%%% Save output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    contResultsMat.trialNum = trialNum;
    contResultsMat.targetLoc = targetLoc;
    contResultsMat.targetDist = radius;
    contResultsMat.startPos = startPos;
    contResultsMat.wacEndPoint = wXwY;
    contResultsMat.wacScreenEnd = endPointWac;
    contResultsMat.endPtAngle = endPtAngle;
    contResultsMat.endPointLine = endPointLine;
    contResultsMat.motorError = motorError;
    contResultsMat.reportAngle = reportAngle;
    contResultsMat.chosenEndPt = endptChosen;
    contResultsMat.fixError = fixError;
    %contResultsMat.respDist = respDist;
    contResultsMat.tarAppearTime = tarAppearTime;
    contResultsMat.moveStart = moveStart;
    contResultsMat.moveEnd = moveEnd;
    contResultsMat.startTimes = startTimes;
    contResultsMat.inTimes = inTimes;
    contResultsMat.RTs = RTs;
    contResultsMat.MTs = MTs;
    
    contResultsMat.xPos = tabletData(:,1);
    contResultsMat.yPos = tabletData(:,2);
    contResultsMat.buttonState = tabletData(:,3);
    contResultsMat.getsecTimeStamp = tabletData(:,4);
    
    contResultsMat.tabletData = tabletData;
    contResultsMat.pktData = pktData3;
    save([displayInfo.fSaveFile,'_controlresults.mat'],'contResultsMat');
end
%% %%%%%%%%%%%%%%%%%%%%%%%%% FINAL SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%

KbName('UnifyKeyNames');
spaceKeyID = KbName('space');
ListenChar(2);

instructions = 'End of Experiment - Thank you for participating!';
[instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);

Screen('Flip', displayInfo.window);

%Waits for space bar
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(spaceKeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);
end



