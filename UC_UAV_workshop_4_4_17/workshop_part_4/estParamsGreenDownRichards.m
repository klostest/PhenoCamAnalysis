function [params, modelT, modelY, cutOffDates, resnorm, initGuess,...
    initGuessY, weighting, residual, jacobian] = ...
    estParamsGreenDownRichards(fhandle, modelName, dataT, dataY)
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
if ( (max(dataT) < 290) || (min(dataT) > 150) )
    
    params = NaN*ones(1,13); cutOffDates(1) = NaN; resnorm(1) = NaN;
    residual{1} = NaN; jacobian{1} = NaN; modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY)); initGuess = params; initGuessY = ...
    modelY;
    weighting.type = 'none';
    weighting.weight = 1;
return
end

%% default arguments
% set non-default options for matlab's parameter estimation algorithm
options = optimset('MaxFunEvals', 4*1e3, 'MaxIter', 4*1e3,...
    'Display', 'off');%, 'TolFun', 1e-9, 'TolX', 1e-9);

weighting.type = 'none';
weighting.weight = 1;
cutOffDates = [0 0];

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
% if (~isempty(springTime) && ...
%         (springTime(length(springTime))-springTime(1) >= changeTime)); %days

%translation, slope, amplitude, base, time to transition to next piecewise
%function.  initial guess for transition time will be time of max GCC
% a1 b1 c1 d1 t1

[beginWindowTime, endWindowTime, beginWindowData,...
endWindowData, beginWindowIndex, endWindowIndex] = ...
seasonalChange(changeTime, firstHalfYearTime, firstHalfYearData);

%*** trying new things***
peakGreen = max(springData);
% peakGreen = beginWindowData;
baseGreen = min(springData);
% baseGreen = endWindowData;

%for endpoint of summer model
y1 = endWindowData;

%now need initial guess.  The amplitude should be peak minus baseline
amp = peakGreen - baseGreen;
%time for middle of sigmoid, aka max increase
maxInc = beginWindowTime + ...
    0.5*(endWindowTime - beginWindowTime);
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.
B1 = 4 / (endWindowTime - beginWindowTime);
%translation
M1 = maxInc;
% c1 = amp;
V1 = 2; Q1 = 0.5;
base = baseGreen;
t1 = endWindowTime;
%time trigger for cost function weighting
weighting.times(1) = beginWindowTime;
weighting.times(2) = endWindowTime;

%%============================================
%% Fall senescence
%%============================================

%%
weighting.type = 'none';

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

%transition time, translation, slope, amplitude, base, time to transition
% to next piecewise function.  initial guess for transition times will be
% beginning and ending window times from seasonalChange.m
%t2 a3 b3 c3 d3 t3

[beginWindowTime, endWindowTime, beginWindowData,...
    endWindowData, beginWindowIndex, endWindowIndex] = ...
    seasonalChange(changeTime, secondHalfYearTime, secondHalfYearData);
%*** trying new things***
peakGreen = max(fallData);
% peakGreen = beginWindowData;
baseGreen = min(fallData);
% baseGreen = endWindowData;

%for endpoint of summer model
y2 = beginWindowData;

%Just to have an initial guess for one of the years with Min's LAI data
for_init_guess = endWindowData;

%now need initial guess.  The amplitude should be peak minus baseline
amp = peakGreen - baseGreen;
%time for middle of sigmoid, aka max increase
maxInc = fallTime(1) + ...
    0.5*(endWindowTime - fallTime(1));
%from observation, I noticed that the parameter b is roughly -4 divided by
%the distance between the 10th and 90th percentiles on the x axis.  Note
%that b < 0 for an increasing sigmoid and b > 0 for decreasing.
B2 = -4 / (fallTime(1) - endWindowTime);
%translation
M2 = maxInc;
% c3 = amp;
% d3 = baseGreen;
t2 = beginWindowTime;
% t3 = endWindowTime;
V2 = 2; Q2 = 0.5;

%%============================================
%% Summer
%%============================================
%% linear or quadratic decreasing summer greenness
%transition time, parameters for quadratic.  initial guess will be straight
%line between t1 and t2, with c = 0.
%t1 a2 b2 c2 t2

%ax^2 + bx + c
a = 0;
b = (y2-y1)/(t2-t1);
%y = mx + b
c = y2 - b*t2;

% % exponential 
% a = y2;
% b = 0.3;
% c = (t1+t2)/2;
% d = 1/100;

% %cubic
% %ax^2 + bx + c
% a = 0; b = 0;
% c = (y2-y1)/(t2-t1);
% %y = mx + b
% d = y2 - b*t2;

base2 = 0;
%scale certain parameters so all parameter sensitities are on a similar
%order of magnitude for jacobian matrix
% base = base*1e-2;
% a = a*1e5;
% b = b*1e-5;
% c = c*1e-2;
% B2 = B2*1e-1;
% base2 = base2*1e5;
    
initGuess = [base a b c Q1 B1 M1 V1 Q2 B2 M2 V2 base2];
initGuess = double(initGuess);
lb = -Inf*ones(size(initGuess));
ub = Inf*ones(size(initGuess));
% ub(3) = 0;
% ub(2) = 0;

%If base, a, b, and c are messed up, i.e. NaN or zero or similar, just make
%them all zero.  This happened when trying Min's LAI data.
%Actually make the c parameter (y intercept of line at top of curve).
if sum(isnan(initGuess)) > 0
    initGuess(1:4) = [zeros(1,3) for_init_guess]; %trying y1 as well as y1_1 for a
    %different site year
end

%% see how initial guess is
figureh = figure;
initGuessY = fhandle(initGuess, dataT);
plot(dataT, initGuessY, dataT, dataY, 'o');
close(figureh);

%% error checking:  onset and offset dates should not be the same
% if onsetIndex == peakIndex
%     params(1,:) = [0 0 0 0];
%     resnorm(1) = 0;
% else
%% parameter estimation
%non-linear least squares
[params, resnorm,residual,~,~,~,jacobian]...
        = lsqnonlin(@(params)...
        dataDiff(params,dataY,dataT,fhandle,modelName,...
        weighting), initGuess,...
        lb, ub, options);
    
modelY = fhandle(params, dataT);
    
%% see how parameter estimation worked
figureh = figure;
modelT = dataT;
plot(dataT, modelY, dataT, dataY, 'o'); hold on;
minModel = min(modelY); maxModel = max(modelY);
plot([t1 t1], [minModel maxModel], [t2 t2], [minModel maxModel]);
grid minor
close(figureh);
    
    % end
else
    params = NaN*ones(1,13); cutOffDates(1) = NaN; resnorm(1) = NaN;
    residual{1} = NaN; jacobian{1} = NaN; modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY)); initGuess = params; initGuessY = ...
        modelY;
end