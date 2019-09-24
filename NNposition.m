% -------------------------------------------------------------------------
% NN for position
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Authors:      Cirelli Renato, Ventre Francesco, Salvatore Bella,
%               Alvaro Romero Calvo, Aloisia Russo.
% Team:         ARACNE
% Date:         24/09/2019
% Revision:     3
% ---------------------------- ChangeLog ----------------------------------
% 23/08/2019 - First Version
% 24/09/2019 - Dataset of training and testing are now loaded with a GUI
%              and the trained NN is tested with non-training data.
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

%% Load the pre-preocessed data

% Choose a file for training session
[filename1,filepath1] = uigetfile({'*.mat'},'Pre-processed data selection for TRAINING','MultiSelect','off');
% Load the chisen file
trainData = load([filepath1,filename1]);

% Choose a file for testing session
[filename1,filepath1] = uigetfile({'*.mat'},'Pre-processed data selection for TEST','MultiSelect','off');
% Load the chisen file
testData = load([filepath1,filename1]);

clear filepath1 filename1

%% Parameters & Options

% Number of NN to train
nnCount = 20;

% Number of training session per each NN
keepTraining = 1;

% Validation percentage (referred to the training data)
trPerc = 0.85;

% Test percentage (referred to the training data)
valPerc = 0.1;

% Maximum fails
maxFails = 200;

% Maximum Epochs
maxEpochs = 500;

% Parameter of merit for the selection of the best NN
pMeritMem = 1000;

%Set the training function
% Levenberg-Marquardt
trainFcn = 'trainlm';
% % BFGS Quasi-Newton
%trainFcn = 'trainbfg';
% % Resilient Backpropagation
%trainFcn = 'trainrp';
% % Scaled Conjugate Gradient
%trainFcn = 'trainscg';
% % Conjugate Gradient with Powell/Beale Restarts
%trainFcn = 'traincgb';
% % Fletcher-Powell Conjugate Gradient
%trainFcn = 'traincgf';
% % Polak-Ribiére Conjugate Gradient
%trainFcn = 'traincgp';
% % One Step Secant
%trainFcn = 'trainoss';
% Variable Learning Rate Backpropagation
%trainFcn = 'traingdx';

% Set the performance function
% % Mean absolute error 
%performFcn = 'mae';
% % Mean squared error
performFcn = 'mse';
% % Sum absolute error
%performFcn = 'sae';
% Sum squared error
%performFcn = 'sse';
% % Cross-entropy
%performFcn = 'crossentropy';
% % Mean squared
%performFcn = 'msesparse';

%% DO NOT TOUCH THIS SECTION PLEASE

% Preallocation
netColl = {};
errorColl = {};
shootTime = zeros(1,nnCount);

%loopCont
loopCount = 0;


for k = 1:nnCount
    
    tic
    
    % Neural network definition
    net = feedforwardnet([25],trainFcn); % [best with 25 neurons in ne layer]
    %net = cascadeforwardnet([25 10 3],trainFcn);

    % Training, validation and test percentage of the total training set
    net.divideParam.trainRatio = trPerc;
    net.divideParam.valRatio = valPerc; 
    net.divideParam.testRatio  = 1-trPerc-valPerc;
    
    % Maximum training fail limit
    net.trainParam.max_fail = maxFails;
    net.trainParam.epochs = maxEpochs;
    net.performFcn = performFcn;
    
    fprintf('NN : %d\n',k);
    
    % Preallocation
    netCollInt = {};
    
    for j = 1:keepTraining
        
        % Training th NN
        fprintf('-- %d\n',j);
        [net,tr,y,e] = train(net,trainData.inputX,trainData.outputY);
        
        loopCount = loopCount + 1;
        fprintf('Mean squared normalized error : %e \n',mse(e));
    end
    
    % Collect the resulting NN
    netColl{k} = net;
    errorColl{k} = e;
    
    % Check if the NN is the best one according to a pre-defined criterira
    pMerit = abs(max(max(e)));
    if pMeritMem > pMerit
        
        % Update the parameter of merit
        pMeritMem = pMerit;
        
        % Best Network 
        best.idk = k;
        best.net = net;
        best.pMerit = pMerit;
        best.e = e;
    end
    
    % Memorize the run time
    shootTime(k) = toc;
    
    % Time left
    timeLeft = mean(shootTime(shootTime>0))*(nnCount - k);
    fprintf('Time left: %.1f [s] | %.1f [m] | %.1f [h]\n\n',timeLeft,timeLeft/60,timeLeft/3600);
    
end

% Test session of the best NN
figure()
cla

% Apply the NN to the test data
predictedY = best.net(testData.inputX);
% Compute the regression
plotregression(testData.outputY,predictedY,['Regression for best NN  with ID ',num2str(best.idk)])


figure()
cla

% Error computation
temp = (predictedY - testData.outputY); 
subplot(1,2,1)
histogram(temp(1,:),100);
title('X Error')
subplot(1,2,2)
histogram(temp(2,:),100);
title('Y Error')

figure()
hold on
cla

plot(testData.outputY(1,:),testData.outputY(2,:),'bO','DisplayName','Data')
plot(predictedY(1,:),predictedY(2,:),'rx','DisplayName','Prediction')
legend
title('Position Prediction')

fprintf('The best is NN %d\n',best.idk)