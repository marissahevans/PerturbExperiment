 function [tform, calibration,startPhase] = wacCalib2(displayInfo)
%9 point calibration for WACOM tablet and projector screen. Includes
%calibration, affine transform, calibration test, and acceptance check.

fullScreen = [0 0 displayInfo.screenXpixels2 displayInfo.screenYpixels2];
Screen('FillRect', displayInfo.window2,displayInfo.whiteVal, fullScreen);
Screen('Flip', displayInfo.window2);

xc = displayInfo.xCenter;
yc = displayInfo.yCenter;

sampDots = [50 150; 50 yc; 50 630; xc 150; xc yc; xc 630; 960 150; 960 yc; 960 630;]';

trialLength = .3;                   %record buffer at the end of response time
HideCursor;

%On screen text instructions before calibration start
KbName('UnifyKeyNames');
KeyID = KbName('space');
ListenChar(2);

instructions = 'Please press spacebar when ready to start the calibration';
instructions1 = ('As each dot turns green touch it with the pen one time, it will turn red when touched');
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


a = 1:length(sampDots);             %number of dots to be tested
vecInt = [a a];                     %test all points twice
Pairinedx = vecInt(randperm(length(vecInt))); %randomize points order
cursors = NaN(3,length(Pairinedx));

%Start sampling loop
for ii = 1:length(Pairinedx)
    j = Pairinedx(ii);                 %which dot is being selected
    xy = sampDots(:,j);             %coordinates of selected dot
    cursors(3,ii) = j;
    while true  % waiting for pen to touch down
        [x, y, buttons] = GetMouse(displayInfo.window2);
        Screen('DrawDots', displayInfo.window, sampDots, displayInfo.dotSizePix, [.75 .75 .75], [], 2);
        Screen('DrawDots', displayInfo.window, xy, displayInfo.dotSizePix, displayInfo.dotColor, [], 2); %target
        Screen('Flip', displayInfo.window);
        if buttons(1) %&& sum(abs(xy - xy2))<51 %if pen is touching tablet and within a 21pt radius of target
            cursors(1:2,ii) = [x,y];
            Screen('DrawDots', displayInfo.window, sampDots, displayInfo.dotSizePix, [.75 .75 .75], [], 2);
            Screen('DrawDots', displayInfo.window, xy, displayInfo.dotSizePix,[1 0 0], [], 2); %red target
            Screen('Flip', displayInfo.window);
            pause(trialLength);
            break
            %Error if tablet is not recording data. Restart matlab and
            %clear all prior to restart
        elseif KbCheck
            Screen('CloseAll');
            ShowCursor;
            break
        end
    end

    %all grey dots on screen between targets
    Screen('DrawDots', displayInfo.window, sampDots, displayInfo.dotSizePix, [.75 .75 .75], [], 2);
    Screen('Flip', displayInfo.window);
    pause(.5)
end
pause(1)

wacX = NaN(1,9);
wacY = NaN(1,9);

for ii = 1:9                                    %separate data by dot location
    test1 = cursors(:,(cursors(3,:) == ii));       %find location data for each dot
    wacX(ii) = mean(test1(1,:));                %mean WACOM space x coordinate
    wacY(ii) = mean(test1(2,:));                %mean WACOM space y coordinate
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
calibration = {M, M1, M2, M3, cursors, wacX, wacY,  sampDots}; %compiling all calibration info

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

         %samples per second

tic;
timeElapse = 0;

while timeElapse < 10               %This loop runs for 10 seconds.
    %Set up a variable to store data
    [x,y,~] = GetMouse(displayInfo.window2);

    %Drawing the pen point on the screen using transform
    [x1, y1] = transformPointsForward(tform,x,y);
    Screen('DrawDots', displayInfo.window, [x1 y1], displayInfo.dotSizePix, displayInfo.whiteVal, [], 2); %pen location
    Screen('Flip', displayInfo.window);
    
    timeElapse = toc;               %save elapsed time
end

Screen('FillRect', displayInfo.window2,displayInfo.blackVal, fullScreen);
Screen('Flip', displayInfo.window2); %return wacom screen to black

%Ask if calibration was good and should be saved, or if it needs to be
%redone
instructions1 = ('To use this calibration press P, or to redo the calibration press Q');
[instructionsX1,instructionsY1] = centreText(displayInfo.window, instructions1, 15);
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
end


