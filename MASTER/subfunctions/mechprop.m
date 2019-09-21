function [C1, S1, rho01] = mechprop(G)
% Gives the mechanical properties of the group G for the 6 groups
%
% 1. expl_fragm, coll fragm, LMRO, Ejecta (Launch and Mission Related Objects)-> Al 7075
% 2. NaK droplets -> rho = 866 kg/m3 --> liquid hydrogen
% 3. Slag, SRM dust -> Al2O3/Corundum
% 4. Paint -> rubber
% 5. MLI -> Al 1100
% 6. Meteoroids -> Iron
%
% Values from LASL SHOCK HUGONIOT DATA, 1980

% Assignment
switch G
    case 1 % Al 7075
        C1    = 5200;  % m/s (Al 7075)
        S1    = 1.36;
        rho01 = 2810;  % kg/m3
    case 2 % Liquid Hydrogen
        C1    = 2000;  % m/s 
        S1    = 1.28;
        rho01 = 72;  % kg/m3
    case 3 % Corundum (Al2O3)
        C1    = 8750;  % m/s 
        S1    = 0.98;
        rho01 = 3977;  % kg/m3
    case 4 % Rubber
        C1    = 1840;  % m/s 
        S1    = 1.44;
        rho01 = 1372;  % kg/m3
    case 5 % Al 1100
        C1    = 5380;  % m/s 
        S1    = 1.34;
        rho01 = 2712;  % kg/m3
    case 6 % Iron
        C1    = 4000;  % m/s 
        S1    = 1.59;
        rho01 = 7174;  % kg/m3
end

% For verification purposes
% C1    = 4920;  % m/s (Tungsten Carbide)
% S1    = 1.339; 
% rho01 = 15000; % kg/m3
%
% C1    = 3000;  % m/s (Nylon Hugoniot)
% S1   = 1.4;    
% rho01 = 1146;