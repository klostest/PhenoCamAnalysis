function [Y] = greenDownSigmoid(params, X)
%============================================
%
%% inputs
% Parameters.  See
% Elmore, A. J., Guinn, S. M., Minsley, B. J., and Richardson, A. D.:
% Landscape controls on the timing of spring, fall, and growing season
% length in mid-Atlantic forests, Glob. Chang. Biol., 18, 656?674, 2012.
% 
% X is a time vector to return modeled values at
%
%% outputs
% Y is a vector of modeled values

m1 = params(1);
m2 = params(2);
m3p = params(3);
m4p = params(4);
m5p = params(5);
m6p = params(6);
m7 = params(7);

Y = m1 + (m2 - m7*X) .* ( 1 ./ (1 + exp( (m3p - X) ./ m4p ) ) - ...
    1 ./ (1 + exp( (m5p - X) ./ m6p) ) );

% Y = vmin + vamp * ( 1 / (1 + exp(m1 + m2*X)) - ...
%     1 / (1 + exp(m3 + m4*X)) );