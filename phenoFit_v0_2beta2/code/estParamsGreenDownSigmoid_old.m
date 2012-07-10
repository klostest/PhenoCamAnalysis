function [params, modelT, modelY, cutOffDates, resnorm, initGuess,...
    initGuessY, weighting] = ...
    estParamsGreenDownSigmoid_old(fhandle, modelName, dataT, dataY, weighting)
%============================================
% [] = [params, modelT, modelY, cutOffDates, resnorm] = ...
%    estParamsFullYearSigmoid(fhandle, dataT, dataY, weighting)
%
%% description
% This function constructs an initial guess and estimates parameters for
% the fullYearSigmoid model
%
%% inputs
% fhandle is a function handle of the model to be estimated, an individual
% sigmoid which is used both for spring and fall
%
% dataT is the time vector for the input data
%
% dataY is a vector of input data
%
%% dependencies
% getSigDate.m and dataDiff.m must be in the current directory
%
%% notes
% This function includes an automated approach to divide a full year
% of vegetation index data into appropriate sections for a spring sigmoid
% and a fall sigmoid, and make an initial guess at the parameters.  There
% are probably many ways to do this I am interested in your thoughts on
% whether or not this is useful, and if so, others ways it might be done.
%
% Several metaparameters controlling the approach here
% are arbitrary and were selected from experience with particular data
% sets.  The initial cut of the year is done at DOY 200, which was judged
% to be approximately in the middle of summer.  The two halves of the year
% are further truncated, and the initial guess is constructed, based on a
% rough model of accumulated days before or after low and high percentiles
% of data intended as rough onset, peak, offset, and dormancy dates.  The
% parameters that control which percentile and the number of accumulated
% days are also arbitrary and specific to a particular data set.
% 
% In a general approach it may be good to subject these metaparameters to
% some sort of optimization across the entire data set of all sites,
% inform the metaparameters using site specific climate information,
% or develop rules of thumb for particular types of vegetation indices.
%
%============================================
% Stephen Klosterman
% 4/8/2012
% steve.klosterman@gmail.com
%============================================

%% dealing with partial years
%report zero params if a season is missing
%in order to do full year model, require an upper limit to start date and a
%lower limit to end date
if ~(min(dataT) > 100) || (max(dataT) < 300)

%% default arguments
% set non-default options for matlab's parameter estimation algorithm
options = optimset('MaxFunEvals', 4*1e3, 'MaxIter', 4*1e3,...
    'Display', 'off' );
% weighting{1} = 'timeExponential';
% weighting{2} = 2;

weighting.type = 'timeTrigger';
weighting.weight = 1;    %200;

% weighting{1} = 'none';

downReg = 1;

%% set metaparameters 

%To choose when to end the spring sigmoid, a higher percentile, such as the
%90th, of the first half of the year's greenness values is identified.  A
%given number of accumulated data points after this value is achieved is
%chosen to end the spring sigmoid.  This number of data points will likely
%be different depending on the data source, i.e. gcc or MODIS.

%If changing any of the percentiles, the highly empirical approach for
%producing an initial guess for the 'b' parameter will need to be modified.

%Initial cut to divide the year halfway into two seasons
halfYear = 200;

%Percentile for estimating peak greenness during first half year
peakQuant = .9;

%Number of accumlated days after the peak has been achieved to truncate the
%data used for parameter estimation
% peakTrigger = 3;    %for MODIS EVI
peakTrigger = 15;    %for GCC data

%spring onset percentile
onsetQuant = .1;

%number of accumulated days for spring onset
onsetTrigger = 3;

%fall dormancy percentile
offsetQuant = .1;

%number of accumulated days for fall dormancy
offsetTrigger = 2;

%%============================================
%% Spring
%%============================================
%% subset the data
%get data indices for the first half of the year
firstHalfYearIndices = dataT <= halfYear;

%what is greenness at the chosen quantile for the first half of the year?
peakGreenSpring = quantile(dataY(firstHalfYearIndices),peakQuant);

%step through the first half of the year, stopping as soon as a certain
%number of values greater than or equal to the chosen greenness have been
%observed
firstHalfData = dataY(firstHalfYearIndices);
peakIndexSpring = getSigDate(firstHalfData, downReg*peakGreenSpring, ...
    peakTrigger, 'increase');

%subset the data for a good sigmoid fit
springData = dataY(1:peakIndexSpring);
springTime = dataT(1:peakIndexSpring);

% only do this if there is a spring time in the data set
if ~isempty(springTime)
%% initial guess for spring parameters
%same procedure for a rough onset date
baseGreenSpring = quantile(dataY(firstHalfYearIndices),onsetQuant);
onsetIndexSpring = getSigDate(springData, baseGreenSpring, onsetTrigger,...
    'increase');

%now need initial guess.  The amplitude should be peak minus baseline
ampSpring = peakGreenSpring - baseGreenSpring;
%time for middle of sigmoid, aka max increase
maxInc = springTime(onsetIndexSpring) + ...
    0.5*(springTime(peakIndexSpring) - springTime(onsetIndexSpring));
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.
m2 = -4 / (springTime(peakIndexSpring) - springTime(onsetIndexSpring));
%translation
m1 = -m2 * maxInc;

%transform fisher nomenclature to elmore
m3 = m1; m4 = -m2;
m3p = m3/m4; m4p = -1/m4;

% weighting interval for parameter estimation.  Seems to work better when
% values during rapid increase or decrease are weighted more heavily (?)
%start weighting at spring onset index
weighting.times(1) = onsetIndexSpring;
%stop weighting at index of maximum greenness
[maxSpringData, weighting.times(2)] = max(springData);

%% see how initial guess is
% temp = fhandle(initGuess, springTime);
% plot(springTime, temp, springTime, springData);
% clf
else
    params = zeros(1,7);
    modelT = zeros(size(dataT));
    modelY = zeros(size(dataY));
    cutOffDates = [0 0];
    resnorm = 0;
    initGuess = 0;
    initGuessY = 0;
    weighting.weightMask = 0;
    return
end

%%============================================
%% Fall
%%============================================

%%
weighting.type = 'timeTrigger';
peakTrigger = 3;

%% subset the data
% redo this based on k means clustering ?

%get data indices for the second half of the year
secondHalfYearIndices = dataT >= halfYear;
%get index of beginning of second half of year
[dummyVar, beginSecondHalfIndex] = max(secondHalfYearIndices);

%what is greenness at the chosen quantile for the second half of the year?
peakGreenFall = quantile(dataY(secondHalfYearIndices),peakQuant);

%step through the second half of the year, stopping as soon as a certain
%number of values less than or equal to the chosen greenness have been
%observed
secondHalfData = dataY(secondHalfYearIndices);
secondHalfTime = dataT(secondHalfYearIndices);
peakIndexFall = getSigDate(secondHalfData, peakGreenFall,...
    peakTrigger, 'decrease');

%subset the data for a good sigmoid fit
fallData = secondHalfData(peakIndexFall:length(secondHalfData));
fallTime = secondHalfTime(peakIndexFall:length(secondHalfTime));

% only do this if there is a fall in the data set
if length(fallTime) > 1
%% initial guess for parameters
baseGreenFall = quantile(dataY(secondHalfYearIndices),offsetQuant);
offsetIndexFall = getSigDate(fallData, baseGreenFall, offsetTrigger,...
    'decrease');

%now need initial guess.  The amplitude should be peak minus baseline
ampFall = peakGreenFall - baseGreenFall;
%time for middle of sigmoid, aka max increase
maxInc = fallTime(1) + ...
    0.5*(fallTime(offsetIndexFall) - fallTime(1));
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.  Note
%that b < 0 for an increasing sigmoid and b > 0 for decreasing.
m4 = 4 / (fallTime(1) - fallTime(offsetIndexFall));
%translation
m3 = -m4 * maxInc;

%transform fisher nomenclature to elmore
m5 = m3; m6 = -m4;
m5p = m5/m6; m6p = -1/m6;

%other elmore params
m1 = (baseGreenSpring + baseGreenFall)/2;
m2 = (ampSpring + ampFall)/2;
%negative of slope
m7 = -(peakGreenFall - peakGreenSpring)/...
    (fallTime(1) - springTime(peakIndexSpring));

initGuess = [m1 m2 m3p m4p m5p m6p m7];

%indices for weighting interval
weighting.times(3) = beginSecondHalfIndex + peakIndexFall - 1;
weighting.times(4) = beginSecondHalfIndex + offsetIndexFall - 1;

weighting.weightMask = [ zeros(1, weighting.times(1)-1) ...
                ones(1, weighting.times(2) - weighting.times(1) + 1) ...
                zeros(1, weighting.times(3) - weighting.times(2) -1) ...
                ones(1, weighting.times(4) - weighting.times(3) + 1) ...
                zeros(1, length(dataT) - weighting.times(4)) ];

%% see how initial guess is
initGuessY = fhandle(initGuess, dataT);
plot(dataT, temp, dataT, dataY);
clf

%% error checking:  peak and offset dates should not be the same
% if peakFallIndex == offsetIndex
%     params(2,:) = [0 0 0 0];
%     resnorm(2) = 0;
% else
%% parameter estimation
%non-linear least squares
[params, resnorm]...
    = lsqnonlin(@(params)...
    dataDiff(params,dataY,dataT,fhandle,modelName,weighting),...
    initGuess,...
    -Inf, Inf, options);
modelT = dataT;
modelY = fhandle(params, modelT);
%use the division line between seasons as the
%rejection for too late of a spring or too early of
%a fall
cutOffDates = [200 200];
else
    params = zeros(1,7);
    modelT = zeros(size(dataT));
    modelY = zeros(size(dataY));
    cutOffDates = [0 0];
    resnorm = 0;
    initGuess = 0;
    initGuessY = 0;
    weighting.weightMask = 0;
end
    

else
    params = zeros(1,7);
    modelT = zeros(size(dataT));
    modelY = zeros(size(dataY));
    cutOffDates = [0 0];
    resnorm = 0;
    initGuess = 0;
    initGuessY = 0;
    weighting.weightMask = 0;
end

%% see how parameter estimation worked
% plot(modelT, modelY, dataT, dataY);
% clf