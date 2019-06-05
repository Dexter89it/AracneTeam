%
% This script loads a COMSOL model through LiveLink server, it sets some
% parameter and runs the simulation.
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato
% Team: ARACNE
% Date: 05/06/2019
% Revision: 2
%
% ChangeLog
% 31/05/2019 - First Version
% 05/06/2019 - Parameters can now be set and the results extracted to use
%              them in matlab.
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

% Load Orbital Library
addpath(genpath('myFunctions'))

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
mphopen('Z:\Users\Dexter\Documents\Comsol Projects\ARACNE\Plate_test_4.mph')

% Show the model parameters (not really needed...)
%mphgetexpressions(model.param)

% Set the new parameters
% Peak of the force
model.param.set('L_peak','1000 [N]')
% Location of the applied force
model.param.set('impact_x','0.25 [m]')
model.param.set('impact_y','0.25 [m]')

%% Run the model
% Note: If the model has been already solved in COMSOL, a solution is
% present in the .mph file and the re-run is not necessary (unless
% parameters are changed ;) )

% tic
% model.study('std1').run
% toc

%% Data Extraction

% Time series for each node (node_id,value)
timeEval = mphevalpoint(model,'t');

% Acceleration of each node (node_id,value)
nodalAcc = mphevalpoint(model,'shell.u_ttZ');

% Velocity of each node (node_id,value) 
nodalVel = mphevalpoint(model,'shell.u_tZ');

% Displacement of each node (node_id,value)
nodalDisp = mphevalpoint(model,'shell.umz');

% Some plots
plot(handler_ax(1),timeEval',nodalDisp')
plot(handler_ax(2),timeEval',nodalVel')
plot(handler_ax(3),timeEval',nodalAcc')