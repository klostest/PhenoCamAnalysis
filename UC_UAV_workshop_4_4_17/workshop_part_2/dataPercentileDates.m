function [sixDates] = dataPercentileDates(T, Y, percentiles)
% This function accepts a smoothed, e.g. with a spline, GCC time series "Y"
% and corresponding time vector "T", and the percentiles at which to
% estimate dates, i.e. "percentiles = [10 50 90]".
%
% The output is "sixDates...
%
% Stephen Klosterman
% 6/16/2015

%Set up dummy return values if algorithm fails
sixDates = NaN*ones(1,6);

%% If less than 90 days, don't do it
if max(T) < 90, return; end

%Isolate spring time
springY = Y(T<180);
springT = T(T<180);

%If there is spring time data, estimate spring time dates
if ~isempty(springY)
    
%***Start here
%We have the percentiles as input.  How do we compute, from the data, which
%greenness values do these correspond to?
%Put these in a 3x1 array called 'thresh'

%Now that we have the thresholds, we would like to determine the first day
%of year that greenness exceeds these thresholds in spring.  Talk with your
%partner or group about how you might do this, then give it a shot.
%% Spring
%when does greenness first cross the thresholds without turning back?

%Replace the dummy values in 'sixDates'.  You will only compute
%the first three dates here for spring.

else
    %skip spring if no data
end

%%  Autumn
%using same percentiles as for spring
fallY = Y(T>180);
fallT = T(T>180);

if ~isempty(fallY) %do if there's data
    
%*** We need to take the same basic steps here.  Think first about what the
%percentiles mean in autumn, as opposed to spring.  Then think about how
%you might quickly apply the approach you used for spring, to the fall
%data.

else
    %skip fall if no data
end