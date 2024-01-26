%% The top version transforms the starting points from pixel space to wacom
%space, finds the coordinates in wacom space then transforms back into
%pixel space. The 2nd version just finds the points in pixel space (to
%determin of the location calculations were correct). The only difference
%between the two is the use of the transformation. 

%I've used this same transformation when testing the calibration and the
%points are accurate. I've also used both the forward and inverse
%transforms in the analysis and the points show up where they are supposed
%to be. 

%The only thing specifically unique to this is the double tranformation
%(forward then backward on the same data), although logically I cant figure
%out why that would be an issue. 

%This code will run without any additional files, any data that is pulled
%in from outside I've coded into the top. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%values from the calibration affine least squares. The transform has been
%tested live by taking the pen location in wacom space, transforming it to
%pixel space and projecting it on the surface. The pen tip and projected
%point line up perfectly at all points of the screen. 
M = [0.000090746947157   0.000000059343229  -1.422089384582093;...
    0.000000819645677  -0.000039893129946   1.063178889676743;...
                    0                   0   0.001000000000000];
              
M = M*1.0e+03;                      %resize
tform = affine2d(M');               %create transformation matrix

%set up PsychToolbox window
screens = Screen('Screens');        % Get the screen numbers
screenNumber = max(screens)-1;
white = WhiteIndex(screenNumber);   % Define white color spaces
black = BlackIndex(screenNumber);   % Define black color spaces
grey = white/2;                     % Define grey color spaces
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey); % Open a grey on screen window

fixation = [512 593];               %fixation point in pixel space
[Xstrt, Ystrt] = transformPointsInverse(tform,fixation(1),fixation(2)); %affine transform from pixel to wacom space

%%%%%%%%%%%%%%%%%%%% Target Sector Locations in Tablet Space %%%%%%%%%%%%%%

% %target location base sectors
theta = (0:36:180).*pi/180;          %six sections for targets in radians
radius = 4000;                       %chosen radius - this is how far all points are away from the hand
x = radius*cos(theta);
y = radius*sin(theta);
targets = [x+Xstrt; abs(y+Ystrt)]';

[Xtars, Ytars] = transformPointsForward(tform,targets(:,1),targets(:,2)); %affine transform for wacom to pixel space
tarLocs = [Xtars Ytars]; %target locations in PIXEL space

Screen('DrawDots', window, tarLocs', 10, [.75 .75 .75], [], 2);
Screen('Flip', window);

pause
%%
%testing using pixel space (no affine transformation. This is what the
%points are supposed to look like (without accounting for the slight warp
%in wacom space due to forshortening)
%%%%%%%%%%%%%%%%%%%% Target Sector Locations in Tablet Space %%%%%%%%%%%%%%
%target location base sectors
theta = (0:36:180).*pi/180;          %six sections for targets in radians
radius = 400;                       %chosen radius - this is how far all points are away from the hand
x = radius*cos(theta);
y = radius*sin(theta);

Xstrt = fixation(1);                %untransformed starting point
Ystrt = fixation(2);                %untransformed starting point

tarLocs = [x+Xstrt; abs(y-Ystrt)]; %target locations in PIXEL space

Screen('DrawDots', window, tarLocs, 10, [.75 .75 .75], [], 2);
Screen('Flip', window);
