function [smoothT, smoothY] = smoothInterp(T, Y)

%more frequent times for spline
smoothT = T(1):0.1:T(end);

%smooth and interpolate the time series
smoothY = smooth(Y);
smoothY = interp1(T, smoothY, smoothT);