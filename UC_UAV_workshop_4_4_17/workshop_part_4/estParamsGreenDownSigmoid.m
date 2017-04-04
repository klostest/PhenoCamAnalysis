function [params, modelT, modelY, cutOffDates, resnorm, initGuess,...
    initGuessY, weighting, residual, jacobian] = ...
    estParamsGreenDownSigmoid(fhandle, modelName, dataT, dataY, weighting)
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

%exit on empty year
if isempty(dataT)
    params = NaN*ones(1,7);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    cutOffDates = [NaN NaN];
    resnorm = NaN;
    initGuess = params;
    initGuessY = NaN;
    weighting.weightMask = NaN;
    residual = NaN;
    jacobian = NaN;
    return
end
%% default arguments
%*** levenburg-marquardt or not?  All the Phenocam-MODIS stuff apparently
%used it, but it's probably simpler just to use the default across all
%curve fits if it works.

% set non-default options for matlab's parameter estimation algorithm
options = optimset('MaxFunEvals', 4*1e3, 'MaxIter', 4*1e3,...
    'Display', 'off', 'Algorithm', 'levenberg-marquardt');

weighting.type = 'none';
weighting.weight = 1;    %200;

%% dealing with partial years
%report zero params if a season is missing
%in order to do full year model, require an upper limit to start date and a
%lower limit to end date
% if ~(min(dataT) > 110) || (max(dataT) < 300)
if ~(min(dataT) > 155) || (max(dataT) < 280)

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

%transform fisher nomenclature to elmore
m3 = m1; m4 = -m2;
m3p = m3/m4; m4p = 1/m4;

% weighting interval for parameter estimation.  Seems to work better when
% values during rapid increase or decrease are weighted more heavily (?)
%start weighting at spring onset index
weighting.times(1) = beginWindowTime;
weighting.times(2) = endWindowTime;

else
    params = NaN*ones(1,7);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    cutOffDates = [NaN NaN];
    resnorm = NaN;
    initGuess = params;
    initGuessY = NaN;
    weighting.weightMask = NaN;
    residual = NaN;
    jacobian = NaN;
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
%time for middle of sigmoid, aka max increase
maxInc = beginWindowTime2 + ...
    0.5*(endWindowTime2 - beginWindowTime2);
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.  Note
%that b < 0 for an increasing sigmoid and b > 0 for decreasing.
m4 = -4 / (endWindowTime2 - beginWindowTime2);
%translation
m3 = -m4 * maxInc;

%transform fisher nomenclature to elmore
m5 = m3; m6 = -m4;
m5p = m5/m6; m6p = 1/m6;

%other elmore params
m1 = (baseGreenSpring + baseGreenFall)/2;
m2 = (ampSpring + ampFall)/2;
%negative of slope
m7 = -(peakGreenFall - peakGreenSpring)/...
    (beginWindowTime2 - endWindowTime);

%increase amplitude guess to account for greendown slope
m2 = m2 + (beginWindowTime2 + endWindowTime)/2 * m7;

initGuess = [m1 m2 m3p m4p m5p m6p m7];

%indices for weighting interval
weighting.times(3) = beginWindowTime;
weighting.times(4) = endWindowTime;
 
% weighting.weightMask = [ zeros(1, weighting.times(1)-1) ...
%                 ones(1, weighting.times(2) - weighting.times(1) + 1) ...
%                 zeros(1, weighting.times(3) - weighting.times(2) -1) ...
%                 ones(1, weighting.times(4) - weighting.times(3) + 1) ...
%                 zeros(1, length(dataT) - weighting.times(4)) ];
            
weighting.weightMask = logical( ( (dataT > weighting.times(3)) & ...
    dataT < weighting.times(4)) + (dataT > weighting.times(1)) & ...
    dataT < weighting.times(2) );

%% see how initial guess is
initGuessY = fhandle(initGuess, dataT);
h = figure;
plot(dataT, initGuessY, dataT, dataY);
close(h);

%% error checking:  peak and offset dates should not be the same
% if peakFallIndex == offsetIndex
%     params(2,:) = [0 0 0 0];
%     resnorm(2) = 0;
% else
%% parameter estimation
%non-linear least squares
% [params, resnorm]...
[params,resnorm,residual,exitflag,output,lambda,jacobian] ...
    = lsqnonlin(@(params)...
    dataDiff(params,dataY,dataT,fhandle,modelName,weighting),...
    initGuess,...
    -Inf*ones(size(initGuess)), Inf*ones(size(initGuess)), options);
modelT = dataT;
modelY = fhandle(params, modelT);
%use the division line between seasons as the
%rejection for too late of a spring or too early of
%a fall
cutOffDates = [200 200];
else
    params = NaN*ones(1,7);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    cutOffDates = [NaN NaN];
    resnorm = NaN;
    initGuess = params;
    initGuessY = NaN;
    weighting.weightMask = NaN;
    residual = NaN;
    jacobian = NaN;
end
    
else
    params = NaN*ones(1,7);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    cutOffDates = [NaN NaN];
    resnorm = NaN;
    initGuess = params;
    initGuessY = NaN;
    weighting.weightMask = NaN;
    residual = NaN;
    jacobian = NaN;
end

%% see how parameter estimation worked
h = figure;
plot(modelT, modelY, dataT, dataY);
close(h);

% throw out if summer greendown is attempting to model the spring greenup
% (arbitrary criteria based on examination of several summer greendowns and
% a few summer greenups)
if params(7) < -0.003 %
    params = NaN*ones(1,7);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    cutOffDates = [NaN NaN];
    resnorm = NaN;
    initGuess = params;
    initGuessY = NaN;
    weighting.weightMask = NaN;
    residual = NaN;
    jacobian = NaN;
end

%throw out if middle of autumn is being modeled before DOY 200, to prevent
%autumn and spring fits from being confused
if params(5) < 200 %
    params = NaN*ones(1,7);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    cutOffDates = [NaN NaN];
    resnorm = NaN;
    initGuess = params;
    initGuessY = NaN;
    weighting.weightMask = NaN;
    residual = NaN;
    jacobian = NaN;
end
