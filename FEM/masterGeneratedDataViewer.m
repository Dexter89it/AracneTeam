clear
close all
clc

%All the figure are docked in one window
set(0,'DefaultTextInterpreter','latex');
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultTextFontSize',12);
set(0,'DefaultAxesFontSize',12);

addpath(genpath('MASTER'));

%%
% Generate the impact data
xout = impact_generator('MASTER/total_flux.txt',100,AL_data((273.15+20).*ones(100,1)));

dt = xout(:,1);
P = xout(:,2);
d = xout(:,3);
up2 = xout(:,4);
v = xout(:,5);
crosspen = xout(:,6);
G = xout(:,7);

figure(1);
subplot(5,1,1)
plot(dt);
xlabel('$Sample \; number$');
ylabel('$dt \; [s]$');
title('$Impact \; Time$')

subplot(5,1,2)
plot(P);
xlabel('$Sample number$');
ylabel('$P \; [Pa]$');
title('$Impact \; Pressure$');

subplot(5,1,3)
plot(d);
xlabel('$Sample \; number$');
ylabel('$d \; [m]$');

subplot(5,1,4)
plot(v);
xlabel('$Sample \; number$');
ylabel('$v \; [m/s]$');
title('$Incident \; Impact \; Velocity$');

subplot(5,1,5)
plot(G);
xlabel('$Sample \; number$');
ylabel('$ID$');
title('$Material \; Group$');