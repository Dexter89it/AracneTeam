% Third Test of the nerual network
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato
% Team: ARACNE
% Date: 18/08/2019
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
timeCount = size(filesColl(1).myCollector.data.acc.z,2);
sensCount = size(filesColl(1).myCollector.data.acc.z,1);

clear filepath1 filename1

%% Creation of the input data
Xinput = {};
Youtput = zeros(collDim,2);
for k = 1:collDim
    Xinput{k,1} = filesColl(k).myCollector.data.acc.z;
    Youtput(k,:) = filesColl(k).myCollector.Parameters.impact.value';
end

mu = mean([Xinput{:}],2);
sig = std([Xinput{:}],0,2);

for i = 1:numel(Xinput)
    Xinput{i} = (Xinput{i} - mu) ./ sig;
end

%% LSTM Set-Up

numHiddenUnits = 100;

layers = [ ...
    sequenceInputLayer(sensCount)
    lstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(50)
    dropoutLayer(0.5)
    fullyConnectedLayer(2)
    regressionLayer];

maxEpochs = 100;
miniBatchSize = 15;

options = trainingOptions('sgdm', ...
                          'InitialLearnRate',0.001, ...
                          'ExecutionEnvironment','cpu', ...
                          'MaxEpochs',maxEpochs, ...
                          'MiniBatchSize',miniBatchSize, ...
                          'GradientThreshold',1, ...
                          'Verbose',true, ...
                          'Plots','training-progress');

net = trainNetwork(Xinput,Youtput,layers,options);

YPred = predict(net,Xinput);
rmse = sqrt(mean((Youtput - YPred).^2))