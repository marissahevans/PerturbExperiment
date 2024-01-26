 function [tform, calibration,startPhase] = wacCalib(displayInfo)
%VERSION FOR PERTURBATION EXPERIMENT!!!!!
%9 point calibration for WACOM tablet and projector screen. Includes
%calibration, affine transform, calibration test, and acceptance check.

fullScreen = [0 0 displayInfo.screenXpixels2 displayInfo.screenYpixels2];
Screen('FillRect', displayInfo.window2,displayInfo.whiteVal, fullScreen);
Screen('Flip', displayInfo.window2);

[~, ~, buttons] = GetMouse(displayInfo.window);

wacData = [];

xc = displayInfo.xCenter;
yc = displayInfo.yCenter;

sampDots = [50 150; 50 yc; 50 630; xc 150; xc yc; xc 630; 960 150; 960 yc; 960 630;]';

%Initialize wintabmex
WinTabMex(0, displayInfo.window);   %Initialize tablet driver, connect it to active window
trialLength = .3;                   %record buffer at the end of response time
samplingRate = 60;                  %displayInfo.tabSamplingRate;
deltaT = 1/samplingRate;            %sampling rate per second
HideCursor;

%On screen text instructions before calibration start
KbName('UnifyKeyNames');
KeyID = KbName('space');
ListenChar(2);

instructions = 'Please press spacebar when ready to start the calibration';
instructions1 = ('Place pen on each dot as it turns green and HOLD while dot is red.');
instructions2 = ('Hold the pen like you would a regular pencil. Touching the tablet surface with your hand will not have any effect on your input.');
[instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
[instructionsX1 instructionsY1] = centreText(displayInfo.window, instructions1, 15);
[instructionsX2 instructionsY2] = centreText(displayInfo.window, instructions2, 15);
Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY+120, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions2, instructionsX2, instructionsY2+60, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);

%Waits for space key to continue to calibration
[keyIsDown, secs, keyCode] = KbCheck;
while keyCode(KeyID)~=1
    [keyIsDown, secs, keyCode] = KbCheck;
end
ListenChar(1);

%Draw all 9x dots on screen
Screen('DrawDots', displayInfo.window, sampDots, displayInfo.dotSizePix, [.75 .75 .75], [], 2);
Screen('Flip', displayInfo.window);
pause(1)

testphase = 0;                      %denotes input phase waiting for press or not

a = 1:length(sampDots);             %number of dots to be tested
vecInt = [a a];                     %test all points twice
xyPair = vecInt(randperm(length(vecInt))); %randomize points order

%Start sampling loop
for ii = 1:length(xyPair)
    j = xyPair(ii);                 %which dot is being selected
    xy = sampDots(:,j);             %coordinates of selected dot
    
    while testphase == 0    % waiting for pen to touch down
        [x, y, buttons] = GetMouse(displayInfo.window);
        xy2 = [x;y;]
        Screen('DrawDots', displayInfo.window, sampDots, displayInfo.dotSizePix, [.75 .75 .75], [], 2);
        Screen('DrawDots', displayInfo.window, xy, displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %target
        Screen('Flip', displayInfo.window);
        if buttons(1) %&& sum(abs(xy - xy2))<51 %if pen is touching tablet and within a 21pt radius of target
            testphase = 1;
            clear buttons x y
            %WINTABMEX TABLET POSITION COLLECTION
            %Set up a variable to store data
            pktData = [];           %will hold data from each iteration
            WinTabMex(2);           %Empties the packet queue in preparation for collecting actual data
            
            %This loop runs for trialLength seconds.
            start = GetSecs;        %start time in seconds
            stop  = start + trialLength;
            
            while GetSecs < stop
                Screen('DrawDots', displayInfo.window, sampDots, displayInfo.dotSizePix, [.75 .75 .75], [], 2);
                Screen('DrawDots', displayInfo.window, xy, displayInfo.dotSizePix,[1 0 0], [], 2); %red target
                Screen('Flip', displayInfo.window);
                loopStart = GetSecs;
                
                %This loop runs for deltaT or until it successfully retrieves some data from the queue
                while 1  %Note this loop MUST be broken manually, as 'while 1' always returns TRUE
                    
                    pkt = WinTabMex(5);
                    
                    %This check breaks the loop if data is recovered from the queue before deltaT is up
                    if ~isempty(pkt)
                        break
                    end
                    
                    %This check breaks the loop after deltaT if pkt was always empty
                    if GetSecs>(loopStart+deltaT)
                        pkt = zeros(9,1); %Dummy data representing a missed data point
                        break;
                    end
                end
                pkt = [pkt; (GetSecs - start)]; %add timing column
                pktData = [pktData pkt];        %collect location data over time
                
                %Waits to end of deltaT if need be
                if GetSecs<(loopStart+deltaT)
                    WaitSecs('UntilTime', loopStart+deltaT);
                end
                
            end
            pktData2 = pktData';  %Assemble the data and then transpose to arrange data in columns because of Matlab memory preferences
            pktData2 = [pktData2 j*ones(length(pktData2),1)]; %add dot location
            
            %Error if tablet is not recording data. Restart matlab and
            %clear all prior to restart
            if sum(pktData2(:,1)) == 0
                instructions = 'Wacom not recording data! Restart Matlab!';
                [instructionsX, instructionsY] = centreText(displayInfo.window, instructions, 15);
                Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
                Screen('Flip', displayInfo.window);
                testphase = 0;
                pause(.5)
                
                ShowCursor;
                error('Wacom not recording data! Restart Matlab!');
                break
            else
                wacData = [wacData; pktData2;]; %save location data for each point
            end
        else
            testphase = 0;  %continue to wait for accepted pen touch
        end
    end
    
    WinTabMex(3);                               % Stop/Pause data acquisition.
    
    %all grey dots on screen between targets
    Screen('DrawDots', displayInfo.window, sampDots, displayInfo.dotSizePix, [.75 .75 .75], [], 2);
    Screen('Flip', displayInfo.window);
    pause(.5)
    testphase = 0;
end
WinTabMex(1);
pause(1)

calib = wacData;                                %change variable name

for ii = 1:9                                    %separate data by dot location
    test1 = calib((calib(:,11) == ii),:);       %find location data for each dot
    test1 = test1((test1(:,4) == 1),:);         %save only data when pen was touching down
    wacX(ii) = mean(test1(:,1));                %mean WACOM space x coordinate
    wacY(ii) = mean(test1(:,2));                %mean WACOM space y coordinate
end

y1 = [1 7 5 3 8 9 2 4 6];                       %order of points in the transform
%Affine transformation for 3x points at a time, averaged across all
%calculations for 9x points.
y = y1(1:3);
M1 = affine_least_square(wacX(y(1)),wacY(y(1)), wacX(y(2)),wacY(y(2)), wacX(y(3)),wacY(y(3)),sampDots(1,y(1)),sampDots(2,y(1)), sampDots(1,y(2)),sampDots(2,y(2)), sampDots(1,y(3)),sampDots(2,y(3)));
y = y1(4:6);
M2 = affine_least_square(wacX(y(1)),wacY(y(1)), wacX(y(2)),wacY(y(2)), wacX(y(3)),wacY(y(3)),sampDots(1,y(1)),sampDots(2,y(1)), sampDots(1,y(2)),sampDots(2,y(2)), sampDots(1,y(3)),sampDots(2,y(3)));
y = y1(7:9);
M3 = affine_least_square(wacX(y(1)),wacY(y(1)), wacX(y(2)),wacY(y(2)), wacX(y(3)),wacY(y(3)),sampDots(1,y(1)),sampDots(2,y(1)), sampDots(1,y(2)),sampDots(2,y(2)), sampDots(1,y(3)),sampDots(2,y(3)));

M = (M1 + M2 + M3)./3;                          %transformation matrix

tform = affine2d(M');                           %affine 2d transformation matrix
calibration = {M, M1, M2, M3, calib, wacX, wacY,  sampDots}; %compiling all calibration info

%% %%%%%%%%%%%%%% Test if calibration is good %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Testing calibration instructions
instructions1 = ('Place pen on the tablet now and slowly move the pen around as you would a pencil for 10 seconds - if you do not see dot lift pen briefly');
instructions2 = ('Watch to see if the dot on screen matches with the tip of your pen visible through the mirror, some lag is normal');
[instructionsX1, instructionsY1] = centreText(displayInfo.window, instructions1, 15);
[instructionsX2, instructionsY2] = centreText(displayInfo.window, instructions2, 15);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1, displayInfo.whiteVal);
Screen('DrawText', displayInfo.window, instructions2, instructionsX2, instructionsY2+60, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);
pause(5)

%Sometimes the dot will not be visible if the pen is touching down before
%the time starts
instructions1 = ('Feedback Begins Now');
[instructionsX1, instructionsY1] = centreText(displayInfo.window, instructions1, 15);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);
pause(.2)

WinTabMex(0, displayInfo.window);

trialLength = .01;                 %record buffer at the end of response time
samplingRate = 300;                %higher sampling rate to reduce lag;
deltaT = 1/samplingRate;           %samples per second

tic;
timeElapse = 0;
pktData = [];
WinTabMex(2);                   %Empties the packet queue in preparation for collecting actual data

while timeElapse < 10               %This loop runs for 10 seconds.
    %Set up a variable to store data
    
    start = GetSecs;                %start time in seconds
    stop  = start + trialLength;
    while GetSecs < stop
        
        loopStart = GetSecs;
        
        %This loop runs for deltaT or until it successfully retrieves some data from the queue
        while 1  %Note this loop MUST be broken manually, as 'while 1' always returns TRUE
            
            pkt = WinTabMex(5);
            
            %This check breaks the loop if data is recovered from the queue before deltaT is up
            if ~isempty(pkt)
                break
            end
            
            %This check breaks the loop after deltaT if pkt was always empty
            if GetSecs>(loopStart+deltaT)
                pkt = zeros(9,1);      %Dummy data representing a missed data point
                break;
            end
        end
        pkt = [pkt; (GetSecs - start)]; %add sample time
        pktData = [pktData pkt];
        
        %Waits to end of deltaT if need be
        if GetSecs<(loopStart+deltaT)
            WaitSecs('UntilTime', loopStart+deltaT);
        end
    end
    %Drawing the pen point on the screen using transform
    [x, y] = transformPointsForward(tform,pktData(1,end),pktData(2,end));
    Screen('DrawDots', displayInfo.window, [x y], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen location
    Screen('Flip', displayInfo.window);
    
    
    timeElapse = toc;               %save elapsed time
    clear x y
end
WinTabMex(3);                   % Stop/Pause data acquisition.

Screen('FillRect', displayInfo.window2,displayInfo.blackVal, fullScreen);
Screen('Flip', displayInfo.window2); %return wacom screen to black

%Ask if calibration was good and should be saved, or if it needs to be
%redone
instructions1 = ('To use this calibration press P, or to redo the calibration press Q');
[instructionsX1 instructionsY1] = centreText(displayInfo.window, instructions1, 15);
Screen('DrawText', displayInfo.window, instructions1, instructionsX1, instructionsY1, displayInfo.whiteVal);
Screen('Flip', displayInfo.window);

%Listen for key press input from participant
ListenChar(2);
acceptedKeys = [KbName('p'), KbName('q')];
responded = 0;
while responded == 0
    [~,~,KeyCode] = KbCheck;
    if any(KeyCode(acceptedKeys))
        strResponse = KeyCode;
        responded = 1;
        if strResponse(acceptedKeys(1)) %save the transform and the calibration
            startPhase = 1;
        elseif strResponse(acceptedKeys(2)) %restart the loop and run the calibration function again
            startPhase = 0;
        end
    end
    % time between iterations of KbCheck loop
    WaitSecs(0.001);
end

ShowCursor;
ListenChar(1);
WinTabMex(1);                       %shut down tablet listening
end


