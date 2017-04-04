function [sixDates] = dataPercentileDates(T, Y, percentiles)
% This function accepts a smoothed, e.g. with a spline, GCC time series "Y"
% and corresponding time vector "T", and the percentiles at which to
% estimate dates, i.e. "percentiles = [10 50 90]".
%
% The output is "sixDates...
%
% Stephen Klosterman
% 6/16/2015
sixDates = NaN*ones(1,6);

%% If less than 90 days, don't do it
if max(T) < 90, return; end

%just spring
springY = Y(T<180);
springT = T(T<180);

if ~isempty(springY)
%what is peak greenness?
peakGreen = max(springY);
%baseline? < DOY 50?
% base_green = mean(smoothY(smoothT<50));
%kmeans approach, assuming data will cluster around 2 means: dormant and
%active

[~,C] = kmeans(springY,2);
base_green = min(C);

%what are the greenness thresholds to be crossed?
for i = 1:length(percentiles)
    thresh(i) = base_green + percentiles(i)*(peakGreen-base_green);
end

count = 1;
springFlags = ones(size(percentiles));

%% Spring
%when does greenness first cross the thresholds without turning back?
for i = 1:length(springY)
    for j = 1:length(thresh)
        if j < length(thresh) 
            %first two thresholds are
            %typically small enough that time series won't turn back
            
            %note this doesn't work in the case of upperbuffalo, in which
            %the 50% threshold is crossed again very soon.  For this one
            %use the commented if statement
            
            if (springY(i) >= thresh(j)) && (min(springY(i:end)) >= ...
                    thresh(j)) && logical(springFlags(j))

%             if (springY(i) >= thresh(j)) && logical(springFlags(j))
                sixDates(count) = springT(i);
                count = count+1;
                springFlags(j) = 0;
            end
        else
            if (springY(i) >= thresh(j)) && logical(springFlags(j))
                %allow time series to turn back
                %for last threshold
                sixDates(count) = springT(i);
                count = count+1;
                springFlags(j) = 0;
            end
        end
    end
end
else
    %skip spring
end

%%  Autumn
%reverse and do same thing for autumn, using same thresholds as for spring
fallY = Y(T>180);
fallT = T(T>180);

if ~isempty(fallY)
    
fallY = flipud(fallY);
fallT = fliplr(fallT);

%redo limits for percentiles using fall data
[~,C] = kmeans(fallY,2);
base_green = min(C);
peakGreen = max(fallY);

%what are the greenness thresholds to be crossed?
for i = 1:length(percentiles)
    thresh(i) = base_green + percentiles(i)*(peakGreen-base_green);
end

count = 6;
autumnFlags = ones(size(percentiles));

%when does greenness first cross the thresholds without turning back?
for i = 1:length(fallY)
    for j = 1:length(thresh)
        if j < length(thresh) 
            %first two thresholds are
            %typically small enough that time series won't turn back
            if (fallY(i) >= thresh(j)) && (min(fallY(i:end)) >= ...
                    thresh(j)) && logical(autumnFlags(j))
                sixDates(count) = fallT(i);
                count = count-1;    %walking backward through time
                autumnFlags(j) = 0;
            end
        else
            if (fallY(i) >= thresh(j)) && logical(autumnFlags(j))
                %allow time series to turn back
                %for last threshold
                sixDates(count) = fallT(i);
                count = count-1;    %walking backward through time
                autumnFlags(j) = 0;
            end
        end
    end
end

else
    %skip fall
end