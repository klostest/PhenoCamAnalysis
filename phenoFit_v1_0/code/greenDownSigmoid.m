function [Y] = greenDownSigmoid(params, X)
%============================================
% [Y] = fullYearSigmoid(params, X)
%
%% description
% This function contains the model equation for a full year sigmoid,
% similar in form to Fisher, 2006, RSE
%
%% inputs
% params is a 1 by 6 vector containing sigmoid parameters:  a (part of the
% formula for the midpoint), b (part of the formula for the slope), c
% amplitude, d  baseline
% vmin = background greenness
% vamp = amplitude of greeness signal
% m1 = phase shift for greenup
% m2 = slope for greenup
% m3 = phase shift for abscission
% m4 = slope for abscission
%
% X is a time vector to return modeled values at
%
%% outputs
% Y is a vector of modeled values
%
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================

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