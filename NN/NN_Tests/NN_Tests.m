% First Test of the nerual network
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Ventre Francesco
% Team: ARACNE
% Date: 16/08/2019
% Revision: 1
%
% ChangeLog
% 16/08/2019 - First Version
%
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
[filename1,filepath1] = uigetfile({'*.mat'},'Select Data File','MultiSelect','off');
% Load the chisen file
load([filepath1,filename1]);

% Loaded archive size
collDim = length(filesColl);

clear filepath1 filename1

%% Time of maximum response and maximum response magnitude of Acceleration

sensCount  = size(filesColl(1).myCollector.data.acc.z,1);

maxTime = zeros(sensCount,collDim);
maxVal = zeros(sensCount,collDim);
maxIndex = zeros(sensCount,collDim);

forceL = zeros(1,collDim);
forcePosX = zeros(1,collDim);
forcePosY = zeros(1,collDim);

sensPosX = zeros(sensCount,collDim);
sensPosY = zeros(sensCount,collDim);

% Find the maximum response location for each simulation
for j = 1:collDim
   
    % Iterate for each sensor in a simulation
    for k = 1:sensCount
    
        
        % Find the maximum value
        [maxVal(k,j),maxIndex(k,j)] = max(filesColl(j).myCollector.data.acc.z(k,:));

        % Extract the time
        maxTime(k,j) = filesColl(j).myCollector.timeEval(maxIndex(j));
        
        sensPosX(k,j) = filesColl(j).myCollector.mesh.x(k,1);
        sensPosY(k,j) = filesColl(j).myCollector.mesh.y(k,1);
        
        
    end

    % Extract the impct magnitude
    forceL(j) = filesColl(j).myCollector.Parameters.L_peak.value;

    % Extract the impact location
    forcePosX(j) = filesColl(j).myCollector.Parameters.impact.value(1);
    forcePosY(j) = filesColl(j).myCollector.Parameters.impact.value(2);
    
end

% Show Impact Location
figure()
hold on
for j = 1:collDim
    plot(forcePosX(j),forcePosY(j),'r.','MarkerSize',30*forceL(j)./max(forceL))
end

% Build the input layers
% inputX = [maxTime;maxVal];
outputY = [forcePosX;forcePosY];

inputX = zeros(4*sensCount,collDim);

inputX(1:4:4*sensCount,:) = sensPosX;
inputX(2:4:4*sensCount,:) = sensPosY;
inputX(3:4:4*sensCount,:) = maxTime;
inputX(4:4:4*sensCount,:) = maxVal;



% %% create a neural
% net = feedforwardnet([10]);
% 
% % set early stopping
% net.divideParam.trainRatio = 0.70;
% % training set [%]
% net.divideParam.valRatio = 0.15; 
% % validation set [%]
% net.divideParam.testRatio  = 0.15;
% 
% % High for gradient descent learning alike and small for Newton's method
% %net.trainParam.mu = 5;
% 
% % Maximum training fail limit
% net.trainParam.max_fail = 15;
% 
% 
% % train a neural network
% [net,tr,y,e] = train(net,inputX,outputY);
% 
% % ploterrhist(e)
% % plotregression(outputY,y,'Regression')
% 
% 
% % show netview(net)
% %view(net)