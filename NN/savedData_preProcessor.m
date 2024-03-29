% -------------------------------------------------------------------------
% This script allows the pre-processing of the data for the NN training and
% testing session. It contains different algorithms of extraction and it
% produces the files necessary for both position and force estimation
% predic
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Authors:      Cirelli Renato, Ventre Francesco, Salvatore Bella,
%               Alvaro Romero Calvo, Aloisia Russo.
% Team:         ARACNE
% Date:         24/09/2019
% Revision:     6
% ---------------------------- ChangeLog ----------------------------------
% 16/08/2019 - First Version
% 22/08/2019 - Second Version
% 23/08/2019 - Fixed the characteristic time value for the reference
%              sensor, corrected the outputX vector preallocations.
% 22/09/2019 - The processed signals are sampled at a specified sampling
%              frequency in Hz, the reuslting dataset is saved in the same
%              folder of the used compacted data.
% 24/09/2019 - Data is no loaded with GUI, the interpolation is an option,
%              two algorithms of characteristic data extraction are defined,
%              the output vector is now a concatenation of vectors.
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------

clear
close all
clc

%All the figure are docked in one window
set(0,'DefaultTextInterpreter','latex');
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultTextFontSize',12);
set(0,'DefaultAxesFontSize',12);

%% Load the compacted archive
% Choose a file
[filename1,filepath1] = uigetfile({'*.mat'},'Select Data For Trainin','MultiSelect','off');
% Load the chisen file
load([filepath1,filename1]);

% Loaded archive size
collDim = length(filesColl);

%% Preprocessor Parameters and Options

% Sensor ID to be consider (from 1 to 16)
sensSelIdx =1:16;

% Data point amplifier
dataPointAmpl = 2;

% Show data extraction plot during the pre-processing
showPlots = false;

%% DO NOT TOUCH THIS SECTION PLEASE

% Total numbero of selected sensor
sensCount  = length(sensSelIdx);

if sensCount>size(filesColl(1).myCollector.data.acc.z,1)
   error('Maximum number of sensor is %d',size(filesColl(1).myCollector.data.acc.z,1)); 
end

% Preallocation
charTime = zeros(sensCount,collDim);
charVal = zeros(sensCount,collDim);
sensPosX = zeros(sensCount,collDim);
sensPosY = zeros(sensCount,collDim);
sensDist = zeros(sensCount,collDim);
impF = zeros(1,collDim);
impPosX = zeros(1,collDim);
impPosY = zeros(1,collDim);
chosenInterp = -1;

% Figure set-up
if showPlots
    figure(10)
    handlerAx_1 = axes;
    hold on
end

% Iterate over the collection of simulations
for j = 1:collDim
    
    fprintf('Data extraction from simulation %d of %d\n',j,collDim);
    
    % Simulation time
    simTime = filesColl(j).myCollector.timeEval;
    % Simulation data to extract
    simData = filesColl(j).myCollector.data.disp.z(sensSelIdx,:);
    % Simulation length
    simL = filesColl(j).myCollector.Parameters.L;
    
    % Ask the first time only
    if chosenInterp == -1
        myList = {'Interpolate --> SPLINE','RAW Data from COMSOL'};
        [chosenInterp,tf] = listdlg('ListString',myList,'SelectionMode','single');
        if ~tf
            error('Please select an interpolation method.\n')
        end
        
        % Data Normalization dialog
        [chosenNorm,tf] = listdlg('ListString',...
                                 {'Normalize data -> sensor max. response',...
                                  'RAW data from COMSOL'},...
                                  'SelectionMode','single');
        if ~tf
            error('Please select normalization method.\n')
        end
    end
    
    % Perform the interpolation, if requested
    if chosenInterp == 1
        
        % Increased data point vector
        tempTime = linspace(simTime(1),simTime(end),length(simTime)*dataPointAmpl);

        % Preallocation
        dimRes = [sensCount,length(tempTime)];
        memData = zeros(dimRes);

        % Iterate the interpolation over the rows
        for rr = 1 : sensCount
            memData_fcn = griddedInterpolant(simTime,simData(rr,:),'spline');

            memData(rr,:) = memData_fcn(tempTime);
        end

        % Redefinition of the extracted data
        simTime = tempTime;
        simData = memData;
    end
    
    % Perform the normalization if requested
    if chosenNorm == 1
        % Normalization of the data in respect the sensr maximum response
        for sensSel = 1:sensCount
            simData(sensSel,:) = simData(sensSel,:)./max(abs(simData(sensSel,:)));
        end
    end
    
    % Show the data if requested
    if showPlots
        plot(handlerAx_1,simTime,simData');
    end
    
    % Loops on each considered sensor
    for k = 1:sensCount

% ---- Extraction algorithm #1
% -- Search the first intersection with zero after the maximum peak of
% -- the signal. If no sign change, search it aftet the minimum of the
% -- signal instead.

% %         % Search the maximum of theresponse
% %         [~,refIdx] = max(simData(k,:));
% %         
% %         % Find the index at which the zero is crossed and choose the
% %         % previose one
% %         charIdx = refIdx + find(simData(k,refIdx:end)<=0,1) -1;
% %         
% %         if isempty(charIdx)
% %             % Search the minimum instead
% %             [minResp,minIdx] = min(simData(k,:));
% %             charIdx = minIdx + find(simData(k,minIdx:end)>=0,1);
% %         end
% %         % Extract characteristic values
% %         charVal(k,j) = simData(k,charIdx);
% %         charTime(k,j) = simTime(charIdx);
% %         
% %         % Show the char time if requested
% %         if showPlots
% %             plot(charTime(k,j),charVal(k,j),'r.')
% %         end

% ---- Extraction algorithm #2
% -- Search the maximum and the minimum locations of the signal avoiding
% -- the point at the end of the integration period
        
         % Search the maximum of theresponse
         [~,rIdx] = max(simData(k,:));
         
         % If the maximum is at the end of the simulation the minimum is
         % considered (maximum of the inverted response)
         if rIdx == length(simTime)
             [~,rIdx] = max(-simData(k,:));
             [~,lIdx] = max(simData(k,1:rIdx));
         else
             % Search the minima of the response between the initial time
             % and the maximum value
             [~,lIdx] = min(simData(k,1:rIdx));
         end

        % Extract characteristic values
        charVal_l(k,j) = simData(k,lIdx);
        charVal_r(k,j) = simData(k,rIdx);
        charTime_l(k,j) = simTime(lIdx);
        charTime_r(k,j) = simTime(rIdx);
        
        % Show the char time if requested
        if showPlots
            plot(charTime_l(k,j),charVal_l(k,j),'r.')
            plot(charTime_r(k,j),charVal_r(k,j),'g.')
        end
        
% ---- Extraction algorithm #3
% --
% ---- Extraction algorithm #4
% -- ...
% ---- Extraction algorithm #5
% -- ...
        
        % Extract the position of the sensor
        sensPosX(k,j) = filesColl(j).myCollector.mesh.x(sensSelIdx(k),1)./simL;
        sensPosY(k,j) = filesColl(j).myCollector.mesh.y(sensSelIdx(k),1)./simL;
        
        sensDist(k,j) = norm([sensPosX(k,j);sensPosY(k,j)]);
        
    end
    
    % Pause the execution if the plots are requested
    if j ~= collDim && showPlots
        pause()
        cla
    end
    
    % Extract the impact properties
    impP = filesColl(j).myCollector.Parameters.P;
    impd = filesColl(j).myCollector.Parameters.d;
    
    % Compute the impact force
    impF(j) = pi*impP*(impd/2)^2;

    % Extract the impact location
    impPosX(j) = filesColl(j).myCollector.Parameters.impact(1)./simL;
    impPosY(j) = filesColl(j).myCollector.Parameters.impact(2)./simL;
    
end

fprintf('- - -\nData extraction completed :) \n\n')

% Show Impact Location referring the impact to the plate center
figure()
hold on
maxL = 0;
for j = 1:collDim
    
    plot(impPosX(j) - 1/2,impPosY(j) - 1/2,'r.','MarkerSize',30*impF(j)./max(impF))
    plot(sensPosX(:,j) -1/2,sensPosY(:,j) -1/2,'gO','MarkerFaceColor',[0.4660 0.6740 0.1880])
    
end

%% Definition of input and output vector for the training sessions

% ---- Extraction algorithm #1

% % % Input vector for position estimation
% % inputXp = charVal;
% % % Input vector for force estimation
% % inputXf = charVal;
% % % Output vector for position estimation
% % outputYp = [impPosX;
% %             impPosY];
% % % Output vector for force estimation
% % outputYf = impF./1e5; %[bar]

% ---- Extraction algorithm #2

% Input vector for position estimation
inputXp = [charVal_l;
           charVal_r;
           charTime_l;
           charTime_r];
% Input vector for force estimation
inputXf = [charVal_l;
           charVal_r;
           charTime_l;
           charTime_r];
% Output vector for position estimation
outputYp = [impPosX;
            impPosY];
% Output vector for force estimation
outputYf = impF./1e5; %[bar]

% ---- Extraction algorithm #3

% ---- Extraction algorithm #4

% ---- Extraction algorithm #5
% % 
% % %% Input Data Normalization
% % inputXp = mapminmax(inputXp')';
% % inputXf = mapminmax(inputXf')';

%%

% % Ass some noise
% inputXp = [inputXp,awgn(inputXp,40)];
% outputYp =[outputYp,outputYp];

%%
% Pre-processing info
preProcInfo.origin = filename1;
preProcInfo.sensIDs = sensSelIdx';
preProcInfo.sensCount = sensCount;
preProcInfo.interp = chosenInterp;
preProcInfo.dataPointAmpl = dataPointAmpl;
    
% Save the results for postion
inputX = inputXp;
outputY = outputYp;
tempStr = split(filename1,'.');
tmepStr = [filepath1,tempStr{1},'_preProcessed_NNpos.',tempStr{2}];
save(tmepStr,'preProcInfo','inputX','outputY');

% Save the results for force
inputX = inputXf;
outputY = outputYf;
tempStr = split(filename1,'.');
tmepStr = [filepath1,tempStr{1},'_preProcessed_NNfor.',tempStr{2}];
save(tmepStr,'preProcInfo','inputX','outputY');

fprintf('The pre-processed data has been saved in %s \n\n',tmepStr);