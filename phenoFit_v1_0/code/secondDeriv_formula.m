function [] = secondDeriv_formula()
%============================================
% [] = secondDeriv_formula()
%
%% description
% This function uses the symbolic algebra package to solve for the extrema
% of the second derivative of a sigmoid function described in Zhang et al.
% 2003.  Results are saved in the current directory.
%
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================
%%
%declare symbolic variables
syms x a b c

%sigmoid function
y = c / (1 + exp(b*(x+a/b)));

%obtain third derivative
thirdDeriv = diff(y,x);
thirdDeriv = diff(thirdDeriv,x);
thirdDeriv = diff(thirdDeriv,x);

%find roots of third derivative, which are extrema of the second derivative
minMax = solve(thirdDeriv,x);

save('secondDeriv_formula', 'minMax');