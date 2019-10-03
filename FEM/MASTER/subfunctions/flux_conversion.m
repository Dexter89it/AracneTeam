function [D,V,G1,G2,G3,G4,G5,G6,T] = flux_conversion(flux)
% Converts the flux matrix into the required format
%
% INPUT
%
% Format of the flux matrix
% diameter, impact velocity, expl-fragm, coll-fragm, launch/mis, NaK drops,
% SRM slag, SRM dust, Paint, Flks, Ejecta, MLI, Meteoroids, Streams, Cloud
% 1, Cloud 2, Cloud 3, Cloud 4, Cloud 5, Total
%
% The previous are subdivided into 6 groups with "similar" mechanical
% properties in terms of Hugoniot curve
% 1. expl_fragm, coll fragm, LMRO, Ejecta (Launch and Mission Related Objects)-> Al 7075
% 2. NaK droplets -> rho = 866 kg/m3 --> liquid hydrogen
% 3. Slag, SRM dust -> Al2O3/Corundum
% 4. Paint -> rubber
% 5. MLI -> Al 1100
% 6. Meteoroids -> IRon
%
% OUTPUT
%
% Diameter (D), Velocity (V), total flux (T) and percentual group flux (Gi)
% Bulk load
d    = flux(:,1);
v    = flux(:,2)*1000;
D    = unique(d);
V    = unique(v);
T0   = flux(:,19);
G10  = flux(:,3) + flux(:,4) + flux(:,5) + flux(:,10);
G20  = flux(:,6);
G30  = flux(:,7) + flux(:,8);
G40  = flux(:,9);
G50  = flux(:,11);
G60  = flux(:,12) + flux(:,13);

% Reformatting
T    = zeros(length(V),length(D));
G1   = zeros(length(V),length(D));
G2   = zeros(length(V),length(D));
G3   = zeros(length(V),length(D));
G4   = zeros(length(V),length(D));
G5   = zeros(length(V),length(D));
G6   = zeros(length(V),length(D));

for i = 1:length(V)
    for j = 1:length(D)
        T(i,j)  = T0(d==D(j)  & v == V(i));
        if T(i,j)~= 0
            G1(i,j) = G10(d==D(j) & v == V(i))/T(i,j)*100;
            G2(i,j) = G20(d==D(j) & v == V(i))/T(i,j)*100;
            G3(i,j) = G30(d==D(j) & v == V(i))/T(i,j)*100;
            G4(i,j) = G40(d==D(j) & v == V(i))/T(i,j)*100;
            G5(i,j) = G50(d==D(j) & v == V(i))/T(i,j)*100;
            G6(i,j) = G60(d==D(j) & v == V(i))/T(i,j)*100;
        end
    end
end
