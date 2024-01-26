%% Perturb Reach Experiment main operational code
%This file is the main control script for the experiment. For each session
%edit the necessary information in the Participant Info section then run
%from thi s script.

%This s  cript calls several functions, namely:
%screenVisuals.m - sets up colors and screens
%startExp.m - st  arts psychToolbox
%controlExpSigmaP.m - session 1 control expe riment (+practice trials)
%pracTrialSeq.m - practice trial s  for main experiment
%t rialSeq.m - main experimental trials

%Output is save as results.mat and dispInfo.mat

%setting the file path
cd('C:\Users\labadmin\Documents\perturbationExperiment');
%% Experiment start
% Clear the workspace and the screen
sca;
close all;
clearvars;
%%%%%%%%%%%%%%%%%%%%%%%% Participant Info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subj = 'MF';                        %participant initials
session = 01;                      %session being run {01, 02, 03, or 04)
redoCalib = 0;                    %force re-calibration. Always 0 unless session calibration was inaccurate, then 1
prac = 0;                            %If running practice block 1, otherwise 0
sigmaPtest = 0;                     %If running control experiment 1, otherwise 0
ptbType = 2;                        %if 1 uses explict block perterbation, if 2 uses implicit ramp perterbation
%% DO NOT EDIT BELOW THIS LINE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sigmaPtest == 1
    numBlocks = 5;              %number of blocks
    numIter = 10;                   %times 6 for total number of trials per block
else
    numBlocks = 4;              %number of blocks
    numIter = 25;                   %number of iterations across all 4x locations
end
expName = 'perturb';          %experiment title

confTrial = 1;                  %how often does a confidence trial appear
restart = 0;                    %Always 0

dateTime = clock;               %gets time for seed
rng(sum(100*dateTime));         %sets seed to be dependent on the clock

%%%%%%%%%%%%%%%%%%%%%%%%% File Save Path %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%using file save stucture function from Shannon

%create save structure for practice trials
if prac == 1
    [prac_exp,prac_fSaveFile,prac_tSaveFile,prac_restart] = expDataSetup(expName,subj,session,'practice',restart);
end

%create save structure for experimental trials
[exp,fSaveFile,tSaveFile,restart] = expDataSetup(expName,subj,session,'exp',restart);

%% %%%%%%%%%%%%%%%%%%%%%%% Setting up Psychtoolbox %%%%%%%%%%%%%%%%%%%%%%%%

%Standard settings for number of screens, screen size, screen selection,
%refresh rate, color space, and screen coordinates.
[displayInfo] = startExp(subj,datetime,rng);

%%
%%%%%%%%%%%%%%%%%%%%%%% Visual Trial Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Visual settings includng target color, size, location, quantity,
%confidence circle color and shape, fixation circle color and shape

[displayInfo] = screenVisuals(displayInfo);

%% %%%%%%%%%%%%%%%%%%%%% Screen Calibration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Check if calibration for TODAY already exists for a given participant, and
%no recalibration has been requested
if exist(['data_perturb\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_tform.mat']) && redoCalib == 0
    load(['data_perturb\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_tform.mat']) %load calibration incase of restart
    load(['data_perturb\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_calibration.mat'])
else
    %9 point calibration for WACOM tablet and projector screen. Includes
    %calibration, affine transform, calibration test, and acceptance check.
    startPhase = 0;
    while startPhase == 0
        [tform, calibration,startPhase] = wacCalib2(displayInfo);
        if startPhase == 1
            save(['data_perturb\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_tform.mat'],'tform')
            save(['data_perturb\' subj '\' subj '_' expName '_S' num2str(session) '_' date,'_calibration.mat'],'calibration')
        end
        pause(1);
    end
    
    %% %%%%%%%% Pause in experiment to change to full siver mirror %%%%%%%%%%%%
    
    instructions = ('Please wait for experimenter to change mirror, then press T to continue to the experiment');
    [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
    Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
    Screen('Flip', displayInfo.window);
    
    KbName('UnifyKeyNames');
    tKeyID = KbName('t');
    ListenChar(2);
    
    %Waits for T key to move forward with experiment
    [keyIsDown, secs, keyCode] = KbCheck;
    while keyCode(tKeyID)~=1
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    ListenChar(1);
    
end

%%%%%%%%%%%%%%%%%%%% Target Sector Locations in Tablet Space %%%%%%%%%%%%%%
%target location base sectors
theta = (1:360).*pi/180;          %six sections for targets in radians
radius = 200;                       %chosen radius - this is how far all points are away from the hand
x = radius*cos(theta);
y = radius*sin(theta);

Xstrt = displayInfo.fixation(1);                %untransformed starting point
Ystrt = displayInfo.fixation(2);                %untransformed starting point

targets = [x+Xstrt;(y+Ystrt)]; %target locations in PIXEL space

displayInfo.tarLocsX = reshape(targets(1,:),[90 4]); %target locations in PIXEL space
displayInfo.tarLocsY = reshape(targets(2,:),[90 4]);
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Specifics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%starting position for values within the trial loop
gamephase = 0;                  %trial phase start
trial = 1;                      %trial counter start

% Practice specifics if practice is happening
if prac == 1
    pracIter = 5;               %if practice how many iterations
    pracBlocks = 1;              %if practice how many blocks
    pracNumTrials = ones(pracBlocks,1)*(pracIter*displayInfo.numTargets); %total trial number per block must be a factor of 4
    pracTotalTrials = sum(pracNumTrials);   %total trials in all blocks
    
    %saving to file structure
    displayInfo.pracIterations = pracIter;
    displayInfo.pracBlocks = pracBlocks;
    displayInfo.pracNumTrials = pracNumTrials;
    displayInfo.pracTotalTrials = pracTotalTrials;
end

%settings specific to the trial set
numTrials = ones(numBlocks,1)*(numIter*displayInfo.numTargets); %total trial number per block must be a factor of 4
sessTrials = numTrials(1);
totalTrials = sum(numTrials);   %total trials in all blocks
numSecs = .5;                    %stimulus hold time
numFrames = round(numSecs/displayInfo.ifi); %stimulus hold time on screen adjusted for refresh
tarDispTime = round(.25/displayInfo.ifi);   %target display duration
pauseTime = .3;                  %pauses within trial
iti = .3;                        %inter-trial interval in seconds
respWindow = .8;                %time participant has to respond

%saving trial specifics to structure
displayInfo.radius = radius;
displayInfo.numBlocks = numBlocks;
displayInfo.numIterations = numIter;
displayInfo.numTrials = numTrials;
displayInfo.totalTrials = totalTrials;
displayInfo.confTrial = confTrial;
displayInfo.numFrames = numFrames;
displayInfo.pauseTime = pauseTime;
displayInfo.iti = iti;
displayInfo.tarDispTime = tarDispTime;
displayInfo.respWindow = respWindow;
displayInfo.tform = tform;
displayInfo.calibration = calibration;
displayInfo.fSaveFile = fSaveFile ;

%% Run control experiment if requested at top of code
%first block is practice trials
if sigmaPtest == 1
    save([fSaveFile,'_dispInfo.mat'],'displayInfo')
    [controlDat,motorError] = controlExpSigmaPV1(displayInfo, numBlocks, numIter, gamephase, trial, fSaveFile);
    save(['data_perturb\' subj '\motorError.mat'],'motorError')
    %saving visual and system settings for experimental trials
else
    %% Perterbation Angle Information
    %Perturbation structure
    ptb = zeros(1,sessTrials);
    ptbAngle = zeros(1,sessTrials);
    order = [1 2 1 2]; %rotate left, rotate right, rotate left, rotate right
    
    %Explicit set amount:
    if ptbType == 1
        ptbAngle(20:70) = 20;
        %Like a ramp (implicit)
    elseif ptbType == 2
        ptbAngle(20:70) = [linspace(0,20,45),20*ones(1,6)];
    end
    
     %based on participant motor error:
        %     if exist(['data_perturb\' subj '\motorError.mat'])
        %         load(['data_perturb\' subj '\motorError.mat'])
        %         ptbDist = normpdf(0:90,0,motorError);
        %         ptbMag = find(ptbDist == min(ptbDist(ptbDist>.0001)));
        %         %Single step function
        %         ptbAngle(20:70) = ptbMag;
        %     else
        %         warning('Control Task must be run FIRST')
        %     end
        
        %STEP SIZE LIKE A STAIRCASE
        %     theta = [0:4:20,16:-4:4]; %Theta angle in staircase step sizes
        %     ptbOrder = reshape(2:61,6,10);
        %     for ii = 1:length(theta)
        %         ptbAngle(ptbOrder(:,ii)) = theta(ii);
        %     end
    
    displayInfo.ptbAngle = ptbAngle;
    displayInfo.ptbOrder = order;
    %%
    %%%%%%%%%%%%%%%%%%%%%%% Save Display Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %saving visual and system settings for practice trials
    if prac == 1
        save([prac_fSaveFile,'_dispInfo.mat'],'displayInfo')
    end
    
    %saving visual and system settings for experimental trials
    save([fSaveFile,'_dispInfo.mat'],'displayInfo')
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%% Run Practice Trials %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if prac == 1
        HideCursor;
        [prac_resultsMat] = pracTrialSeqPerturb(displayInfo, pracBlocks, pracIter, gamephase, trial, prac_fSaveFile);
        
        save([prac_fSaveFile,'_pracResults.mat'],'prac_resultsMat'); %save data from practice
        
        %Wait screen before continuing to experiment
        instructions = ('To continue on to the experimental trials, please press the space bar');
        [instructionsX instructionsY] = centreText(displayInfo.window, instructions, 15);
        Screen('DrawText', displayInfo.window, instructions, instructionsX, instructionsY, displayInfo.whiteVal);
        Screen('Flip', displayInfo.window);
        pause(1);
        
        KbName('UnifyKeyNames');
        KeyID = KbName('space');
        ListenChar(2);
        
        %Waits for T key
        [keyIsDown, secs, keyCode] = KbCheck;
        while keyCode(KeyID)~=1
            [keyIsDown, secs, keyCode] = KbCheck;
        end
        ListenChar(1);
        ShowCursor;
        %clear tablet
        
    end
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%% Run Experiment Trials %%%%%%%%%%%%%%%%%%%%%%%%%%
    HideCursor;
    [resultsMat] = trialSeq(displayInfo, numBlocks, numIter, gamephase, trial, fSaveFile);
    
    save([fSaveFile,'_results.mat'],'resultsMat'); %saves final expermimental data (also saved at the end of each run, and text files per trial)
    ShowCursor;
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%% Finish Experiment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %'end' page is displayed at the end of the experimental trials
    %clear tablet
    
end
% Clear the screen
sca;