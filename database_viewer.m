% This script shows the collected data
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Ventre Francesco
% Team: ARACNE
% Date: 06/06/2019
% Revision: 1
%
% ChangeLog
% 31/05/2019 - First Version 
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
addpath(genpath('myFunctions'))


%% Load the database
% Load a database
[file,path] = uigetfile('*.mat');
if isequal(file,0)
   disp('Ok, bye.');
else
   selData= fullfile(path,file);
   load(selData,'-mat');
   disp(['Selected database: ', selData,'\n']);
   fprintf(['Database generated on: ',datestr(myInfo.creationTime),'\n']);
   fprintf(['Number of simulations: ',datestr(myInfo.setDim),'\n']);
end


%% Figure Setup
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

%% Some plots
for tt = 1:myInfo.setDim
    timeEval = myCollector(tt).timeEval;
    nodalDisp = myCollector(tt).nodalDisp;
    nodalVel = myCollector(tt).nodalVel;
    nodalAcc = myCollector(tt).nodalAcc;

    plot(handler_ax(1),timeEval',nodalDisp')
    plot(handler_ax(2),timeEval',nodalVel')
    plot(handler_ax(3),timeEval',nodalAcc')
    
    pause()
    claMore(handler_ax)
end
    