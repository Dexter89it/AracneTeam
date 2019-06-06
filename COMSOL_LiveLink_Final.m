
% This script loads a COMSOL model through LiveLink server, it sets some
% parameter and runs the simulation.
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Ventre Francesco
% Team: ARACNE
% Date: 05/06/2019
% Revision: 3
%
% ChangeLog
% 31/05/2019 - First Version
% 05/06/2019 - Parameters can now be set and the results extracted to use
%              them in matlab.
%            - Iterative method implemented. It generates a number of
%              simulation that can be set through the parameter N.
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

% Load Library
%addpath(genpath('myFunctions'))

%% Figure Preallocation
figure()
handler_ax(1) = axes;
title('Displacement at specified location')
xlabel('$time \; [s]$')
ylabel('$Vertical \; Displacement \; [m]$')
hold on

figure()
handler_ax(2) = axes;
title('Velocity at specified location')
xlabel('$time \; [s]$')
ylabel('$Vertical \; Velocity \; [m/s]$')
hold on

figure()
handler_ax(3) = axes;
title('Acceleration at specified location')
xlabel('$time \; [s]$')
ylabel('$Vertical \; Acceleration \; [m/s^2]$')
hold on

%% COMSOL LiveLink
% Import the model
mphopen('Z:\Users\Dexter\Documents\Comsol Projects\ARACNE\SSSS_Plate_ver1.mph')

% Set the dimension of the dataset to be produced
title = 'Dataset Generator';
dims = [1 45];
prompt = {'Enter the dimension of the dataset (Integer):',...
          'Enter the magnitude interval [N]:',...
          'Enter the impact location limits on x [m]:',...
          'Enter the impact location limits on y [m]:'};
definput = {'20','[500,5000]','[0.01,0.49]','[0.01,0.49]'};
userAnswer = inputdlg(prompt,title,dims,definput);

% End the script if no choice is made
if isempty(userAnswer)
    close all
    clc
    return
end

% Answer Map
setDim = str2double(userAnswer{1});
fLimits = str2num(userAnswer{2});
posLimits.x = str2num(userAnswer{3});
posLimits.y = str2num(userAnswer{4});

myInfo.setDim = setDim;
myInfo.fLimits = fLimits;
myInfo.posLimits = posLimits;

% Preallocation
myCollector = struct();

tStart = tic;

for k = 1 : setDim

    % Generate a random load within the given internval
    fVal = fLimits(1) + (fLimits(2)-fLimits(1)).*rand();

    % Generate a random position within the given intervals
    posVal = [posLimits.x(1);posLimits.y(1)] + ...
             [posLimits.x(2)-posLimits.x(1),0;...
              0,posLimits.y(2)-posLimits.y(1)]*rand(2,1);

    % Update the model with the current parameters
    % Peak of the force
    model.param.set('L_peak',[num2str(fVal),'[N]']);
    % Location of the applied force
    model.param.set('impact_x',[num2str(posVal(1)),'[m]']);
    model.param.set('impact_y',[num2str(posVal(2)),'[m]']);
    
    % Save the parameters
    myCollector(k).id = now;
    myCollector(k).Parameters.L_peak.value = fVal;
    myCollector(k).Parameters.L_peak.unit = '[N]';
    myCollector(k).Parameters.impact.value = posVal;
    myCollector(k).Parameters.impact.unit = '[m]';

    % Run the model
    % Note: If the model has been already solved in COMSOL, a solution is
    % present in the .mph file and the re-run is not necessary (unless
    % parameters are changed ;) )
    
    fprintf('Simulation has started\n');
    tic
    model.study('std1').run
    myCollector(k).runTime = toc;
    fprintf('Simulation has ended in %.1f s \n',myCollector(k).runTime);

    % Data Extraction
    % Time series for each node (node_id,value)
    myCollector(k).timeEval = mphevalpoint(model,'t');
    % Acceleration of each node (node_id,value)
    myCollector(k).nodalAcc = mphevalpoint(model,'shell.u_ttZ');
    % Velocity of each node (node_id,value) 
    myCollector(k).nodalVel = mphevalpoint(model,'shell.u_tZ');
    % Displacement of each node (node_id,value)
    myCollector(k).nodalDisp = mphevalpoint(model,'shell.umz');
    
    fprintf('Simulation %d of %d completed.\n\n',k,setDim);
end

myInfo.totalRunTime = toc(tStart);

save(['setOf',num2str(setDim),'_',num2str(now),'.mat'],'myCollector','myInfo');

% 
% % Some plots
% %figure ('name',name)
% plot(handler_ax(1),timeEval',nodalDisp')
% %figure ('name',name,'2')
% plot(handler_ax(2),timeEval',nodalVel')
% %figure ('name',name,'2')
% plot(handler_ax(3),timeEval',nodalAcc')

