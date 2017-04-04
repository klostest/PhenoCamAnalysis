function [params, modelT, modelY, cutOffDates, resnorm, initGuess,...
    initGuessY, weighting] = ...
    estParamsFullYearSigmoid(fhandle, modelName, dataT, dataY, weighting)
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

%% default arguments
% set non-default options for matlab's parameter estimation algorithm
options = optimset('MaxFunEvals', 4*1e3, 'MaxIter', 4*1e3,...
    'Display', 'off' );

weighting.type = 'timeTrigger';
weighting.weight = 1;    %200;

%% dealing with partial years
%report zero params if a season is missing
%in order to do full year model, require an upper limit to start date and a
%lower limit to end date
if ~(min(dataT) > 100) || (max(dataT) < 300)

%% set metaparameters
%Initial cut to divide the year halfway into two seasons
halfYear = 200;

%%============================================
%% Spring
%%============================================
%% subset the data
%get data indices for the first half of the year
firstHalfYearIndices = dataT <= halfYear;
firstHalfYearTime = dataT(firstHalfYearIndices);
firstHalfYearData = dataY(firstHalfYearIndices);
changeTime = 21;    %days for greenup

%% initial guess for parameters
% only do this if there is enough spring time in the data set
if (~isempty(firstHalfYearTime) && ...
        (firstHalfYearTime(length...
        (firstHalfYearTime))-firstHalfYearTime(1) >= changeTime)); %days

[beginWindowTime, endWindowTime, beginWindowData,...
endWindowData, beginWindowIndex, endWindowIndex] = ...
seasonalChange(changeTime, firstHalfYearTime, firstHalfYearData);

%*** trying new things***
peakGreenSpring = max(firstHalfYearData);
% peakGreen = beginWindowData;
baseGreenSpring = min(firstHalfYearData);
% baseGreen = endWindowData;

%now need initial guess.  The amplitude should be peak minus baseline
ampSpring = peakGreenSpring - baseGreenSpring;
%time for middle of sigmoid, aka max increase
maxInc = beginWindowTime + ...
    0.5*(endWindowTime - beginWindowTime);
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.
m2 = -4 / (endWindowTime - beginWindowTime);
%translation
m1 = -m2 * maxInc;

else
    params = NaN*ones(1,6);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    initGuess = params;
    initGuessY = modelY;
    cutOffDates = [NaN NaN];
    resnorm = NaN;
    weighting.weightMask = NaN;
    return
end

%%============================================
%% Fall
%%============================================
%% subset the data
%get data indices for the second half of the year
secondHalfYearIndices = dataT >= halfYear;
secondHalfYearTime = dataT(secondHalfYearIndices);
secondHalfYearData = dataY(secondHalfYearIndices);

%% initial guess for parameters
% only do this if there is enough fall in the data set
if (~isempty(secondHalfYearTime) && ...
        (secondHalfYearTime(length...
        (secondHalfYearTime))-secondHalfYearTime(1) >= changeTime))

[beginWindowTime2, endWindowTime2, beginWindowData2,...
    endWindowData2, beginWindowIndex2, endWindowIndex2] = ...
    seasonalChange(changeTime, secondHalfYearTime, secondHalfYearData);
%*** trying new things***
peakGreenFall = max(secondHalfYearData);
% peakGreen = beginWindowData;
baseGreenFall = min(secondHalfYearData);
% baseGreen = endWindowData;

%now need initial guess.  The amplitude should be peak minus baseline
ampFall = peakGreenFall - baseGreenFall;
%time for middle of sigmoid, aka max increase (average of window times)
maxInc = beginWindowTime2 + ...
    0.5*(endWindowTime2 - beginWindowTime2);
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.  Note
%that b < 0 for an increasing sigmoid and b > 0 for decreasing.
m4 = -4 / (endWindowTime2 - beginWindowTime2);
%translation
m3 = -m4 * maxInc;

initGuess = [(baseGreenSpring + baseGreenFall)/2 ...
    (ampSpring + ampFall)/2 ...
    m1 m2 m3 m4];

weighting.weightMask = logical( ( (dataT > beginWindowTime2) & ...
    dataT < endWindowTime2) + (dataT > beginWindowTime) & ...
    dataT < endWindowTime );

%% see how initial guess is
initGuessY = fhandle(initGuess, dataT);
plot(dataT, initGuessY, dataT, dataY);
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
    params = NaN*ones(1,6);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    initGuess = params;
    initGuessY = modelY;
    cutOffDates = [NaN NaN];
    resnorm = NaN;
end
    

else
    params = NaN*ones(1,6);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    initGuess = params;
    initGuessY = modelY;
    cutOffDates = [NaN NaN];
    resnorm = NaN;
end

%% see how parameter estimation worked
plot(modelT, modelY, dataT, dataY);
clf