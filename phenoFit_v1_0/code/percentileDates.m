function [sixDates] = percentileDates(params, X, fhandle, percentiles, ...
    modelName)

grain = 10000;
if params == zeros(size(params)), sixDates = zeros(1,6); return; end

%for length of time series, identify points where curve is 10, 50, and 90
%percent of the maximum distance from the curve in spring, and 90, 50, and
%10 percent of the distance to the curvature change point in fall.

%% get CCR dates
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

%% percentile method
switch modelName
    case 'greenDownRichards'
        base = params(1); base2 = params(13);
        baseLine = (base + base2*T);
    case 'greenDownSigmoid'
        baseLine = params(1)*ones(size(T));
    case 'separateSigmoids'
end

springT = T(T<sixDates(3));
springY = Y(T<sixDates(3));
springBaseLine = baseLine(T<sixDates(3));

% for i = 1:length(springY)
% %     if (springY(i)-springBaseLine(i)) > (0.90*(max(springY) - springBaseLine(i)))
%     if (springY(i)-springBaseLine(i)) == (max(springY) - springBaseLine(i))
%         sixDates(3) = springT(i);
%         break
%     end
% end

for i = 1:length(springY)
    if (springY(i)-springBaseLine(i)) > ...
            (percentiles(1)*(max(springY) - springBaseLine(i)))
        sixDates(1) = springT(i);
        break
    end
end

for i = 1:length(springY)
    if (springY(i)-springBaseLine(i)) > ...
            (percentiles(2)*(max(springY) - springBaseLine(i)))
        sixDates(2) = springT(i);
        break
    end
end



if sixDates(4) == 0, return; end

fallT = T(T>=sixDates(4));
fallY = Y(T>=sixDates(4));
fallBaseLine = baseLine(T>=sixDates(4));

% for i = 1:length(fallY)
%     if (fallY(i)-fallBaseLine(i)) < (0.90*(max(fallY) - fallBaseLine(i)))
%         sixDates(4) = fallT(i);
%         break
%     end
% end

for i = 1:length(fallY)
    if (fallY(i)-fallBaseLine(i)) < ...
            (percentiles(3)*(max(fallY) - fallBaseLine(i)))
        sixDates(5) = fallT(i);
        break
    end
end

for i = 1:length(fallY)
    if (fallY(i)-fallBaseLine(i)) < ...
            (percentiles(4)*(max(fallY) - fallBaseLine(i)))
        sixDates(6) = fallT(i);
        break
    end
end

%throw out out of season dates
if (min(sixDates(1:3))<0) || (max(sixDates(1:3))>200)
    sixDates(1:3) = zeros(1,3);
end
if (min(sixDates(4:6))<200) || (max(sixDates(4:6))>365)
    sixDates(4:6) = zeros(1,3);
end