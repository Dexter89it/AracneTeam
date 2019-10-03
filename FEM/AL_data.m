function myOut = AL_data(T)
% -------------------------------------------------------------------------
% This script computes properties for AL7075-T6.
% -------------------------------------------------------------------------
% Authors:      Salvatore Andrea Bella, Francesco Ventre.
% Team:         ARACNE
% Date:         03/10/2019
% Revision:     1
% ---------------------------- ChangeLog ----------------------------------
%
% 03/10/2019 - First Version
% -------------------------------------------------------------------------
% LICENSED UNDER Creative Commons Attribution-ShareAlike 4.0 International
% License. You should have received a copy of the license along with this
% work. If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.
% -------------------------------------------------------------------------

%density
rho_20to700 = @(T) 2753.524 + 0.05647875*T.^1 - 0.001127433*T.^2 + ...
                   2.657999E-6*T.^3 - 3.148685E-9*T.^4 + 1.417919E-12*T.^5;
rho = rho_20to700(T);

%bulk modulus
kappa = @(T) 7.462627E10+1927169.0*T.^1 - 73167.5*T.^2 + 54.23875*T.^3;

%speed of sound
c = sqrt(kappa(T)./rho_20to700(T));

myOut = [c rho]';

end