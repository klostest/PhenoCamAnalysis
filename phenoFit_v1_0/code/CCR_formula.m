function [] = CCR_formula()
%============================================
% [] = CCR_formula()
%
%% description
% This function uses the symbolic algebra package to make a formula for the
% curvature change rate described in Zhang et al., 2003.  Results are saved
% in the current directory.
%
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================
%%
%declare symbolic variables
%% CCR (curvature change rate), from Zhang et al., 2003 
syms x a b c z t1 t2 t3
z = exp(a + b*x);
t1 = 3*z*(1-z)*((1+z)^3)*(2*((1+z)^3)+(b^2)*(c^2)*z);
t2 = ((1+z)^2)*(1+2*z-5*(z^2));
t3 = ((1+z)^4 + (b*c*z)^2);
Kprime = (b^3)*c*z*(t1/(t3^(5/2)) - t2/(t3^(3/2)));

save('CCR_formula', 'Kprime')