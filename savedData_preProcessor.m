%
% NN Data pre-processor for the position prediction
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato
% Team: ARACNE
% Date: 22/09/2019
% Revision: 6
%
% ChangeLog
% 16/08/2019 - First Version
% 22/08/2019 - Second Version
% 23/08/2019 - Fixed the characteristic time value for the reference
%              sensor, corrected the outputX vector preallocations.
% 22/09/2019 - The processed signals are sampled at a specified sampling
%              frequency in Hz, the reuslting dataset is saved in the same
%              folder of the used compacted data.
%
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

%clear filepath1 filename1

%% Preprocessor Parameters and Options

% Sensor ID to be consider (from 1 to 16)
sensSelIdx = 1:16;

% Sampling frequency of the acquisition system in Hz
sFreq = 5000; %Hz

% Show data extraction plot during the pre-processing
showPlots = false;

%% DO NOT TOUCH THIS SECTION PLEASE

% Total numbero of selected sensor
sensCount  = length(sensSelIdx);

if sensCount>size(filesColl(1).myCollector.data.acc.z,1)
   error('Maximum number of sensor is %d',size(filesColl(1).myCollector.data.disp.z,1)); 
end

% Preallocation
charTime = zeros(sensCount,collDim);
charVal = zeros(sensCount,collDim);
sensPosX = zeros(sensCount,collDim);
sensPosY = zeros(sensCount,collDim);
sensDist = zeros(sensCount,collDim);
impP = zeros(1,collDim);
impPosX = zeros(1,collDim);
impPosY = zeros(1,collDim);

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
    % Simulation data taken as reference data
    refData = filesColl(j).myCollector.data.disp.z(sensSelIdx,:);
    
    % Interp data along the rows and sample the signals at a certain
    % frequency
    
    % Acquisition time
    sTime = 1/sFreq;
    % Sampled time vector
    tempTime = simTime(1):sTime:simTime(end);
    
    % Preallocation
    dimRes = [sensCount,length(tempTime)];
    memData = zeros(dimRes);
    memDataRef = zeros(dimRes);
    
    % Iterate the interpolation over the rows
    for rr = 1 : sensCount
        memData_fcn = griddedInterpolant(simTime,simData(rr,:),'spline');
        memDataRef_fcn = griddedInterpolant(simTime,refData(rr,:),'spline');
        
        memData(rr,:) = memData_fcn(tempTime);
        memDataRef(rr,:) = memDataRef_fcn(tempTime);
    end
    
    % Redefinition of the extracted data as the sampled data
    simTime = tempTime;
    simData = memData;
    refData = memDataRef;
    
    % Normalization of the data in respect the sensr maximum response
    for sensSel = 1:sensCount
        simData(sensSel,:) = simData(sensSel,:)./max(abs(simData(sensSel,:)));
        refData(sensSel,:) = refData(sensSel,:)./max(abs(refData(sensSel,:)));
    end
    
    % Find the minimum value for the maximum displacement among the sensors
    [maxResp,maxIdx] = max(abs(refData),[],2);
    [~,minMaxIdx] = min(maxResp);
    
    % Save the reference sensor and reference time on that sensor 
    refSensor = minMaxIdx;
    refTimeIdx = maxIdx(minMaxIdx);
    
    % Show the data if requested
    if showPlots
        plot(handlerAx_1,simTime,refData');
        plot(handlerAx_1,simTime(refTimeIdx),refData(refSensor,refTimeIdx),'bO')
    end
    
    % This loop is extracting characteristic data from the sampled
    % signals
    for k = 1:sensCount
        
        % If the k-th sensor is the reference sensor, do not compute things
        % again. Use the reference one.
        if k == refSensor
            charVal(k,j) = refData(k,refTimeIdx);
            charTime(k,j) = simTime(refTimeIdx);
            sensPosX(k,j) = filesColl(j).myCollector.mesh.x(k,1);
            sensPosY(k,j) = filesColl(j).myCollector.mesh.y(k,1);
            sensDist(k,j) = norm([sensPosX(k,j);sensPosY(k,j)]);
            continue
        end
        
        % Find the charactertistic data for the time response of the k-th
        % sensor
        charTimeIdx = find(abs(simData(k,:))>=abs(refData(refSensor,refTimeIdx)),1);
        charVal(k,j) = simData(k,charTimeIdx);
        charTime(k,j) = simTime(charTimeIdx);
        
        % Show the char time if requested
        if showPlots
            plot(charTime(k,j),charVal(k,j),'r.')
        end
        
        % Extract the position of the sensor
        sensPosX(k,j) = filesColl(j).myCollector.mesh.x(k,1);
        sensPosY(k,j) = filesColl(j).myCollector.mesh.y(k,1);
        
        sensDist(k,j) = norm([sensPosX(k,j);sensPosY(k,j)]);
        
    end
    
    % Pause the execution if the plots are requested
    if j ~= collDim && showPlots
        pause()
        cla
    end
    
    % Extract the pressure of the impact
    impP(j) = filesColl(j).myCollector.Parameters.P;

    % Extract the impact location
    impPosX(j) = filesColl(j).myCollector.Parameters.impact(1);
    impPosY(j) = filesColl(j).myCollector.Parameters.impact(2);
    
end

fprintf('- - -\nData extraction completed :) \n\n')

% Show Impact Location
figure()
hold on
for j = 1:collDim
    plot(impPosX(j),impPosY(j),'r.','MarkerSize',30*impP(j)./max(impP))
    plot(sensPosX(:,j),sensPosY(:,j),'gO','MarkerFaceColor',[0.4660 0.6740 0.1880])
end

%% Definition of input and output vector for the training sessions

% Build the NN Output Vector
outputY = [impPosX;impPosY];

% Build the NN Input Vector

% Neural Input Vector Builder #1
%[...,sPosX_i,sPosY_i,charTime_i,charVal_i,...]'
inputX = zeros(4*sensCount,collDim);
inputX(1:4:4*sensCount,:) = sensPosX;
inputX(2:4:4*sensCount,:) = sensPosY;
inputX(3:4:4*sensCount,:) = charTime;
inputX(4:4:4*sensCount,:) = charVal;

% Neural Input Vector Builder #2
% [...,sPosX_i,sPosY_i,charTime_i,...]'
% inputX = zeros(3*sensCount,collDim);
% inputX(1:3:3*sensCount,:) = sensPosX;
% inputX(2:3:3*sensCount,:) = sensPosY;
% inputX(3:3:3*sensCount,:) = charTime;
% 
% Neural Input Vector Builder #3
% [...,charTime_i,charVal_i,...]'
% inputX = zeros(2*sensCount,collDim);
% inputX(1:2:2*sensCount,:) = sensDist;
% inputX(2:2:2*sensCount,:) = charTime;
% % 
% Neural Input Vector Builder #4
% [...,charTime_i,...]'
% inputX = charTime;

%%
% Pre-processing info
preProcInfo.origin = filename1;
preProcInfo.sensIDs = sensSelIdx';
preProcInfo.sensCount = sensCount;
preProcInfo.sFreq = sFreq;
    
% Save the results
tempStr = split(filename1,'.');
tmepStr = [filepath1,tempStr{1},'_preProcessed_NNpos.',tempStr{2}];
save(tmepStr,'preProcInfo','inputX','outputY');
fprintf('The pre-processed data has been saved in %s \n\n',tmepStr);