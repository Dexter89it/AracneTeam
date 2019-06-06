
% This script loads a COMSOL model through LiveLink server, it sets some
% parameter and runs the simulation.
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Ventre Francesco
% Team: ARACNE
% Date: 06/06/2019
% Revision: 4
%
% ChangeLog
% 31/05/2019 - First Version
% 05/06/2019 - Parameters can now be set and the results extracted to use
%              them in matlab.
%            - Iterative method implemented. It generates a number of
%              simulation that can be set through the parameter N.
% 06/06/2019 - The parameters can be set using a GUI
%            - Default values added
%            - Timer for the overall database creation and for the single
%              model run
%            - The results and the simulation parameters are saved in a
%              .mat file 
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

% Load Library (here if needed)
%addpath(genpath('myFunctions'))

%% COMSOL LiveLink
% Load a model
[file,path] = uigetfile('*.mph');
if isequal(file,0)
   disp('Ok, bye.');
else
   selModel = fullfile(path,file);
   disp(['Selected model: ', selModel]);
   mphopen(selModel);
end

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

% Preallocation
myCollector = struct();

% Start a stopwatch timer for the all loop
tStart = tic;

% Loop untill all simulations are done
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
    
    % Save the parameters (id is unique and equal to the time of run)
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
    tStart_k = tic;
    model.study('std1').run
    myCollector(k).runTime = toc(tStart);
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

% Stop the loop timer
myInfo.totalRunTime = toc(tStart);

fprintf('Database has been created in %d seconds.\n',myInfo.totalRunTime);

% Save some info about the simulation
myInfo.setDim = setDim;
myInfo.fLimits = fLimits;
myInfo.posLimits = posLimits;

% Save a .mat file with a unique name
save(['setOf',num2str(setDim),'_',num2str(now),'.mat'],'myCollector','myInfo');