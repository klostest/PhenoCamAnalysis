function [Y] = greenDownRichards(params, X)
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

base = params(1);
a = params(2);
b = params(3);
c = params(4);
Q1 = params(5);
B1 = params(6);
M1 = params(7);
V1 = params(8);
Q2 = params(9);
B2 = params(10);
M2 = params(11);
V2 = params(12);
base2 = params(13);
% d = params(13);
% a = 0; %linear

% % parabolic greendown
% Y = base + (a*X.^2 + b*X + c) .* ...
%     ( ( 1 ./ (1 + Q1*exp( -B1*(X - M1))) ).^V1  - ...
%     ( 1 ./ (1 + Q2*exp( -B2*(X - M2))) ).^V2 );

% different baselines
Y = (base + base2*X) + (a*X.^2 + b*X + c) .* ...
    ( ( 1 ./ (1 + Q1*exp( -B1*(X - M1))) ).^V1  - ...
    ( 1 ./ (1 + Q2*exp( -B2*(X - M2))) ).^V2 );

% %exponential greendown
% Y = base + (a + b*exp(d*(-X-c))) .* ...
%     ( ( 1 ./ (1 + Q1*exp( -B1*(X - M1))) ).^V1  - ...
%     ( 1 ./ (1 + Q2*exp( -B2*(X - M2))) ).^V2 );

% %cubic greendown
% Y = base + (a*X.^3 + b*X.^2 + c*X + d) .* ...
%     ( ( 1 ./ (1 + Q1*exp( -B1*(X - M1))) ).^V1  - ...
%     ( 1 ./ (1 + Q2*exp( -B2*(X - M2))) ).^V2 );

% Y = vmin + vamp * ( 1 / (1 + exp(m1 + m2*X)) - ...
%     1 / (1 + exp(m3 + m4*X)) );