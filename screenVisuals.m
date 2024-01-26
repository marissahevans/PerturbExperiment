function [displayInfo] = screenVisuals(displayInfo)
%Updating the displayInfo structure with trial specific visual info for the
%experiment. 

%Target dot appearance
dotColor = [0 1 0];             %green
dotSizePix = 6;                %Dot size in pixels

displayInfo.dotColor = dotColor;
displayInfo.dotSizePix = dotSizePix;

%Set the color of the confidence oval to yellow
rectColor = [1 1 0];            %yellow

displayInfo.rectColor = rectColor;

%fixation circle
fixation = [displayInfo.xCenter,displayInfo.yCenter];%fixation location
baseRect = abs([0 0 15 15]);    %fixation circle size
controlRect = CenterRectOnPointd(baseRect, displayInfo.xCenter, displayInfo.screenYpixels-175); %fixation circle centered coordinates
centeredRect = CenterRectOnPointd(baseRect, displayInfo.xCenter, displayInfo.yCenter); %fixation circle centered coordinates

displayInfo.fixation = fixation;
displayInfo.baseRect = baseRect;
displayInfo.centeredRect = centeredRect;
displayInfo.controlRect = controlRect;

%Number of testable target locations
numTargets = 4;

displayInfo.numTargets = numTargets;

end

