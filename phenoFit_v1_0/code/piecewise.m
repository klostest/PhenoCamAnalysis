function [Y] = piecewise(params, X)
%============================================
% [Y] = singleSigmoid(params, X)
%
%% description
% This function contains the model equation for a sigmoid, using the
% notation of Zhang 2003 
%
%% inputs
% params is a 1 by 4 vector containing sigmoid parameters:  a (part of the
% formula for the midpoint), b (part of the formula for the slope), c
% amplitude, d  baseline
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


a1 = params(1);
b1 = params(2);
c1 = params(3);
d1 = params(4);

t1 = params(5);

a2 = params(6);
b2 = params(7);
c2 = params(8);

t2 = params(9);

a3 = params(10);
b3 = params(11);
c3 = params(12);
d3 = params(13);

t3 = params(14);

a4 = params(15);
b4 = params(16);
c4 = params(17);
d4 = params(18);

X1 = X(X<t1);
Y1 = c1 ./ (1 + exp(a1+b1*X1)) + d1;

X2 = X((t1<=X)&(X<=t2));
% Y2 = a2*X2.^2 + b2*X2 + c2;
Y2 = b2*X2 + c2;

X3 = X((t2<X)&(X<=t3));
Y3 = c3 ./ (1 + exp(a3+b3*X3)) + d3;

X4 = X(X>t3);
Y4 = c4 ./ (1 + exp(a4+b4*X4)) + d4;

Y = [Y1 Y2 Y3 Y4];