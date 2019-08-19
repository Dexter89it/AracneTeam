% Second Test of the nerual network
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

nnCount = 5;
keepTraining = 15;

netColl = {};

figure()
hold on;
hh = 0;

for k = 1:nnCount
    
    net = feedforwardnet([10 10 5 3]);
    %net = cascadeforwardnet([10 10 5 3]);

    % set early stopping
    net.divideParam.trainRatio = 0.70;
    % training set [%]
    net.divideParam.valRatio = 0.15; 
    % validation set [%]
    net.divideParam.testRatio  = 0.15;

    % High for gradient descent learning alike and small for Newton's method
    %net.trainParam.mu = 5;
    
    % Maximum training fail limit
    net.trainParam.max_fail = 10;
    
    fprintf('NN : %d\n',k);
    netCollInt = {};
    for j = 1:keepTraining
        % train a neural network
        fprintf('-- %d\n',j);
        [net,tr,y,e] = train(net,inputX,outputY);
        
        netCollInt{j}.net = net;
        netCollInt{j}.tr = tr;
        netCollInt{j}.y = y;
        netCollInt{j}.e = e;
        
        hh = hh + 1;
        
        plot(hh,mse(e),'ro');
        fprintf('Mean squared normalized error : %e \n\n',mse(e));
    end
    
    netColl{k}= netCollInt;
end