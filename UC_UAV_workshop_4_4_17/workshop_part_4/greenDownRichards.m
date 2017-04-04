function [Y] = greenDownRichards(params, X)
%============================================
%% inputs
% parameters... see e.g.
% Richards, F. J.: A Flexible Growth Function for Empirical Use,
% J. Exp. Bot., 10, 290?301, 1959.
%Additionally this has quadratic summer time greenness connecting the two
%general sigmoid functions
%
% X is a time vector to return modeled values at
%
%% outputs
% Y is a vector of modeled values

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

Y = (base + base2*X) + (a*X.^2 + b*X + c) .* ...
    ( ( 1 ./ (1 + Q1*exp( -B1*(X - M1))) ).^V1  - ...
    ( 1 ./ (1 + Q2*exp( -B2*(X - M2))) ).^V2 );