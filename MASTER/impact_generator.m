function xout = impact_generator(file_path,N)
% Generates N time-force combinations based on the diameter-velocity flux
% of particles at the ISS orbit.
%
% VERSION:      2
% DATE:         23/09/2019
%
% OUTPUT:
% dt            impact time
% P             impact pressure (square wave)
% d             particle diameter
% up2           particle velocity in the material
% v             incident impact velocity
% crosspen      particle crosses the target (1) or not (0)
% G             material group
%
% INPUT: 
% file_path     path to the processed MASTER input file
% N             number of aleatory samples
%
% EXAMPLE:
%[dt,P,v2,v0] = impact_generator('./total_flux.txt',100)
%
% MATERIAL GROUP
%
% 1. expl_fragm, coll fragm, LMRO, Ejecta (Launch and Mission Related Objects)-> Al 7075
% 2. NaK droplets -> rho = 866 kg/m3 --> liquid hydrogen
% 3. Slag, SRM dust -> Al2O3/Corundum
% 4. Paint -> rubber
% 5. MLI -> Al 1100
% 6. Meteoroids -> Iron

    % PARAMETERS
    % Target properties (Al7075 - from Comsol case study)
    C2    = 5187;   % m/s 
    S2    = 1.36;  
    rho02 = 2748.5; % kg/m^3

    % Plate thickness
    t     = 0.001; % m 

    % Load data
    flux = importflux(file_path); 
    [D,V,G1,G2,G3,G4,G5,G6,T] = flux_conversion(flux);

    % Generate distribution of impacts 
    d   = zeros(N,1);
    v   = zeros(N,1);
    G   = zeros(N,1);
    C1  = zeros(N,1);
    S1  = zeros(N,1);
    rho01= zeros(N,1);

    for i = 1:N
        % Diameter and velocity based on Total MASTER flux
        [d(i),v(i)] = pinky(D,V,T,10);

        % Group distribution
        G(i)  = gassignment(G1,G2,G3,G4,G5,G6,D,V,d(i),v(i));    

        % Mechanical properties
        [C1(i), S1(i), rho01(i)] = mechprop(G(i));
    end

    % Obtain wave velocity (up2_n)
    a   = rho02.*S2 - rho01.*S1;
    b   = rho02.*C2 + rho01.*C1 + 2*rho01.*S1.*v;
    c   = -rho01.*(C1.*v+S1.*v.^2);
    up2_p = (-b + sqrt(b.^2-4*a.*c))./(2*a);
    up2_n = (-b - sqrt(b.^2-4*a.*c))./(2*a);

    % Select positive and lower than v solutions
    up2_p(up2_p < 0 | up2_p > v) = 0;
    up2_n(up2_n < 0 | up2_n > v) = 0;
    up2 = max(up2_p, up2_n);

    % Compute pressure
    P      = rho02 * up2 .* (C2 + S2.*up2);

    % Compute penetration time (pp. 591 MA Meyer)
    dt          = d./(v-up2);
    crosspen    = dt.*up2 > t;
    dt(crosspen)= t./up2(crosspen);

    % Remove errors
    dt(up2==0)  = [];
    P(up2==0)   = [];
    d(up2==0)   = [];
    v(up2==0)   = [];
    G(up2==0)   = [];
    crosspen(up2==0)   = [];
    up2(up2==0) = [];
    
    xout = [dt,P,d,up2,v,crosspen,G];
end