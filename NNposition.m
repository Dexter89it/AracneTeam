%
% FNN for position estimation #1
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Francesco Ventre, Bella Salvatore Andrea
% Team: ARACNE
% Date: 15/09/2019
% Revision: 2
%
% ChangeLog
% 23/08/2019 - First Version
% 15/09/2019 - Removed possible options and left only the one chosen as
%              final version.
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------

clc

% Number of NN to train
nnCount = 3;
% Number of training session per each NN
keepTraining = 1;

% Preallocation
netColl = {};
errorColl = {};
shootTime = zeros(1,nnCount);

% Parameter of merit for the selection of the best neural net
pMeritMem = 1000;

% loopCont
loopCount = 0;

for k = 1:nnCount
    tic
    %Set the training function
    % Levenberg-Marquardt
     trainFcn = 'trainlm';
    
    % Neural network definition
    net = feedforwardnet(25,trainFcn);
    
    % Set the performance function
    % Sum squared error
     net.performFcn = 'sse';

    % Training, validation and test percentage of the total training set
    net.divideParam.trainRatio = 0.85;
    net.divideParam.valRatio = 0.10; 
    net.divideParam.testRatio  = 1-net.divideParam.trainRatio-net.divideParam.valRatio;
    
    % Maximum training fail limit
    net.trainParam.max_fail = 100;
    
    fprintf('NN : %d\n',k);
    netCollInt = {};
    
    for j = 1:keepTraining
        
        % Training th NN
        fprintf('-- %d\n',j);
        [net,tr,y,e] = train(net,inputX,outputY);
        
        loopCount = loopCount + 1;
        fprintf('Mean squared normalized error : %e \n',mse(e));
    end
    
    % Collect the resulting NN
    netColl{k} = net;
    errorColl{k} = e;
    
    % Check if the NN is the best one according to a criteria
    pMerit = abs(max(max(e)));
    if pMeritMem > pMerit
        
        pMeritMem = pMerit;
        
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

%%
figure()
cla
predictedY = best.net(inputX);
plotregression(outputY,predictedY,['Regression for best NN  with ID ',num2str(best.idk)])

figure()
cla
temp = (predictedY - outputY); 
subplot(1,2,1)
histogram(temp(1,:),100);
title('X Error')
subplot(1,2,2)
histogram(temp(2,:),100);
title('Y Error')

figure()
cla
hold on
plot(outputY(1,:),outputY(2,:),'bO','DisplayName','Data')
plot(predictedY(1,:),predictedY(2,:),'rx','DisplayName','Prediction')
legend
title('Position Prediction')

fprintf('The best is NN %d\n',best.idk)