function [params, modelT, modelY, cutOffDates, resnorm] = ...
    estParamsSeparateSigmoids_old(fhandle, dataT, dataY, weighting)
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

weighting{1} = 'timeTrigger';
weighting{2}(3) = 200;

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
peakGreen = quantile(dataY(firstHalfYearIndices),peakQuant);

%step through the first half of the year, stopping as soon as a certain
%number of values greater than or equal to the chosen greenness have been
%observed
firstHalfData = dataY(firstHalfYearIndices);
peakIndex = getSigDate(firstHalfData, downReg*peakGreen, peakTrigger, 'increase');

%subset the data for a good sigmoid fit
springData = dataY(1:peakIndex);
springTime = dataT(1:peakIndex);

% only do this if there is a spring time in the data set
if ~isempty(springTime)
%% initial guess for parameters
%same procedure for a rough onset date
baseGreen = quantile(dataY(firstHalfYearIndices),onsetQuant);
onsetIndex = getSigDate(springData, baseGreen, onsetTrigger, 'increase');

%now need initial guess.  The amplitude should be peak minus baseline
amp = peakGreen - baseGreen;
%time for middle of sigmoid, aka max increase
maxInc = springTime(onsetIndex) + ...
    0.5*(springTime(peakIndex) - springTime(onsetIndex));
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.
b = -4 / (springTime(peakIndex) - springTime(onsetIndex));
%translation
a = -b * maxInc;

%time trigger for cost function weighting
if strcmp(weighting{1}, 'timeTrigger')
    weighting{2}(1) = springTime(onsetIndex);
end
weighting{2}(2) = max(springData);

initGuess = [a b amp baseGreen];

%% see how initial guess is
% temp = fhandle(initGuess, springTime);
% plot(springTime, temp, springTime, springData);
% clf

%% error checking:  onset and offset dates should not be the same
if onsetIndex == peakIndex
    params(1,:) = [0 0 0 0];
    resnorm(1) = 0;
else
    %% parameter estimation
    %non-linear least squares
    [params(1,:), resnorm(1)]...
        = lsqnonlin(@(params)...
        dataDiff(params,springData,springTime,fhandle,weighting), initGuess,...
        -Inf, Inf, options);
end
else params(1,:) = zeros(1,4); cutOffDates(1) = 0;
end

%%============================================
%% Fall
%%============================================

%%
weighting{1} = 'timeTrigger';
peakTrigger = 3;

%% subset the data


%%  redo this based on k means clustering, 


%get data indices for the second half of the year
secondHalfYearIndices = dataT >= halfYear;

%what is greenness at the chosen quantile for the second half of the year?
peakGreen = quantile(dataY(secondHalfYearIndices),peakQuant);

%step through the second half of the year, stopping as soon as a certain
%number of values less than or equal to the chosen greenness have been
%observed
secondHalfData = dataY(secondHalfYearIndices);
secondHalfTime = dataT(secondHalfYearIndices);
peakFallIndex = getSigDate(secondHalfData, peakGreen, peakTrigger, 'decrease');

%subset the data for a good sigmoid fit
fallData = secondHalfData(peakFallIndex:length(secondHalfData));
fallTime = secondHalfTime(peakFallIndex:length(secondHalfTime));

% only do this if there is a fall in the data set
if length(fallTime) > 1
%% initial guess for parameters
baseGreen = quantile(dataY(secondHalfYearIndices),offsetQuant);
offsetIndex = getSigDate(fallData, baseGreen, offsetTrigger, 'decrease');

%now need initial guess.  The amplitude should be peak minus baseline
amp = peakGreen - baseGreen;
%time for middle of sigmoid, aka max increase
maxInc = fallTime(1) + ...
    0.5*(fallTime(offsetIndex) - fallTime(1));
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.  Note
%that b < 0 for an increasing sigmoid and b > 0 for decreasing.
b = -4 / (fallTime(1) - fallTime(offsetIndex));
%translation
a = -b * maxInc;

% %time trigger for cost function weighting
% if strcmp(weighting{1}, 'timeTrigger')
%     weighting{2}(1) = maxInc;
% end
%k means clustering to get interval for weighting
% [IDX,C] = kmeans(fallData,2);
% weighting{2}(1) = max(C);
% weighting{2}(2) = min(C);
% end

weighting{2}(1) = fallTime(1);
weighting{2}(2) = fallTime(offsetIndex);

initGuess = [a b amp baseGreen];

%% see how initial guess is
% temp = fhandle(initGuess, fallTime);
% plot(fallTime, temp, fallTime, fallData);
% clf

%% error checking:  peak and offset dates should not be the same
if peakFallIndex == offsetIndex
    params(2,:) = [0 0 0 0];
    resnorm(2) = 0;
else
%% parameter estimation
%non-linear least squares
[params(2,:), resnorm(2)]...
    = lsqnonlin(@(params)...
    dataDiff(params,fallData,fallTime,fhandle,weighting), initGuess,...
    -Inf, Inf, options);
end
else params(2,:) = zeros(1,4); cutOffDates(2) = 0;
end

%% stitch together spring and fall models for output

modelT = [springTime fallTime];
modelY = [fhandle(params(1,:), springTime) fhandle(params(2,:), fallTime)];
if ~isempty(springTime) && ~isempty(fallTime)
    cutOffDates = [max(springTime) min(fallTime)];
elseif ~isempty(springTime) && isempty(fallTime)
    cutOffDates = [max(springTime) 0];
elseif isempty(springTime) && ~isempty(fallTime)
    cutOffDates = [0 min(fallTime)];
end

if isempty(modelT)
    params = zeros(2,4);
    modelT = zeros(size(dataT));
    modelY = zeros(size(dataY));
    cutOffDates = [0 0];
end
%% see how parameter estimation worked
% plot(modelT, modelY, dataT, dataY);
% clf

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