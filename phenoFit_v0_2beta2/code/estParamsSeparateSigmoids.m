function [params, modelT, modelY, cutOffDates, resnorm, initGuess,...
    initGuessY, weighting] = ...
    estParamsSeparateSigmoids(fhandle, modelName, dataT, dataY)
%============================================
% [] = [params, modelT, modelY, cutOffDates, resnorm] = ...
%    estParamsSeparateSigmoids(fhandle, dataT, dataY, weighting)
%
%% description
% This function constructs an initial guess for parameters for separate
% sigmoid curves of the form (Y = c ./ (1 + exp(a+b*X)) + d) based on on
% the input data, then uses lsqnonlin.m to estimate the parameters.
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
% 11/20/2011
% steve.klosterman@gmail.com
%============================================

%% dealing with partial years
%report zero params if a season is missing

%% default arguments
% set non-default options for matlab's parameter estimation algorithm
options = optimset('MaxFunEvals', 4*1e3, 'MaxIter', 4*1e3,...
    'Display', 'off' );
% weighting{1} = 'timeExponential';
% weighting{2} = 2;

weighting.type = 'timeTrigger';
weighting.weight = 1;

% weighting{1} = 'none';

%% initial guess
%the approach for
%producing an initial guess for the 'b' parameter may need to be modified.

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

%subset the data for a good sigmoid fit
springData = firstHalfYearData;%firstHalfYearData(1:endWindowIndex);
springTime = firstHalfYearTime;%firstHalfYearTime(1:endWindowIndex);

%% initial guess for parameters
% only do this if there is enough spring time in the data set
if (~isempty(springTime) && ...
        (springTime(length(springTime))-springTime(1) >= changeTime)); %days

[beginWindowTime, endWindowTime, beginWindowData,...
endWindowData, beginWindowIndex, endWindowIndex] = ...
seasonalChange(changeTime, firstHalfYearTime, firstHalfYearData);

%*** trying new things***
peakGreen = max(springData);
% peakGreen = beginWindowData;
baseGreen = min(springData);
% baseGreen = endWindowData;

%now need initial guess.  The amplitude should be peak minus baseline
amp = peakGreen - baseGreen;
%time for middle of sigmoid, aka max increase
maxInc = beginWindowTime + ...
    0.5*(endWindowTime - beginWindowTime);
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.
b = -4 / (endWindowTime - beginWindowTime);
%translation
a = -b * maxInc;

%time trigger for cost function weighting
weighting.times(1) = beginWindowTime;
weighting.times(2) = endWindowTime;

initGuess1 = [a b amp baseGreen];

%% see how initial guess is
temp1 = fhandle(initGuess1, springTime);
h = figure;
plot(springTime, temp1, springTime, springData);
close(h);

%% error checking:  onset and offset dates should not be the same
% if onsetIndex == peakIndex
%     params(1,:) = [0 0 0 0];
%     resnorm(1) = 0;
% else
    %% parameter estimation
    %non-linear least squares
    [params(1,:), resnorm(1)]...
        = lsqnonlin(@(params)...
        dataDiff(params,springData,springTime,fhandle,modelName,...
        weighting), initGuess1,...
        -Inf, Inf, options);
% end
else params(1,:) = zeros(1,4); cutOffDates(1) = 0; resnorm(1) = 0;
end

%%============================================
%% Fall
%%============================================

%%
weighting.type = 'timeTrigger';

%% subset the data
%get data indices for the second half of the year
secondHalfYearIndices = dataT >= halfYear;
secondHalfYearTime = dataT(secondHalfYearIndices);
secondHalfYearData = dataY(secondHalfYearIndices);

%subset the data for a good sigmoid fit
fallData = secondHalfYearData;
% fallData = secondHalfYearData...
%(beginWindowIndex:length(secondHalfYearData));
fallTime = secondHalfYearTime;
% fallTime = secondHalfYearTime...
%(beginWindowIndex:length(secondHalfYearTime));

%% initial guess for parameters
% only do this if there is enough fall in the data set
if (~isempty(fallTime) && ...
        (fallTime(length(fallTime))-fallTime(1) >= changeTime))

[beginWindowTime, endWindowTime, beginWindowData,...
    endWindowData, beginWindowIndex, endWindowIndex] = ...
    seasonalChange(changeTime, secondHalfYearTime, secondHalfYearData);
%*** trying new things***
peakGreen = max(fallData);
% peakGreen = beginWindowData;
baseGreen = min(fallData);
% baseGreen = endWindowData;

%now need initial guess.  The amplitude should be peak minus baseline
amp = peakGreen - baseGreen;
%time for middle of sigmoid, aka max increase
maxInc = fallTime(1) + ...
    0.5*(endWindowTime - fallTime(1));
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.  Note
%that b < 0 for an increasing sigmoid and b > 0 for decreasing.
b = -4 / (fallTime(1) - endWindowTime);
%translation
a = -b * maxInc;

weighting.times(1) = fallTime(1);
weighting.times(2) = endWindowTime;

initGuess2 = [a b amp baseGreen];

%% see how initial guess is
temp2 = fhandle(initGuess2, fallTime);
h = figure;
plot(fallTime, temp2, fallTime, fallData);
close(h);

%% error checking:  peak and offset dates should not be the same
% if peakFallIndex == offsetIndex
%     params(2,:) = [0 0 0 0];
%     resnorm(2) = 0;
% else
%% parameter estimation
%non-linear least squares
[params(2,:), resnorm(2)]...
    = lsqnonlin(@(params)...
    dataDiff(params,fallData,fallTime,fhandle,modelName,...
    weighting), initGuess2,...
    -Inf, Inf, options);
% end
else params(2,:) = zeros(1,4); cutOffDates(2) = 0; resnorm(2) = 0;
end

%% stitch together spring and fall models for output

modelT = [springTime fallTime];
modelY = [fhandle(params(1,:), springTime) fhandle(params(2,:), fallTime)];

if (~isempty(springTime) && ...
        (springTime(length(springTime))-springTime(1) >= changeTime)) &&...
        (~isempty(fallTime) && ...
        (fallTime(length(fallTime))-fallTime(1) >= changeTime));
    cutOffDates = [max(springTime) min(fallTime)];
    initGuess = [initGuess1; initGuess2];
    initGuessY = [temp1 temp2];
elseif (~isempty(springTime) && ...
        (springTime(length(springTime))-springTime(1) >= changeTime)) &&...
        (isempty(fallTime) || ...
        (fallTime(length(fallTime))-fallTime(1) < changeTime)); %<
    cutOffDates = [max(springTime) 0];
    initGuess = [initGuess1; 0 0 0 0];
    initGuessY = [temp1];
elseif (isempty(springTime) || ...
        (springTime(length(springTime))-springTime(1) < changeTime)) &&... %<
        (~isempty(fallTime) && ...
        (fallTime(length(fallTime))-fallTime(1) >= changeTime));
    cutOffDates = [0 min(fallTime)];
    initGuess = [0 0 0 0; initGuess2];
    initGuessY = [temp2];
end

if (isempty(springTime) || ...
        (springTime(length(springTime))-springTime(1) < changeTime)) &&...
        (isempty(fallTime) || ...
        (fallTime(length(fallTime))-fallTime(1) < changeTime));
    params = zeros(2,4);
    modelT = zeros(size(dataT));
    modelY = zeros(size(dataY));
    cutOffDates = [0 0];
    initGuess = zeros(2,4);
    initGuessY = zeros(size(dataY));
end
%% see how parameter estimation worked
h = figure;
plot(modelT, modelY, dataT, dataY);
close(h);

%% old way for comparison.  need to do at least as well.
% %% spring
% %estimate and plot sigmoid model
% %bartlett spring
% springLogical{i} = T{i} <= 160;
% springTime{i} = T{i}(springLogical{i});
% springData{i} = Y{i}(springLogical{i});
% initGuess{i} = [140, 0.5, 0.32, 0.1];
%         
% %% fall
% %bartlett fall
% fallLogical{i} = T{i} >= 240;
% fallTime{i} = T{i}(fallLogical{i});
% fallData{i} = Y{i}(fallLogical{i});
% initGuess2{i} = [270, 0.5, 0.33, 0.04];
%
%% random junk from who knows where
%initial guess
% initGuess = [50, 0.5, 0.3, 0.6];