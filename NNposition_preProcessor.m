%
% NN Data pre-processor for the position prediction
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato
% Team: ARACNE
% Date: 22/08/2019
% Revision: 2
%
% ChangeLog
% 16/08/2019 - First Version
% 22/08/2019 - Second Version
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
[filename1,filepath1] = uigetfile({'*.mat'},'Select Data File','MultiSelect','off');
% Load the chisen file
load([filepath1,filename1]);

% Loaded archive size
collDim = length(filesColl);

clear filepath1 filename1

%% Time of maximum response and maximum response magnitude of Acceleration

% Select the sensor ID to consider
sensSelIdx = 1:16;

% Show data extraction plot
showPlots = false;

% Total numbero of selected sensor
sensCount  = length(sensSelIdx);

if sensCount>size(filesColl(1).myCollector.data.acc.z,1)
   error('Maximum number of sensor is %d',size(filesColl(1).myCollector.data.acc.z,1)); 
end

% Preallocation
charTime = zeros(sensCount,collDim);
charVal = zeros(sensCount,collDim);
charIndex = zeros(sensCount,collDim);

forceL = zeros(1,collDim);
forcePosX = zeros(1,collDim);
forcePosY = zeros(1,collDim);

sensPosX = zeros(sensCount,collDim);
sensPosY = zeros(sensCount,collDim);

% Figure set-up
if showPlots
    figure(10)
    handlerAx_1 = axes;
    hold on
end

% Iterate over the simulations
for j = 1:collDim
    
    fprintf('Data extraction from simulation %d of %d\n',j,collDim);
    
    % selected data for the data set
    simTime = filesColl(j).myCollector.timeEval;
    refData = filesColl(j).myCollector.data.disp.z(sensSelIdx,:);
   
    % Find the minimum value for the displacement among the sensors
    [tempResp,tempIdx] = max(abs(refData),[],2);
    [~,tempRef] = min(tempResp);
    
    % Save the reference sensor and reference time on that sensor 
    refSensor = tempRef;
    refTimeIdx = tempIdx(tempRef);
    
    if showPlots
        plot(handlerAx_1,simTime,refData');
        plot(handlerAx_1,simTime(refTimeIdx),refData(refSensor,refTimeIdx),'bO')
    end
        
    % Iterate for each sensor
    for k = 1:sensCount
        
        % If the k-th sensor is the reference sensor, do not compute things
        % again. Use the reference one.
        if k == refSensor
            charVal(k,j) = refData(k,refTimeIdx);
            charTime(k,j) = refTimeIdx;
            sensPosX(k,j) = filesColl(j).myCollector.mesh.x(k,1);
            sensPosY(k,j) = filesColl(j).myCollector.mesh.y(k,1);
            continue
        end
        
        % Interpolate the data
        interpData = griddedInterpolant(simTime,refData(k,:));
        interpTime = linspace(simTime(1),simTime(end),10000);
        interpEval = interpData(interpTime);
        
        % Find the charactertistic data for the time response of the k-th
        % sensor
        charTimeIdx = find(abs(interpEval)>=abs(refData(refSensor,refTimeIdx)),1);
        charVal(k,j) = interpEval(charTimeIdx);
        charTime(k,j) = interpTime(charTimeIdx);
        
        if showPlots
            plot(charTime(k,j),charVal(k,j),'r.')
        end
        
        sensPosX(k,j) = filesColl(j).myCollector.mesh.x(k,1);
        sensPosY(k,j) = filesColl(j).myCollector.mesh.y(k,1);
        
    end
    
    if j ~= collDim && showPlots
        pause()
        cla
    end
    
    % Extract the impct magnitude
    forceL(j) = filesColl(j).myCollector.Parameters.L_peak.value;

    % Extract the impact location
    forcePosX(j) = filesColl(j).myCollector.Parameters.impact.value(1);
    forcePosY(j) = filesColl(j).myCollector.Parameters.impact.value(2);
    
end

fprintf('- - -\nData extraction completed :) \n\n')

% Show Impact Location
figure()
hold on
for j = 1:collDim
    plot(forcePosX(j),forcePosY(j),'r.','MarkerSize',30*forceL(j)./max(forceL))
    plot(sensPosX(:,j),sensPosY(:,j),'gO','MarkerFaceColor',[0.4660 0.6740 0.1880])
end

% Build the NN Output Vector
outputY = [forcePosX;forcePosY];

% Build the NN Input Vector
inputX = zeros(2*sensCount,collDim);

% Neural Input Vector Builder #1
% [...,sPosX_i,sPosY_i,charTime_i,charVal_i,...]'
inputX(1:4:4*sensCount,:) = sensPosX;
inputX(2:4:4*sensCount,:) = sensPosY;
inputX(3:4:4*sensCount,:) = charTime;
inputX(4:4:4*sensCount,:) = charVal;

% Neural Input Vector Builder #2
% [...,sPosX_i,sPosY_i,charTime_i,...]'
inputX(1:3:4*sensCount,:) = sensPosX;
inputX(2:3:4*sensCount,:) = sensPosY;
inputX(3:3:4*sensCount,:) = charTime;

% Neural Input Vector Builder #3
% [...,charTime_i,charVal_i,...]'
inputX(1:2:2*sensCount,:) = charTime;
inputX(2:2:2*sensCount,:) = charVal;

% Neural Input Vector Builder #4
% [...,charTime_i,...]'
inputX(1:2:2*sensCount,:) = charTime;
inputX(2:2:2*sensCount,:) = charVal;
