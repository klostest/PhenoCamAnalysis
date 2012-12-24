function [sixDates] = CCRgd(params, X, Kprime, fhandle)
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
if params == zeros(size(params)), sixDates = zeros(1,6); return; end

%% CCR (curvature change rate), from Zhang et al., 2003 
% declare symbolic variables
syms x a b c

%make a time vector with fairly high resolution to solve numerically for
%max and min of CCR
dT = (max(X)-min(X))/grain;
T = min(X):dT:max(X);

% tempCCR = subs( Kprime, {'x', 'a', 'b', 'c'}, ...
%     {T, params(1), params(2), params(3)} );

%make Y vector for numerical approximation of curvature
Y = fhandle(params, T);
lenY = length(Y);
Ydot = (Y(3:lenY) - Y(1:lenY-2))/(2*dT);
Ydd = (Y(3:lenY) -2*Y(2:lenY-1) + Y(1:lenY-2))/(dT^2);
curve = Ydd ./ ((1 + Ydot.^2).^(3/2));
curveT = T(2:length(T)-1);
lenCurve = length(curve);
tempCCR2 = (curve(3:lenCurve) - curve(1:lenCurve-2))/(2*dT);
CCR2T = curveT(2:lenCurve-1);
% tempCCR2 = smooth(tempCCR2, 21, 'sgolay', 2);
% [tempCCR2, goodness] = fit(CCR2T', tempCCR2', 'smoothingspline' );

h = figure;
plot(CCR2T, tempCCR2);
close(h);

% %step through and grab dates where CCR changes sign
% n = 1;  %counter
% for i = 1:length(T)-2
%     if sign( tempCCR(i+1) - tempCCR(i) ) ...
%         ~= ...
%         sign( tempCCR(i+2) - tempCCR(i+1) ) ...
%         %error handling:  only use if not very close to zero
%         if abs(tempCCR(i)) > eps
%             threeDates(n) = T(i+1);
%             n = n+1;
%         end
%     end
% end

%step through and grab dates where CCR changes sign
n = 1;  %counter
for i = 1:length(CCR2T)-2
    if sign( tempCCR2(i+1) - tempCCR2(i) ) ...
        ~= ...
        sign( tempCCR2(i+2) - tempCCR2(i+1) ) ...
        %error handling:  only use if not very close to zero
        if abs(tempCCR2(i)) > 1e-6
            sixDates(n) = CCR2T(i+1);
            n = n+1;
        end
    end
end

%if ten dates were obtained, check to ensure that middle date is
%surrounded by two other extrema.  All dates likely to be very close
%together in this situation anyways.
if n == 11 %from back to front to get indexing right
    sixDates(9) = [];
    sixDates(7) = [];
    sixDates(4) = [];
    sixDates(2) = [];
    fprintf(1, 'warning:  additional extrema in CCR\n');
    %reset counter
    n = 7;
end
    
%error handling in case dates are out of season or there is some other
%reason why exactly three dates were not obtained, besides above exception
if n ~= 7, sixDates = zeros(1,6); end


% % doesn't look like matlab can solve analytically for the maximum CCR
% KprimePrime = diff(Kprime, x);
% maxCCR = solve(KprimePrime, x);