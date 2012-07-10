function [threeDates] = CCR(params, X, Kprime)
%============================================
% [threeDates] = CCR(params, X, Kprime)
%
%% description
% This function uses the rate of change of curvature (CCR) to estimate
% phenology transition dates, as described in Zhang et al, 2003.
%% inputs
% params is a 1 by 4 vector containing the sigmoid parameters, using the
% same notation as Zhang
%
% X is a vector of dates encompassing the modeled time series
%
% Kprime is a symbolic expression containing the formula for the curvature
% change rate
%
%% outputs
% threeDates is a 1 by 3 vector containing the times of maxima of curvature
% of a sigmoid (first and third elements), and the time of maximum increase
% or decrease of the sigmoid (second element).
%
%% notes
% Since the symbolic math toolbox does not appear capable of analytically
% solving for the derivative of the CCR function, I took the approach of
% stepping through the time series to find maxima and minima.  However root
% finding is a classical problem in numerical methods and there are
% undoubtedly better ways to do this.
%
% The parameter 'grain' controls the resolution of the synthetic data time
% series used to estimate times of maximum or minimum CCR.
%
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================
%%
% the resolution of the time series used to estimate changes in sign of the
% CCR.  The time series will have this many intervals between the start and
% end dates of the season
grain = 10000;

%error handling for zero params
if params == zeros(1,4), threeDates = zeros(1,3); return; end

%% CCR (curvature change rate), from Zhang et al., 2003 
% declare symbolic variables
syms x a b c

%make a time vector with fairly high resolution to solve numerically for
%max and min of CCR
T = min(X):(max(X)-min(X))/grain:max(X);

tempCCR = subs( Kprime, {'x', 'a', 'b', 'c'}, ...
    {T, params(1), params(2), params(3)} );

%step through and grab dates where CCR changes sign
n = 1;  %counter
for i = 1:length(T)-2
    if sign( tempCCR(i+1) - tempCCR(i) ) ...
        ~= ...
        sign( tempCCR(i+2) - tempCCR(i+1) ) ...
        %error handling:  only use if not very close to zero
        if abs(tempCCR(i)) > eps
            threeDates(n) = T(i+1);
            n = n+1;
        end
    end
end

%error handling in case dates are out of season or there is some other
%reason why exactly three dates were not obtained
if n ~= 4, threeDates = zeros(1,3); end

% % doesn't look like matlab can solve analytically for the maximum CCR
% KprimePrime = diff(Kprime, x);
% maxCCR = solve(KprimePrime, x);