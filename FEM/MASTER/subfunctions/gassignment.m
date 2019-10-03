function G  = gassignment(G1,G2,G3,G4,G5,G6,D,V,d,v)
% Assigns a group to the d-v pair based on the probability distributions of
% each subgroup

% Probability calculator
g1  = interp2(D,V,G1,d,v);
g2  = interp2(D,V,G2,d,v);
g3  = interp2(D,V,G3,d,v);
g4  = interp2(D,V,G4,d,v);
g5  = interp2(D,V,G5,d,v);
g6  = interp2(D,V,G6,d,v);

% Group selection
G   = randsample(1:6, 1, true, [g1, g2, g3, g4, g5, g6]);