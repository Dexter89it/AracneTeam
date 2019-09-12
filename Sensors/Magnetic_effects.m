clear; clc; close all
% %% Attenuation coefficient
% % Properties
% mi = [1.25665 1.2566368]*1e-6;  % H/m                                       Permeability of Al and Cu
L = 5e-2;   % m                                                             Side length of the sensor's stack
A = L*L;    % m^2                                                           Cross-section of the sensor's stack

s = linspace(1e-3, 5e-3,100);   % m                                         Different layer thicknesses

    %% Eddy currents
% Properties
c = [921.096 376.812];  % J/(Kg K)                                          Specific heat coefficient
rho = [2700 8960];      % Kg/m^3                                            Density
V = A*s;                % m^3                                               Volume

C_Al = c(1)*V*rho(1);   % J/K                                               Heat Capacity
C_Cu = c(2)*V*rho(2);

%https://www.princeton.edu/ssp/joseph-henry-project/eddy-currents/eddy_wiki.pdf
%https://www.nature.com/articles/s41586-018-0468-5.epdf?shared_access_token=nham_zIa5Juzn7DE2V_xo9RgN0jAjWel9jnR3ZoTv0M8eWEsVdzdgZle6vNO2ytZ0xbYhuV2Q1s0KdSWyHSk2OEoxf0IHJhmfl63cmgf3voJ0vDeZLx60f3nWswEOCQZ2zR9zMqmMOJjtlWmFVmi6e_qDt5w9-1PfD84uojizVs%3D
dB = 4e-3; % T/s                                                           Magneitc Field variation (strong assumption, have to check)
res_Al = 2.65e-8; %ohm*m
res_Cu = 1.68e-8; %ohm*m

P_Al = (pi*dB*s).^2/(6*res_Al*rho(1)); %W/Kg
P_Cu = (pi*dB*s).^2/(6*res_Cu*rho(2)); %W/Kg

P_Al = P_Al*rho(1).*V; %W
P_Cu = P_Cu*rho(2).*V; %W

dT_Al = P_Al./C_Al;               %K/s                                        Temperature variation in time
dT_Cu = P_Cu./C_Cu;

figure(1);
sgtitle('Temperature gradient VS Layer Thickness')

ax = subplot(1,2,1);
plot(s,dT_Al)
title('Aluminum')
xlabel('s [m]')
ylabel('dT [K/s]')
grid on
ax.YAxis.TickLabelFormat = '%.2f';
ax.XAxis.TickLabelFormat = '%.2f';

ax = subplot(1,2,2);
plot(s,dT_Cu)
title('Copper')
xlabel('s [m]')
ylabel('dT [K/s]')
grid on
ax.YAxis.TickLabelFormat = '%.2f';
ax.XAxis.TickLabelFormat = '%.2f';

%% Ionization Energy
m_Al = V*rho(1);    %Kg                                                     Mass
M_Al = 26.98e-3;    %Kg/mol                                                 Molar mass
m_Cu = V*rho(2);
M_Cu = 63.55e-3;

mol_Al = m_Al/M_Al; %mol                                                    Moles
mol_Cu = m_Cu/M_Cu;
iE1_Al = 577.5e3*mol_Al; %J                                                 1st ionization energy
iE1_Cu = 745.5e3*mol_Cu;

s2y = @(t) t/60/60/24/365;                                                  %Seconds to years
req_t_Al = s2y(iE1_Al./P_Al);                                               %time required to reach 1st ionization energy with the contribution of the eddy currents only
req_t_Cu = s2y(iE1_Cu./P_Cu);

figure(2);

sgtitle('Required time to reach 1st ionization energy')

ax = subplot(1,2,1);
plot(s, req_t_Al)
title('Aluminum')
xlabel('s [m]')
ylabel('t [years]')
grid on
% ax.YAxis.TickLabelFormat = '%.2f';
ax.XAxis.TickLabelFormat = '%.2f';

ax = subplot(1,2,2);
plot(s, req_t_Cu)
title('Copper')
xlabel('s [m]')
ylabel('t [years]')
grid on
% ax.YAxis.TickLabelFormat = '%.2f';
ax.XAxis.TickLabelFormat = '%.2f';
