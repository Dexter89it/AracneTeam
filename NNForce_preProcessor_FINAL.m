%
% NN Data pre-processor for the force prediction VER2
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Francesco Ventre, Aloisia Russo, Bella Salvatore
%         Andrea
% Team: ARACNE
% Date: 15/09/2019
% Revision: 2
%
% ChangeLog
% 23/08/2019 - First Version
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

%% Time of maximum response and maximum response magnitude of Acceleration

% Select the sensor ID to consider
sensSelIdx = 1:16;

% Total numbero of selected sensor
sensCount  = length(sensSelIdx);

if sensCount>size(filesColl(1).myCollector.data.acc.z,1)
   error('Maximum number of sensor is %d',size(filesColl(1).myCollector.data.acc.z,1)); 
end

% Preallocation
sensEnergy = zeros(sensCount,collDim);
sensDist = zeros(sensCount,collDim);

forceL = zeros(1,collDim);

% Iterate over the simulations

for j = 1:collDim
    
    fprintf('Data extraction from simulation %d of %d\n',j,collDim);

    % Iterate for each sensor
    
    for k = 1:sensCount
    
    % selected data for the data set
        simTime = filesColl(j).myCollector.timeEval;
        refData = filesColl(j).myCollector.data.acc.z(k,:);
        
        sensPosX = filesColl(j).myCollector.mesh.x(k,1);
        sensPosY = filesColl(j).myCollector.mesh.y(k,1);
        
        sensDist(k,j) = norm([sensPosX;sensPosY]-filesColl(j).myCollector.Parameters.impact.value);

        N = 2^16;
        fs = 1/(simTime(2));     
        
        fftRes = fftshift(fft(refData',N));
        ampl = abs(fftRes)/fs;
        sensEnergy(k,j) = sum(ampl.^2)*fs/N;

    end
    
    % Extract the impct magnitude
    forceL(j) = filesColl(j).myCollector.Parameters.L_peak.value;
    
end

fprintf('- - -\nData extraction completed :) \n\n')

% Build the NN Output Vector
outputY = forceL;

% Build the NN Input Vector
% Neural Input Vector Builder
% [...,sensEnergy_i,sensDist_i,...]'
inputX = zeros(2*sensCount,collDim);
inputX(1:2:2*sensCount,:) = sensEnergy;
inputX(2:2:2*sensCount,:) = sensDist;