clc
clear
close all

%%
th = 0.5; %[cm]
K1 = 0.54; %[?]
V_r = 28; %[km/s]
rho = 2.7; %[g/cm^3]

% Mass to penetrate a plate of Al
%(Source: https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19920014066.pdf)
m = (th/( K1*rho^(1/6)*V_r^0.287 ))^(1/0.352);

% Penetrating Energy
Ek = (0.5*(m/1000)*(V_r*1000)^2); %[J]

t = 0.0009; %[s]

P_impact = Ek/t; %[W = J/s]

F_impact = P_impact/(V_r*1000); %[N]
F_impact_margined.max = 1.5*F_impact;

%%
th = 0.1*(0.5); %[cm]
K1 = 0.54; %[?]
V_r = 28; %[km/s]
rho = 2.7; %[g/cm^3]

% Mass to penetrate a plate of Al
%(Source: https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19920014066.pdf)
m = (th/( K1*rho^(1/6)*V_r^0.287 ))^(1/0.352);

% Penetrating Energy
Ek = (0.5*(m/1000)*(V_r*1000)^2); %[J]

t = 0.0009; %[s]

P_impact = Ek/t; %[W = J/s]

F_impact = P_impact/(V_r*1000); %[N]
F_impact_margined.min = F_impact;

%%
F_impact_margined