%
% NN Data pre-processor for the position prediction
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Bella Salvatore Andrea
% Team: ARACNE
% Date: 15/09/2019
% Revision: 4
%
% ChangeLog
% 16/08/2019 - First Version
% 22/08/2019 - Second Version
% 23/08/2019 - Fixed the characteristic time value for the reference
%              sensor, corrected the outputX vector preallocations.
% 15/09/2019 - Defined final characteristic values to feed the ANN with,
%              removed plots to smoothen the code.
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------

clear
close all
clc

%% Load the compacted archive
% Choose a file
[filename1,filepath1] = uigetfile({'*.mat'},'Select Data For Trainin','MultiSelect','off');
% Load the chisen file
load([filepath1,filename1]);

% Loaded archive size
collDim = length(filesColl);

clear filepath1 filename1

%% Characteristic data estraction
% Select the sensor ID to consider
sensSelIdx = 1:16;

% Total number of selected sensor
sensCount  = length(sensSelIdx);

if sensCount>size(filesColl(1).myCollector.data.acc.z,1)
   error('Maximum number of sensor is %d',size(filesColl(1).myCollector.data.acc.z,1)); 
end

% Preallocation
charTime = zeros(sensCount,collDim);

forceL = zeros(1,collDim);
forcePosX = zeros(1,collDim);
forcePosY = zeros(1,collDim);

sensPos = zeros(sensCount,collDim);

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
        
    % Iterate for each sensor
    for k = 1:sensCount
        
        % If the k-th sensor is the reference sensor, do not compute things
        % again. Use the reference one.
        if k == refSensor
            charTime(k,j) = simTime(refTimeIdx);
            sensPosX = filesColl(j).myCollector.mesh.x(k,1);
            sensPosY = filesColl(j).myCollector.mesh.y(k,1);
            sensPos(k,j) = norm([sensPosX; sensPosY]);
            continue
        end
        
        % Interpolate the data
        interpData = griddedInterpolant(simTime,refData(k,:));
        interpTime = linspace(simTime(1),simTime(end),10000);
        interpEval = interpData(interpTime);
        
        % Find the charactertistic data for the time response of the k-th
        % sensor
        charTimeIdx = find(abs(interpEval)>=abs(refData(refSensor,refTimeIdx)),1);
        charTime(k,j) = interpTime(charTimeIdx);
        
        sensPosX = filesColl(j).myCollector.mesh.x(k,1);
        sensPosY = filesColl(j).myCollector.mesh.y(k,1);
        
        sensPos(k,j) = norm([sensPosX; sensPosY]);
    end
    
    % Extract the impct magnitude
    forceL(j) = filesColl(j).myCollector.Parameters.L_peak.value;

    % Extract the impact location
    forcePosX(j) = filesColl(j).myCollector.Parameters.impact.value(1);
    forcePosY(j) = filesColl(j).myCollector.Parameters.impact.value(2);
    
end

fprintf('- - -\nData extraction completed :) \n\n')

% Build the NN Output Vector
outputY = [forcePosX;forcePosY];

% Build the NN Input Vector
% Neural Input Vector Builder
% [...,sensPos_i,charTime_i,...]'
inputX = zeros(2*sensCount,collDim);
inputX(1:2:2*sensCount,:) = sensPos;
inputX(2:2:2*sensCount,:) = charTime;