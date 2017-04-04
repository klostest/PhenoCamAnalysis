function [smoothT, smoothY] = smoothInterp(T, Y, dataFrac)

% for experimenting with smoothing the raw data directly
% T = Traw; Y = Yraw;

%get rid of duplicate times
[T, m, n] = unique(T);
Y = Y(m);

%more frequent times for spline
smoothT = T(1):0.1:T(end);
% smoothT = T;

%This is the approach used in the PhenoCam MODIS paper.  Smooth data using
%a loess
smoothY = smooth(Y, dataFrac, 'loess');  %0.1 for Phenocam, 0.2 for Modis

%Then apply ubic spline interpolation
smoothY = spline(T, smoothY, smoothT);