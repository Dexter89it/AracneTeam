
% This script loads a COMSOL model through LiveLink server, it sets some
% parameter and runs the simulation.
% 
% NOTE
% The model is created in COMSOL GUI and importated here as it is. This
% reduced the ammount of code needed to properly set-up and run a model.
% -------------------------------------------------------------------------
% Author: Cirelli Renato, Francesco Ventre
% Team: ARACNE
% Date: 05/06/2019
% Revision: 3
%
% ChangeLog
% 31/05/2019 - First Version
% 05/06/2019 - Parameters can now be set and the results extracted to use
%              them in matlab.
% 05/06/2019 - Iterative method implemented. It generates a number of
% simulation that can be set through the parameter N.
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
mphopen('SSSS_Plate_ver1')

mphgetexpressions(model.param)
%%

N = input('insert the desired number of simulations: ');

for i = 1 : N
%Set the new parameters

%generate a random load (500 to 5000 N)
r = 500 + (5000-500).*rand;
r = num2str(r);
F = strcat(r,'[N]');

%generate random location
x0 = rand;
x0 = num2str(x0);
x0 = strcat(x0,'[m]');

y0 = rand;
y0 = num2str(y0);
y0 = strcat(y0,'[m]');

% Peak of the force
model.param.set('L_peak', F)
% Location of the applied force
model.param.set('impact_x', x0)
model.param.set('impact_y',y0)

%give in output the modified data for a check
mphgetexpressions(model.param)


%% Run the model
% Note: If the model has been already solved in COMSOL, a solution is
% present in the .mph file and the re-run is not necessary (unless
% parameters are changed ;) )

num = i;
num = num2str(i);
name = strcat('sym',num); %nome del file salvato
%std = strcat('std',num); %numero dello studio nel medesimo file

% tic
model.study('std1').run
% toc

%%Save the model
mphsave(model,name)


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
%figure ('name',name)
plot(handler_ax(1),timeEval',nodalDisp')
%figure ('name',name,'2')
plot(handler_ax(2),timeEval',nodalVel')
%figure ('name',name,'2')
plot(handler_ax(3),timeEval',nodalAcc')

end
