clear
close all
clc

%All the figure are docked in one window
set(0,'DefaultTextInterpreter','latex');
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultTextFontSize',12);
set(0,'DefaultAxesFontSize',12);

%%
% Generate the impact data
[dt,P,d,up2,v,G] = impact_generator('./total_flux.txt',100);

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