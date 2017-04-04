function [Y] = singleSigmoid(params, X)
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


a = params(1);
b = params(2);
c = params(3);
d = params(4);
Y = c ./ (1 + exp(a+b*X)) + d;