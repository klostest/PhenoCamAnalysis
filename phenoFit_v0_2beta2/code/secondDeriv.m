function [sixDates] = secondDeriv(params, minMax, T, cutOffDates)
%============================================
% [sixDates] = secondDeriv(params, minMax, cutOffDates, T)
%
%% description
% This function uses extrema in the second derivative to estimate
% phenology transition dates, as described in Ahrends et al, 2008.
%% inputs
% params is a 2 by 4 vector containing the sigmoid parameters for both
% spring and fall sigmoids, using the same notation as Zhang
%
% minMax is a symbolic expression containing the formula for the times of
% extrema in the second derivative
%
% cutOffDates is a 1 by 2 vector with the DOYs for the end of the spring
% sigmoid and the beginning of the fall sigmoid
%
% T is a vector of times for modeled data
%
%% outputs
% sixDates is a 1 by 6 vector containing the times of extrema of the second
% derivative (first, third, fourth and sixth elements), and the time of
% maximum increase or decrease of the sigmoid (second and fifth elements).
%
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================
%% General form
%declare symbolic variables
syms a b
sixDates(1:2) = subs(minMax, {a, b},...
    {params(1,1) params(1,2)});
%add in max rate of change, half way between
%inflection points
sixDates(3) = sixDates(2);
sixDates(2) = sixDates(1) + ...
    0.5 * (sixDates(3) - sixDates(1));
                    
%note reverse indexing
sixDates(5:-1:4) = subs(minMax, {a, b},...
    {params(2,1) params(2,2)});
%add in max rate of change, half way between
%inflection points
sixDates(6) = sixDates(5);
sixDates(5) = sixDates(4) + ...
    0.5 * (sixDates(6) - sixDates(4));
                    
%get rid of pheno dates when either one is outside
%of sigmoid that was used to model that season
for k = 1:3
    if sixDates(k) < min(T) || ...
        sixDates(k) > cutOffDates(1)
            sixDates(1:3) = zeros(3,1);
    end
end
for k = 4:6
    if sixDates(k) > max(T) || ...
        sixDates(k) < cutOffDates(2)
            sixDates(4:6) = zeros(3,1);
    end
end