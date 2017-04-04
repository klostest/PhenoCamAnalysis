function [sixDates] = fallRedMax(T, Y)
sixDates = NaN*ones(1,6);

%just fall
Y = Y(T>200);
T = T(T>200);
% obsolete because smoothing is now a model
% %more frequent times for spline
% smoothT = T(1):0.1:T(end);
% 
% %smooth and interpolate the time series
% smoothY = smooth(Y);
% smoothY = interp1(T, smoothY, smoothT);
%when is peak red?
peakRed = T(Y==max(Y));
if isempty(peakRed); peakRed = NaN; end
sixDates(4:6) = peakRed*ones(1,3);