 function [resultsMat] = trialSeq(displayInfo,numBlocks, numIter, gamephase, trial,saveFile)
%THIS IS FOR THE PERTURBATION TASK
%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Output Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%location information
trialNum =[];                   %trial number
targetLoc = [];                 %tar X and tar Y (after jitter applied)
targetSector = [];              %sector of target location (1-6, 1 is bottom left, 6 is bottom right)
wXwY = nan(displayInfo.totalTrials,2);      %wacom coordinates for end point
endPointWac = [];               %true end X and Y
endPointPtb = [];               %feedback X and Y after perturbation applied
confRad = [];                   %confidence rating circle radius
fixError =[];                   %error (in pixels) from fixation
respDist = [];                  %euclidian distance from true target location to end point
arcSize = [];                 %size of circle at start of conf. trial
tform = displayInfo.tform;
pktData = zeros(1,6);
pktData3 = [];

%timestamps
tarAppearTime = [];             %target appearance time
moveStart = [];                 %movement start time
moveEnd = [];                   %movement end time
startTimes = [];                %start time of trial

%duration measures
framerate = Screen('NominalFrameRate',displayInfo.window2);
inTimes = [];                   %time it takes for participant to get inside fixation
RTs = [];                       %time it takes for participant to start response
MTs = [];                       %duration of movement
tabletData = [];

tarLocationsX = displayInfo.tarLocsX';  %possible target locations
tarLocationsY = displayInfo.tarLocsY';

%Because tablet is smaller than projected area:
topBuff = [0 0 displayInfo.screenXpixels displayInfo.screenAdj/2]; %black bar at top of screen
bottomBuff = [0 displayInfo.screenYpixels-displayInfo.screenAdj/2 displayInfo.screenXpixels displayInfo.screenYpixels]; %black bar at bottom of screen
%% %%%%%%%%%%%%%%%%%%%%%%% Setting up PowerMate %%%%%%%%%%%%%%%%%%%%%%%%%%%


pm = PsychPowerMate('Open');            %will read a numeric value.


%%
%%%%%%%%%%%%%%%%%%%%%%%% Experimental Code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blockScore =0;                                          %Score for each block
possibleScore = 0;                                      %possible score for each block given performance

resultsMat = struct();
tic                                                     %start block timer
jj = 1;                                                 %start counter for while loop
for bb = 1:numBlocks                                    %run for number of blocks in fucntion settings
    blockTrial = 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Permutations %%%%%%%%%%%%%%%%%%%%%%%%%%%
    tarOrder = cell2mat(arrayfun(@(tarLocations) randperm(displayInfo.numTargets), 1:numIter, 'UniformOutput',false)')'; %shuffle possible target locations
    timeFlag = 0;                                       %flag to reshuffle trial order of remaining permutations if trial was missed do to timing error
    
    for tt = 1:numIter                                  %run for set number of iterations within a block
        while jj < displayInfo.numTargets +1            %loop through each target location one time
            
            
            %%%%%%%%%%%%%%%%%%%%%%% Setting up escape and timing %%%%%%%%%%%%%%%%%%%%%%
            % Define the ESC key
            KbName('UnifyKeynames');                    %get key names
            esc = KbName('ESCAPE');                     %set escape key code
            [keyIsDown, secs, keyCode] = KbCheck;       % Exits experiment when ESC key is pressed.
            if keyIsDown
                if keyCode(esc)
                    break
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% Initalizing GetMouse %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [x, y, buttons] = GetMouse(displayInfo.window2);
            
            while gamephase <= 5
                %%%%%%%%%%%%%%%%%%%%%%%% Begin drawing to screen %%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %Start Screen
                if gamephase == 0                       %starting screen
                    
                    startTimes(trial) = toc;            %capture start time
                    t = toc;                            %make relative time point
                    temp = 1;                           %temp counting variable
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Select Target Location %%%%%%%%%%%%%%%%%%%
                    
                    if timeFlag == 1                    %if time flag is 1, participant is restarting trial (due to taking too long to respond)
                        tarOrder(jj:end,tt) = Shuffle(tarOrder(jj:end,tt)); %shuffle remaining possible locations including location which was skipped
                        timeFlag = 0;                   %return time flag to zero for future trials
                    end
                    tarPos = tarOrder(jj,tt);           %order in which target locations appear
                    resultsMat.tarOrder(trial,:) = tarOrder(jj,tt);
                    
                    jitter = randi(90); %normal distribtion around center of selected arc
                 
                    dotXpos = tarLocationsX(tarPos,jitter); %target X location after jitter is applied
                    dotYpos = tarLocationsY(tarPos,jitter); %target Y location after jitter is applied.
                    
                    targetLoc(trial,1) = dotXpos; targetLoc(trial,2) = dotYpos; %target position saved
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Visualizations Begin %%%%%%%%%%%%%%%
                    
                    while temp == 1
                        %Starting instruction screen
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white fixation circle';
                        [instructionsX, instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                        [x1, y1] = transformPointsForward(tform,x,y);
                        startPos = [displayInfo.xCenter displayInfo.yCenter];
                        fixError(trial,1) = x1-displayInfo.xCenter; fixError(trial,2) = y1-(displayInfo.yCenter); %fixation check (must be inside circle)
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
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %target
                        Screen('DrawDots', displayInfo.window, [x1 y1], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
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
                            pause(displayInfo.iti);
                            break
                        end
                    end
                    t = toc;                                    %relative time point
                    if gamephase == 1
                        while buttons(1) && sqrt(sum(([x y] - penLoc).^2)) < displayInfo.baseRect(3) && toc-t<displayInfo.respWindow %while fixation is held and less than .6 seconds has elapsed
                            
                            [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                            Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
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
                    else
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
                            Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                            Screen('Flip', displayInfo.window);
                        end
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2);
                        pkt = [x,y,buttons(1), (GetSecs - start), 1, displayInfo.ptbOrder(bb)];
                        locdiff = sqrt(sum((pktData(end,1:2) - pkt(1:2)).^2));
                        [lx ly] = transformPointsForward(displayInfo.tform,x,y);
                        locDist = sqrt(sum(([lx ly] - [displayInfo.xCenter displayInfo.yCenter]).^2));
                        pktData = [pktData; pkt];
                        if locDist >= 200
                            pktData(end,5) = 2;
                        end
                        if locdiff < 1
                            pktData(end,5) = 0;
                            break
                        end
                        
                    end
                    pktData2 = pktData(2:end,:);  %Assemble the data and then transpose to arrange data in columns because of Matlab memory preferences
                    pktData = zeros(1,6);
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
                    
                    if sum(pktData2(:,5)== 2)<1 || pktData2(min(find(pktData2(:,5) == 2)),4) > trialLength -.2         %if movement was longer than .8 seconds
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
                            wXend = pktData2(find(pktData2(:,5) == 0,1,'first'),1); %find X location at stopping point
                            wYend = pktData2(find(pktData2(:,5) == 0,1,'first'),2); %find Y location at stopping point
                        else
                            wXend = pktData2(end,1); %find X location at stopping point
                            wYend = pktData2(end,2); %find Y location at stopping point
                        end
                        
                        wXwYend(trial,1) = wXend; wXwYend(trial,2) = wYend;
                        [endPointWac(trial,1) endPointWac(trial,2)] = transformPointsForward(displayInfo.tform,wXend,wYend); %transform into projector space
                        respDist(trial,1) = sqrt( (targetLoc(trial,1)-endPointWac(trial,1))^2 + (targetLoc(trial,2)-endPointWac(trial,2))^2); %euclidian distance to target from true end point%if no timing mistakes were made
                        
                        wXline = pktData2(find(pktData2(:,5) == 2,1,'first'),1); %find X location at line cross
                        wYline = pktData2(find(pktData2(:,5) == 2,1,'first'),2); %find Y location at line cross
                        wXwYline(trial,1) = wXline; wXwYline(trial,2) = wYline;
                        [endPointline1(1) endPointline1(2)] = transformPointsForward(displayInfo.tform,wXline,wYline); %transform into projector space
                        
                        if rem(trial,displayInfo.confTrial) == 0 %if it is a confidence judgement trial
                            gamephase = 3;                      %confidence test phase
                            pause(displayInfo.pauseTime)
                        else
                            gamephase = 4;                      %feedback phase
                            pause(displayInfo.pauseTime)
                        end
                        t = toc;                                %relative time point
                    end
                    pktData3 = [pktData3; pktData2];
                    clear pktData2
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Confidence Report %%%%%%%%%%%%%%%%%
                elseif gamephase == 3
                    temp=0; %1 if moving pen before reporting confidence, 0 if not.
                    while temp == 1
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white circle to report confidence';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                        [x1, y1] = transformPointsForward(tform,x,y);
                        fixError(trial,1) = x1-endPointWac(1); fixError(trial,2) = y1-(displayInfo.yCenter); %fixation check (must be inside circle)
                        
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
                    
                    [buttonPM, dialPos] = PsychPowerMate('Get',pm); %initalize powermate
                    startDial = dialPos;                        %get dial's starting position
                    arcStart(trial) = randi([1,22],1);               %set arc degrees to start (randomly)
                    
                    while ~buttonPM                             %until button on dial is pressed
                        
                        [buttonPM, dialPos] = PsychPowerMate('Get',pm); %get dial postion
                        
                        arcSize(trial) = arcStart(trial) + (dialPos-startDial); %arc size adjusted for starting dial postion
                        baseRect3 = [0 0 displayInfo.radius*2 displayInfo.radius*2] ;
                        
                        centeredRect3 = CenterRectOnPointd(baseRect3, displayInfo.xCenter, displayInfo.yCenter);
                        angles = [180 270 360 90];
                        startAngle = angles(tarPos)-(90-jitter);
                        
                        %points to circle size calculation
                        if abs(arcSize(trial))*2 > 45                 %if the arc is larger than the target quadrant
                            pointsPos = 0;
                        elseif abs(arcSize(trial))*2 <= 2           %if the radius is smaller than the target size
                            pointsPos = 10;
                        else
                            pointsPos = 10-(10/(45-2)*((abs(arcSize(trial))*2)-2)); %10 points are possible across a 150 pixel radius
                            
                        end
                        
                       Screen('DrawArc',displayInfo.window, displayInfo.rectColor,centeredRect3,startAngle,arcSize(trial))
                       Screen('DrawArc',displayInfo.window, displayInfo.rectColor,centeredRect3,startAngle-arcSize(trial),arcSize(trial))
                       Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle 
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Confidence arc is centered on target, make arc just large enough to intersect feedback - smaller arc = closer to goal';
                        [instructionsX] = centreText(displayInfo.window, instructions, 15);
                        instructions1 = 'Points only collected if final arc size would intersect the feedback';
                        [instructions1X] = centreText(displayInfo.window, instructions1, 15);
                        points = ['Points possible: ' num2str(pointsPos)];
                        [pointsX, pointsY] = centreText(displayInfo.window, points, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, displayInfo.yCenter-280, displayInfo.whiteVal);
                        Screen('DrawText', displayInfo.window, instructions1, instructions1X, displayInfo.yCenter-240, displayInfo.whiteVal);
                        Screen('DrawText', displayInfo.window, points, pointsX, pointsY-200, displayInfo.whiteVal);
                        Screen('Flip', displayInfo.window);
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                        [x1, y1] = transformPointsForward(tform,x,y);
                        epError(trial,1) = x1-endPointWac(trial,1); epError(trial,2) = y1-endPointWac(trial,2); %fixation check (must be inside circle)
                        
                        if abs(epError(trial,1)) >= 10 || abs(epError(trial,2)) >= 10
                            alert = 'Do not move pen from reach endpoint location!';
                            [alertX, alertY] = centreText(displayInfo.window, alert, 15);
                            Screen('DrawText', displayInfo.window, alert, alertX, alertY-200, displayInfo.whiteVal);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                            Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                            Screen('Flip', displayInfo.window);
                            timeFlag = 1;                           %flagging for reshuffling of locations on repeat
                            gamephase = 99;                         %restart trial phase
                            pause(displayInfo.iti+.5);
                            break
                        end
                        
                    end
                    if gamephase ~= 99
                        fbTime = toc - t;                           %elapsed time for rating to be set
                        confAngle(trial,1) = abs(arcSize(trial))*2;          %angle of confidence arc
                        angles = [0 90 180 270];
                        tarAngle(trial) = angles(tarPos)+jitter;
                        
                        reachDist = sqrt(sum((endPointline1 - [displayInfo.xCenter displayInfo.yCenter]).^2)); %hypotenus
                        zeroAngle = sqrt(sum((endPointline1 - [displayInfo.xCenter+displayInfo.radius displayInfo.yCenter]).^2)); %opposite
                        endPtAngle = real(acosd((displayInfo.radius^2 + reachDist^2 - zeroAngle^2)/(2*displayInfo.radius*reachDist))); %angle in degrees
                        if endPointline1(2) < startPos(2)
                            endPtAngle = 360 - endPtAngle;
                        end
                        
                        
                        if displayInfo.ptbOrder(bb) == 1 %rotate left
                            endPointLine(trial,:) = [(displayInfo.radius*cosd(endPtAngle+displayInfo.ptbAngle(blockTrial)))+displayInfo.xCenter (displayInfo.radius*sind(endPtAngle+displayInfo.ptbAngle(blockTrial)))+displayInfo.yCenter];
                            xPtb = endPointLine(trial,1);
                            yPtb = endPointLine(trial,2);
                            ptbPointAngle(trial,:) = endPtAngle+displayInfo.ptbAngle(blockTrial);
                            endPointAngle(trial,:) = endPtAngle;
                        elseif displayInfo.ptbOrder(bb) == 2 %rotate right
                            endPointLine(trial,:) = [(displayInfo.radius*cosd(endPtAngle-displayInfo.ptbAngle(blockTrial)))+displayInfo.xCenter (displayInfo.radius*sind(endPtAngle-displayInfo.ptbAngle(blockTrial)))+displayInfo.yCenter];
                            xPtb = endPointLine(trial,1);
                            yPtb = endPointLine(trial,2);
                            ptbPointAngle(trial,:) = endPtAngle-displayInfo.ptbAngle(blockTrial);
                            endPointAngle(trial,:) = endPtAngle;
                        end
                        
                        endPointPtb(trial,1) = xPtb; endPointPtb(trial,2) = yPtb;
                        adjcent = sqrt(sum(([dotXpos dotYpos]-endPointLine(trial,:)).^2));
                        cosTheta = (2*displayInfo.radius^2-adjcent^2)/(2*displayInfo.radius^2);
                        respErrorAngle(trial,1) = real(acosd(cosTheta));
                        
                        
                        %Points possible for a reach angle, regardless of
                        %confidence
                        if respErrorAngle(trial,1) > 45/2                 %if error is greater than 45 degrees
                            pointsPossible(trial,1) = 0;
                        elseif respErrorAngle(trial,1) <= 1 %if error is smaller than the target size
                            pointsPossible(trial,1) = 10;
                        else
                            pointsPossible(trial,1) = 10 -(10/(22.5-1)*(respErrorAngle(trial,1)-1));   %points out of 10 across a 150 pixel radius
                        end
                        
                        %Points distribution based on perturbed endpoint.
                        if confAngle(trial,1)/2 >= round(respErrorAngle(trial,1)) %-4 to crop at edge of dot
                            pointsEarned(trial,1) = pointsPos;
                        else
                            pointsEarned(trial,1) = 0;
                        end
                        clear buttonPM
                        pause(displayInfo.pauseTime)
                        
                        gamephase = 4;                              %move on to final trial phase
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Feedback %%%%%%%%%%%%%%%%%%%%%%%%%
                elseif gamephase == 4
                    temp = 0; %1 if returning to center before feedback, 0 if not
                    while temp == 1
                        Screen('FrameOval', displayInfo.window, displayInfo.whiteVal, displayInfo.centeredRect, 2,2); %fixation circle
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        instructions = 'Place pen inside white circle to view feedback';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        
                        [x, y, buttons] = GetMouse(displayInfo.window2); %get pen position
                        [x1, y1] = transformPointsForward(tform,x,y);
                        fixError(trial,1) = x1-displayInfo.xCenter; fixError(trial,2) = y1-(displayInfo.yCenter); %fixation check (must be inside circle)
                        
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
                    
                    for frame = 1:displayInfo.numFrames*2         %display feedback for 1 second
                        Screen('DrawArc',displayInfo.window, displayInfo.rectColor,centeredRect3,startAngle,arcSize(trial))
                       Screen('DrawArc',displayInfo.window, displayInfo.rectColor,centeredRect3,startAngle-arcSize(trial),arcSize(trial))
                        Screen('DrawDots', displayInfo.window, [dotXpos dotYpos], displayInfo.dotSizePix, displayInfo.rectColor, [], 2); %target location
                        if pointsEarned(trial,1) ~= 0
                            Screen('DrawDots', displayInfo.window, [xPtb yPtb], displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %perturbed endpoint location
                        else
                            Screen('DrawDots', displayInfo.window, [xPtb yPtb], displayInfo.dotSizePix, [1 0 0], [], 2); %perturbed endpoint location
                        end
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                        Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                        points = ['Points earned: ' num2str(pointsEarned(trial,1))];
                        [pointsX, pointsY] = centreText(displayInfo.window, points, 15);
                        Screen('DrawText', displayInfo.window, points, pointsX, displayInfo.yCenter, displayInfo.whiteVal);
                        Screen('Flip', displayInfo.window);
                    end
                    
                    endPointPtb(trial,1) = xPtb; endPointPtb(trial,2) = yPtb;
                    gamephase = 5;                              %move on to final trial phase
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Trial %%%%%%%%%%%%%%%%%%%
                elseif gamephase == 5
                    targetSector(trial,1) = tarPos;             %save target position since trial was fully completed
                    clear buttons;
                    
                    if jj == displayInfo.numTrials(bb)          %if this is last trial
                        instructions = 'End of Run';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        trialNum(trial) = trial;                %save trial number
                        trial = trial+1;                        %update trial counter
                        jj = jj+1;                              %update iteration counter
                        gamephase = 6;                          %signal end of trial
                        blockTrial = blockTrial+1;
                    else
                        instructions = 'Get ready for next trial';
                        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
                        trialNum(trial) = trial;
                        jj = jj+1;
                        trial = trial+1;
                        gamephase = 6;
                        blockTrial = blockTrial+1;
                    end
                    % Flip to the screen
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
                    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
                    Screen('Flip', displayInfo.window);
                    pause(displayInfo.iti);
                    
                    %saving trial by trial output incase of a crash
                    fd = fopen([saveFile,'_trial_',num2str(trial-1)],'w');
                    fprintf(fd,'trial=%f tarLocX=%f tarLocY=%f tarSec=%f wacEndPtX=%f wacEndPtY=%f confAngle=%f',...
                        trialNum(trial-1), targetLoc(trial-1,:), targetSector(trial-1,:),wXwYline(trial-1,:),confAngle(trial-1,1));
                    fclose(fd);
                    
                elseif gamephase == 99                          %flagged as a repeat trial
                    9999999                                     %visual output for testing
                    gamephase = 0;                              %reset trial phase for restart
                    clear pktData2
                    instructions = 'Get ready for next trial';
                    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
                    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%% END OF BLOCK SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%
    blockScore(bb) = sum(pointsEarned) - sum(blockScore);       %score for this block
    runningScore(bb) = sum(pointsEarned);                       %running score across all blocks
    possibleScore(bb) = sum(pointsPossible) - sum(possibleScore); %possible score based on performance
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%% Save output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    resultsMat.trialNum = trialNum;
    resultsMat.targetLoc = targetLoc;
    resultsMat.targetSector = targetSector;
    resultsMat.startPos = startPos;
    resultsMat.wacEndPoint = wXwY;
    resultsMat.wacScreenEnd = endPointWac;
    resultsMat.alignedEnd = endPointLine;
    resultsMat.feedbackLoc = endPointPtb;
    resultsMat.feedbackAngle = ptbPointAngle;
    resultsMat.endPtAngle = endPointAngle;
    resultsMat.respErrorAngle = respErrorAngle;
    resultsMat.tarAngle = tarAngle;
    resultsMat.arcSize = arcSize;
    resultsMat.confArcStart = arcStart*2;
    resultsMat.confAngle = confAngle;
    resultsMat.fixError = fixError;
    resultsMat.respDist = respDist;
    resultsMat.blockScore = blockScore;
    resultsMat.runningScore = runningScore;
    resultsMat.possibleScore = possibleScore;
    resultsMat.pointsEarned = pointsEarned;
    resultsMat.pointsPossible = pointsPossible;
    resultsMat.tarAppearTime = tarAppearTime;
    resultsMat.moveStart = moveStart;
    resultsMat.moveEnd = moveEnd;
    resultsMat.startTimes = startTimes;
    resultsMat.inTimes = inTimes;
    resultsMat.RTs = RTs;
    resultsMat.MTs = MTs;
    
    resultsMat.xPos = tabletData(:,1);
    resultsMat.yPos = tabletData(:,2);
    resultsMat.buttonState = tabletData(:,3);
    resultsMat.getsecTimeStamp = tabletData(:,4);
    
    resultsMat.tabletData = tabletData;
    resultsMat.pktData = pktData3;
    save([displayInfo.fSaveFile,'_results.mat'],'resultsMat');
    
    %End of block screen
    KbName('UnifyKeyNames');
    spaceKeyID = KbName('space');
    ListenChar(2);
    
    instructions = 'End of block - Press space bar to begin next block';
    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);
    
    block = ['Your score so far: ' num2str(runningScore(bb))]';
    [blockX blockY] = centreText(displayInfo.window, block, 20);
    Screen('DrawText', displayInfo.window, block, blockX, blockY-100, displayInfo.whiteVal);
    
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
    Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
    Screen('Flip', displayInfo.window);
    
    %Waits for space bar
    [keyIsDown, secs, keyCode] = KbCheck;
    while keyCode(spaceKeyID)~=1
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    ListenChar(1);
    
end

%% %%%%%%%%%%%%%%%%%%%%%%%%% FINAL LEADERBORAD %%%%%%%%%%%%%%%%%%%%%%%%%%%
[names,points] = addToLeaderboard(['perturbExp_final'],displayInfo.subj,runningScore(end));

KbName('UnifyKeyNames');
spaceKeyID = KbName('space');
ListenChar(2);

instructions = 'End of Experiment - Thank you for participating!';
[instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY-200, displayInfo.whiteVal);

leader = ('------ Final Leader Board ------');
[leaderX leaderY] = centreText(displayInfo.window, leader, 20);
Screen('DrawText', displayInfo.window, leader, leaderX, leaderY-50, displayInfo.whiteVal);

line1 = [names{1} ':   ' num2str(points(1))];
[line1X line1Y] = centreText(displayInfo.window, line1, 15);
Screen('DrawText', displayInfo.window, line1, line1X, line1Y, displayInfo.whiteVal);

line2 = [names{2} ':   ' num2str(points(2))];
[line2X line2Y] = centreText(displayInfo.window, line2, 15);
Screen('DrawText', displayInfo.window, line2, line2X, line2Y+20, displayInfo.whiteVal);

line3 = [names{3} ':   ' num2str(points(3))];
[line3X line3Y] = centreText(displayInfo.window, line3, 15);
Screen('DrawText', displayInfo.window, line3, line3X, line3Y+40, displayInfo.whiteVal);

line4 = [names{4} ':   ' num2str(points(4))];
[line4X line4Y] = centreText(displayInfo.window, line4, 15);
Screen('DrawText', displayInfo.window, line4, line4X, line4Y+60, displayInfo.whiteVal);

line5 = [names{5} ':   ' num2str(points(5))];
[line5X line5Y] = centreText(displayInfo.window, line5, 15);
Screen('DrawText', displayInfo.window, line5, line5X, line5Y+80, displayInfo.whiteVal);

Screen('FillRect', displayInfo.window,displayInfo.blackVal, topBuff);
Screen('FillRect', displayInfo.window,displayInfo.blackVal, bottomBuff);
Screen('Flip', displayInfo.window);

pause(1);
%Waits for space bar
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(spaceKeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);
end

