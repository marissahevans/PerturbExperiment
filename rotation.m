%% Rotation

startX = 0; startY = 0; 

endPt = [0 100];

theta = 1%[4 8 12 16 20 30 45];

for ii = 1:length(theta)
    roTarg(ii,1) = (endPt(1)-startX)*cosd(theta(ii))-(endPt(2)-startY)*sind(theta(ii))+startX;
    roTarg(ii,2) = (endPt(1)-startX)*sind(theta(ii))+(endPt(2)-startY)*cosd(theta(ii))+startY;
    
    %roTarg(ii,1) = (endPt(1)-startX)*cosd(theta(ii))+(endPt(2)-startY)*sind(theta(ii))+startX;
    %roTarg(ii,2) = -(endPt(1)-startX)*sind(theta(ii))+(endPt(2)-startY)*cosd(theta(ii))+startY;
end

%% 
ptb = 80;
r = sqrt((endPt(1) - startX)^2+(endPt(2) - startY)^2);
cosTheta = (r^2 + r^2 - ptb^2)/(2*r^2);
theta = real(acosd(cosTheta));
%% Shift
for ii = 1:length(theta)
eucDist(ii) = sqrt(sum((endPt - roTarg(ii,:)).^2));
xVals(ii,:) = [endPt(1)-eucDist(ii),endPt(2)];
end
 
%% Gain
lenReach = sqrt(sum((endPt - [startX startY]).^2));
endPt2 = endPt -[startX startY];
unitReach = endPt2/lenReach;
for ii = 1:length(theta)
    newLen1 = lenReach + eucDist(ii);
    newLen2 = lenReach - eucDist(ii);
    plusGain(ii,:) = (unitReach*newLen1) + [startX startY];
    minusGain(ii,:) = (unitReach*newLen2) + [startX startY];
end

%% test distances
eucDist = round(eucDist,2);
shiftDist = round(sqrt(sum((endPt - xVals).^2,2)),2)';
gainDist = round(sqrt(sum((endPt - plusGain).^2,2)),2)';

shiftDist == eucDist
shiftDist == gainDist
gainDist == eucDist 

%% plot
figure; hold on
scatter(startX,startY,50,'filled')
scatter(endPt(1),endPt(2),50,'filled')
scatter(roTarg(:,1),roTarg(:,2),50,'filled')
scatter(xVals(:,1),xVals(:,2),50,'filled')
scatter(plusGain(:,1),plusGain(:,2),50,'filled')
ylim([0 400])
xlim([-200 200])
axis square

figure
plot(x,y)

