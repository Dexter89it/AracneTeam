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
% Date:         25/09/2019
% Revision:     4
% ---------------------------- ChangeLog ----------------------------------
% 23/08/2019 - First Version
% 24/09/2019 - Dataset of training and testing are now loaded with a GUI
%              and the trained NN is tested with non-training data.
% 25/09/2019 - Added the possibility to perform a training session or just
%              a testing session, added the possibility to save the best NN
%              found during the trainins session.
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

clear filepath1 filename1

%%
% What to do
taskSel = questdlg('What do you want to do?', ...
                    'NN for impacting force prediction',...
                    'Train a net', ...
                    'Test a net',...
                    'Train a net');


switch taskSel
    case 'Train a net'
        
        % Choose a file for training session
        [filename1,filepath1] = uigetfile({'*_preProcessed_NNpos.mat'},'NN for position -- Pre-processed data selection for TRAINING','MultiSelect','off');
        % Load the chisen file
        trainData = load([filepath1,filename1]);
        
        fprintf('You have loaded %d training data.\n',size(trainData.inputX,2));

        % Choose a file for testing session
        [filename1,filepath1] = uigetfile({'*_preProcessed_NNpos.mat'},'NN for position -- Pre-processed data selection for TEST','MultiSelect','off');
        % Load the chisen file
        testData = load([filepath1,filename1]);
        
        fprintf('You have loaded %d testing data.\n',size(testData.inputX,2));
        
        clear filepath1 filename1
              
        % Number of NN to train
        nnCount = 10;

        % Number of training session per each NN
        keepTraining = 1;

        % Validation percentage (referred to the training data)
        trPerc = 0.85;

        % Test percentage (referred to the training data)
        valPerc = 0.10;

        % Maximum fails
        maxFails = 50;

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
        % % Polak-Ribi�re Conjugate Gradient
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
        
        % == DO NOT TOUCH BELOW THIS PLEASE ==

        % Preallocation
        netColl = {};
        errorColl = {};
        shootTime = zeros(1,nnCount);
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

            % Compute the maximum committed error over the test dataset
            pMerit = max(abs(mean(net(testData.inputX) - testData.outputY,2)));
            
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

        fprintf('The best is NN %d\n',best.idk)

        % Save the bestNet
        best.trainedFor = 'position';
        uisave('best','positionBestNET_.mat')
        
    case 'Test a net'

        % Choose a file for testing session
        [filename1,filepath1] = uigetfile({'*_preProcessed_NNpos.mat'},'NN for position -- Pre-processed data selection','MultiSelect','off');
        % Load the chisen file
        testData = load([filepath1,filename1]);
        
        fprintf('You have loaded %d testing data.\n',size(testData.inputX,2));
        
        % Choose a file for training session
        [filename1,filepath1] = uigetfile({'*.mat'},'NN for position -- Pre-trained net selection','MultiSelect','off');
        % Load the chisen file
        load([filepath1,filename1]);
        
        % Check if the loaded file is the correct one
        try
            best.trainedFor;
        catch
            error('Load a trained net file please ;)')
        end
        
        if ~strcmp(best.trainedFor,'position')
            error('You have loaded a NN trained for %s prediction :o',best.trainedFor)
        end
        
        clear filepath1 filename1
        
    otherwise
        
            error('Select something ;)')
        
end


% Apply the NN to the test data
predictedY = best.net(testData.inputX);

% Test session of the best NN
figure()
% Compute the regression
plotregression(testData.outputY,predictedY,['Regression for best NN  with ID ',num2str(best.idk)])

% Error computation
temp = (predictedY - testData.outputY);
figure()
subplot(1,2,1)
histogram(temp(1,:),100);
title('X Error')
subplot(1,2,2)
histogram(temp(2,:),100);
title('Y Error')


figure()
hold on
plot(testData.outputY(1,:),testData.outputY(2,:),'bO','DisplayName','Data')
plot(predictedY(1,:),predictedY(2,:),'rx','DisplayName','Prediction')
legend
title('Position Prediction')