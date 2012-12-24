function [sixDates] = dataPercentileDates(T, Y, percentiles)
sixDates = zeros(1,6);

%just spring
Y = Y(T<180);
T = T(T<180);
smoothY = Y;
smoothT = T;

%what is peak greenness?
peakGreen = max(smoothY);
%baseline? < DOY 50?
baseGreen = mean(smoothY(smoothT<50));

%what are the greenness thresholds to be crossed?
for i = 1:length(percentiles)
    thresh(i) = baseGreen + percentiles(i)*(peakGreen-baseGreen);
end

count = 1;
flags = ones(size(percentiles));
%when does greenness first cross the thresholds without turning back?
for i = 1:length(smoothY)
    for j = 1:length(thresh)
        if j < length(thresh) 
            %first two thresholds are
            %typically small enough that time series won't turn back
            if (smoothY(i) >= thresh(j)) && (min(smoothY(i:end)) >= thresh(j)) && ...
                    logical(flags(j))
                sixDates(count) = smoothT(i);
                count = count+1;
                flags(j) = 0;
            end
        else
            if (smoothY(i) >= thresh(j)) && logical(flags(j))
                %allow time series to turn back
                %for last threshold
                    
                sixDates(count) = smoothT(i);
                count = count+1;
                flags(j) = 0;
            end
        end
    end
end

sixDates;